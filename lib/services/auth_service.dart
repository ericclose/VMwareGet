import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'android_cookie_service.dart';
import '../models/auth_session.dart';
import '../utils/constants.dart';
import '../views/mobile_webview_login.dart';
import 'diagnostic_service.dart';
import 'download_service.dart';
import 'catalog_service.dart';
import 'webview_bridge.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AuthSession?> loadSession() async {
    DiagnosticService.instance.info('Auth', 'Attempting to load persisted session...');
    String? jsonStr;
    try {
      jsonStr = await _secureStorage.read(key: AppConstants.storageKeySession);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        DiagnosticService.instance.info('Auth', 'Session loaded from FlutterSecureStorage');
      }
    } catch (e) {
      DiagnosticService.instance.warn('Auth', 'SecureStorage read error: $e');
    }

    // Fallback if secure storage returned null or threw on macOS/sandboxed environments
    if (jsonStr == null || jsonStr.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        jsonStr = prefs.getString(AppConstants.storageKeySession);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          DiagnosticService.instance.info('Auth', 'Session loaded from SharedPreferences fallback');
        }
      } catch (e) {
        DiagnosticService.instance.warn('Auth', 'SharedPreferences read error: $e');
      }
    }

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final session = AuthSession.fromJson(data);
        if (session.isValid) {
          DiagnosticService.instance.info('Auth', 'Persisted session is valid for user: ${session.email} (${session.displayName})');
          return session;
        } else {
          DiagnosticService.instance.warn('Auth', 'Persisted session expired at: ${session.expiresAt}');
        }
      } catch (e) {
        DiagnosticService.instance.error('Auth', 'Error decoding stored session JSON: $e');
      }
    } else {
      DiagnosticService.instance.info('Auth', 'No persisted session found');
    }
    return null;
  }

  Future<void> saveSession(AuthSession session) async {
    DiagnosticService.instance.info('Auth', 'Persisting session for: ${session.email} (expires: ${session.expiresAt})');
    final jsonStr = jsonEncode(session.toJson());
    try {
      await _secureStorage.write(
        key: AppConstants.storageKeySession,
        value: jsonStr,
      );
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.storageKeySession, jsonStr);
    } catch (_) {}
  }

  static String? _windowsWebviewDataDir;

  @visibleForTesting
  static void resetWindowsWebviewDataDirForTesting() {
    _windowsWebviewDataDir = null;
  }

  /// Returns a user-writable directory in %LOCALAPPDATA% for the WebView2 cache.
  /// This prevents the "Microsoft Edge can't read and write to its data directory" error
  /// when the application is installed in "C:\Program Files\VMwareGet".
  static String getWindowsWebviewDataDir() {
    if (_windowsWebviewDataDir != null) {
      return _windowsWebviewDataDir!;
    }
    final sep = Platform.pathSeparator;
    final localAppData = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        (Platform.isWindows ? Platform.environment['USERPROFILE'] : null);
    if (localAppData != null && localAppData.isNotEmpty) {
      final dir = Directory('$localAppData${sep}VMwareGet${sep}webview_data');
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }
      if (dir.existsSync()) {
        _windowsWebviewDataDir = dir.path;
        return dir.path;
      }
    }
    final tempDir = Directory('${Directory.systemTemp.path}${sep}VMwareGet_webview_data');
    if (!tempDir.existsSync()) {
      try {
        tempDir.createSync(recursive: true);
      } catch (_) {}
    }
    _windowsWebviewDataDir = tempDir.path;
    return tempDir.path;
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: AppConstants.storageKeySession);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.storageKeySession);
    } catch (_) {}

    // Completely clear in-app webview cookies and storage so that the next login is fresh
    if (!kIsWeb) {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        try {
          if (Platform.isWindows) {
            await WebviewWindow.clearAll(
              userDataFolderWindows: getWindowsWebviewDataDir(),
            );
          } else {
            await WebviewWindow.clearAll();
          }
        } catch (_) {}
      } else if (Platform.isAndroid || Platform.isIOS) {
        try {
          await AndroidCookieService.clearCookies();
        } catch (_) {}
      }
    }
  }

  /// Filters and compiles cookies for Broadcom support portal,
  /// prioritizing support.broadcom.com (so its JSESSIONID takes precedence)
  /// while preserving essential SSO and ingress tokens across broadcom.com.
  static String compileCookiesForSupportPortal(List<dynamic> cookies) {
    // Keep all cookies associated with broadcom.com
    final broadcomCookies = cookies.where((c) {
      final d = (c.domain as String?)?.toLowerCase().trim() ?? '';
      return d.contains('broadcom.com');
    }).toList();

    // Priority sorting:
    // support.broadcom.com has highest precedence (30) so its JSESSIONID wins.
    // .broadcom.com / broadcom.com has second precedence (15).
    // Other subdomains have baseline (5).
    // Longer paths take higher precedence.
    broadcomCookies.sort((a, b) {
      final aDom = (a.domain as String?)?.toLowerCase().trim() ?? '';
      final bDom = (b.domain as String?)?.toLowerCase().trim() ?? '';
      final aPath = (a.path as String?) ?? '';
      final bPath = (b.path as String?) ?? '';

      final aScore = (aDom == 'support.broadcom.com' ? 30 : (aDom.startsWith('.') ? 15 : 5)) + aPath.length;
      final bScore = (bDom == 'support.broadcom.com' ? 30 : (bDom.startsWith('.') ? 15 : 5)) + bPath.length;
      return bScore.compareTo(aScore);
    });

    final Map<String, String> map = {};
    for (final c in broadcomCookies) {
      final name = (c.name as String?)?.replaceAll('\u0000', '').trim() ?? '';
      final val = (c.value as String?)?.replaceAll('\u0000', '').trim() ?? '';
      if (name.isNotEmpty && val.isNotEmpty && !map.containsKey(name)) {
        map[name] = val;
      }
    }

    final compiled = map.entries.map((e) => '${e.key}=${e.value}').join('; ');
    DiagnosticService.instance.info(
      'CookieJar',
      'Compiled ${map.length} unique Broadcom cookies (has JSESSIONID: ${map.containsKey('JSESSIONID')}, sspsession: ${map.containsKey('sspsession')})',
      'Keys: ${map.keys.join(', ')}',
    );
    return compiled;
  }

  /// Deduplicates manual cookie string by cookie name
  static String cleanCookieString(String cookieStr) {
    final sanitized = cookieStr.replaceAll('\u0000', '');
    final parts = sanitized.split(';');
    final Map<String, String> map = {};
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        final key = trimmed.substring(0, eqIdx).trim().replaceAll('\u0000', '');
        final val = trimmed.substring(eqIdx + 1).trim().replaceAll('\u0000', '');
        if (key.isNotEmpty && val.isNotEmpty) {
          map[key] = val;
        }
      }
    }
    return map.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<Map<String, dynamic>?> loadSessionFromLocalTestFile() async {
    if (kIsWeb) return null;
    try {
      final file = File('tools/.session.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final cookies = data['cookies'] as Map<String, dynamic>? ?? {};
        final email = data['email']?.toString() ?? '';
        final csrf = data['headers']?['x-csrf-token']?.toString() ?? '';
        final cookieStr =
            cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
        return {
          'email': email,
          'cookie': cookieStr,
          'csrf': csrf,
        };
      }
    } catch (_) {}
    return null;
  }

  /// Dynamically extracts the active Liferay.authToken from the Broadcom support portal.
  /// (Deprecated: Token is now captured directly from browser window context)
  Future<String?> fetchDynamicCsrfToken(String cookieHeader) async {
    return null;
  }

  Future<bool> probeSessionValidity(AuthSession session) async {
    return session.sessionToken.isNotEmpty;
  }

  Future<AuthSession> authenticateManual({
    required String email,
    required String tokenOrCookie,
    String? displayName,
    String? csrfToken,
    String? cookieJar,
  }) async {
    String cleanCookie = tokenOrCookie.trim();
    String? extractedCsrf = csrfToken;

    // Check if user pasted a full cURL command
    if (cleanCookie.startsWith('curl')) {
      final cookieMatch = RegExp(r"""-[-a-zA-Z]*[hb]\s+['"](?:Cookie:\s*)?([^'"]+)['"]""")
          .firstMatch(cleanCookie);
      if (cookieMatch != null) {
        cleanCookie = cookieMatch.group(1) ?? cleanCookie;
      }
      final csrfMatch = RegExp(r"""x-csrf-token:\s*([^\s'"]+)""", caseSensitive: false)
          .firstMatch(tokenOrCookie);
      if (csrfMatch != null) {
        extractedCsrf = csrfMatch.group(1);
      }
    } else {
      // Search for x-csrf-token inside text if present
      final csrfMatch = RegExp(r"""x-csrf-token:\s*([^\s'"]+)""", caseSensitive: false)
          .firstMatch(tokenOrCookie);
      if (csrfMatch != null) {
        extractedCsrf = csrfMatch.group(1);
      }
    }

    cleanCookie = cleanCookieString(cleanCookie);

    // If CSRF token was not provided in input, dynamically resolve it from the portal
    if (extractedCsrf == null || extractedCsrf.isEmpty) {
      extractedCsrf = await fetchDynamicCsrfToken(cleanCookie);
    }

    final session = AuthSession(
      email: email.trim(),
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Broadcom User'),
      sessionToken: cleanCookie,
      cookieJar: cookieJar ?? cleanCookie,
      csrfToken: extractedCsrf,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      isExportComplianceVerified: true,
    );
    await saveSession(session);
    return session;
  }

  static List<Map<String, dynamic>> parseCookieStringToDictList(
    String cookieStr, {
    String defaultDomain = '.broadcom.com',
  }) {
    final list = <Map<String, dynamic>>[];
    final parts = cookieStr.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx == -1) continue;
      final name = trimmed.substring(0, eqIdx).trim();
      final value = trimmed.substring(eqIdx + 1).trim();
      if (name.isNotEmpty) {
        final domain = (name.startsWith('JSESSIONID') || name.startsWith('LFR_'))
            ? 'support.broadcom.com'
            : defaultDomain;
        list.add({
          'name': name,
          'value': value,
          'domain': domain,
          'path': '/',
          'expiresDate': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch / 1000,
          'isSecure': true,
        });
      }
    }
    return list;
  }

  Future<bool> launchBroadcomLogin() async {
    final uri = Uri.parse(AppConstants.broadcomLoginUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> launchBroadcomRegister() async {
    final uri = Uri.parse(AppConstants.broadcomRegisterUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> launchProductDownloads(String url) async {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launch native in-app WebView window/modal to log into Broadcom and automatically capture session
  Future<AuthSession?> loginWithInAppWebView({
    BuildContext? context,
    void Function(String message)? onStatusUpdate,
  }) async {
    final osName = Platform.operatingSystem;
    DiagnosticService.instance.info('Auth', 'Initiating in-app WebView login on $osName');

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (context == null) {
        DiagnosticService.instance.error('Auth', 'BuildContext is required for mobile in-app WebView login');
        throw ArgumentError('BuildContext is required for mobile in-app WebView login');
      }
      return await Navigator.of(context).push<AuthSession>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MobileWebViewLoginScreen(
            onStatusUpdate: onStatusUpdate,
          ),
        ),
      );
    }

    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      DiagnosticService.instance.error('Auth', 'In-App WebView is not supported on $osName');
      throw UnsupportedError('In-App WebView login is only supported on Desktop and Mobile platforms.');
    }

    final isAvailable = await WebviewWindow.isWebviewAvailable();
    DiagnosticService.instance.info('Auth', 'System WebView runtime availability: $isAvailable');
    if (!isAvailable) {
      DiagnosticService.instance.error('Auth', 'Desktop WebView runtime is not available on this system ($osName)');
      throw StateError('Desktop WebView runtime is not available on this system.');
    }

    final winDataDir = Platform.isWindows ? getWindowsWebviewDataDir() : null;
    if (winDataDir != null) {
      DiagnosticService.instance.info('Auth', 'Configured Windows WebView2 data directory: $winDataDir');
    }

    onStatusUpdate?.call('Launching Broadcom in-app secure portal...');
    DiagnosticService.instance.info('Auth', 'Creating native WebView window...');

    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: '',
        windowWidth: 1040,
        windowHeight: 760,
        titleBarHeight: 42,
        titleBarTopPadding: 0,
        userDataFolderWindows: winDataDir ?? 'webview_window_WebView2',
      ),
    );

    DiagnosticService.instance.info('Auth', 'Native window created. Launching URL: ${AppConstants.broadcomLoginUrl}');
    webview.launch(AppConstants.broadcomLoginUrl, triggerOnUrlRequestEvent: false);

    final completer = Completer<AuthSession?>();
    Timer? pollTimer;
    bool isCompleted = false;

    void cleanup() {
      pollTimer?.cancel();
    }

    Future<void> finishWithSession(AuthSession session) async {
      if (isCompleted) return;
      isCompleted = true;
      cleanup();

      // 1. Immediately hide window so it does not distract the user
      try {
        await webview.setWebviewWindowVisibility(false);
      } catch (_) {}

      onStatusUpdate?.call('Fetching complete software releases in browser...');
      DiagnosticService.instance.info(
        'Auth',
        'Fetching full software catalog via in-browser fetch before closing window...',
      );

      // 2. Pre-fetch complete catalog in the live, genuine browser context
      try {
        final catResult =
            await WebviewBridge.instance.fetchFullCatalogInBrowser(webview);
        if (catResult != null && catResult['results'] is List) {
          final count = await CatalogService()
              .ingestBrowserBatchResults(catResult['results'] as List);
          DiagnosticService.instance.info(
            'Auth',
            'Pre-fetched $count releases inside native browser successfully.',
          );
        }
      } catch (e) {
        DiagnosticService.instance.warn(
          'Auth',
          'Notice during in-browser catalog pre-fetch: $e',
        );
      }

      // 3. Completely close and destroy native WebView window
      DiagnosticService.instance.info(
        'Auth',
        'Closing and disposing native WebView window now.',
      );
      try {
        webview.close();
      } catch (_) {}

      // Allow a brief frame delay before completing session to ensure native window detachment completes
      await Future.delayed(const Duration(milliseconds: 150));

      if (!completer.isCompleted) {
        completer.complete(session);
      }
    }

    webview.onClose.then((_) {
      DiagnosticService.instance.info('Auth', 'In-App WebView window was closed.');
      cleanup();
      if (!isCompleted && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    int accessSettledTicks = 0;
    DateTime? lastBridgeAttempt;

    // Check cookies and page authentication state every 500ms for responsive session capture
    pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        final cookies = await webview.getAllCookies();
        if (cookies.isEmpty) return;

        // Query active page URL and Liferay runtime inside WKWebView
        String? extractedCsrf;
        String? extractedEmail;
        String? extractedName;
        bool isLoginPage = true;
        bool isSupportPortal = false;
        bool isAccessSettled = false;
        bool jsIsSignedIn = false;

        try {
          final jsRaw = await webview.evaluateJavaScript('''
            (() => {
              try {
                const url = window.location.href;
                const isAccessSignIn = url.includes('access.broadcom.com') && (
                  url.includes('/signin') ||
                  url.includes('/login') ||
                  url.includes('/idp/') ||
                  url.includes('/oauth2') ||
                  url.includes('authcomplete') ||
                  url.includes('/authorize')
                );
                const isLogin = isAccessSignIn ||
                                url.includes('/login') || 
                                url.includes('/signin') ||
                                url.includes('auth.broadcom.com') ||
                                url.includes('login.broadcom.com') ||
                                url.includes('okta.com') ||
                                url.includes('/oauth2') ||
                                url.includes('authcomplete');
                const isAccessPassed = url.includes('access.broadcom.com') && !isAccessSignIn;
                const isSupport = url.includes('support.broadcom.com') && !isLogin;
                let csrf = window.Liferay?.authToken || '';
                if (!csrf && window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function') {
                  csrf = window.themeDisplay.getAuthToken();
                }
                if (!csrf) {
                  const m = document.documentElement.innerHTML.match(/Liferay\\.authToken\\s*=\\s*['"]([a-zA-Z0-9_-]+)['"]/);
                  if (m) csrf = m[1];
                }
                const email = (window.themeDisplay && typeof window.themeDisplay.getUserEmailAddress === 'function')
                  ? window.themeDisplay.getUserEmailAddress()
                  : '';
                let name = (window.themeDisplay && typeof window.themeDisplay.getUserName === 'function')
                  ? window.themeDisplay.getUserName()
                  : '';
                if (!name || name === 'Guest') {
                  const el = document.querySelector('.user-full-name, .user-name, .profile-name, [data-user-name]');
                  if (el) name = el.innerText.trim();
                }
                const hasRealUser = name.length > 0 && name !== 'Guest';
                const signedIn = (window.themeDisplay?.isSignedIn?.() === true) || (isSupport && hasRealUser);

                return JSON.stringify({
                  isLoginPage: !!isLogin,
                  isSupportPortal: !!isSupport,
                  isAccessSettled: !!isAccessPassed,
                  isSignedIn: !!signedIn,
                  csrf: csrf,
                  email: email,
                  name: name,
                  url: url
                });
              } catch(e) {
                return JSON.stringify({ isLoginPage: true, isSupportPortal: false, isAccessSettled: false, isSignedIn: false, error: e.toString() });
              }
            })()
          ''');

          if (jsRaw != null) {
            String jsStr = jsRaw.toString();
            if (jsStr.startsWith('"') && jsStr.endsWith('"') && jsStr.length > 2) {
              jsStr = jsonDecode(jsStr).toString();
            }
            final data = jsonDecode(jsStr);
            if (data is Map) {
              isLoginPage = data['isLoginPage'] == true;
              isSupportPortal = data['isSupportPortal'] == true;
              isAccessSettled = data['isAccessSettled'] == true;
              jsIsSignedIn = data['isSignedIn'] == true;
              if (data['csrf']?.toString().isNotEmpty == true) {
                extractedCsrf = data['csrf'].toString().trim();
              }
              if (data['email']?.toString().isNotEmpty == true) {
                extractedEmail = data['email'].toString().trim();
              }
              if (data['name']?.toString().isNotEmpty == true &&
                  data['name'].toString() != 'Guest') {
                extractedName = data['name'].toString().trim();
              }
              DiagnosticService.instance.info(
                'Auth',
                'WebView poll: ${cookies.length} cookies, url=${data['url']}, loginPage=$isLoginPage, accessSettled=$isAccessSettled, supportPortal=$isSupportPortal, signedIn=$jsIsSignedIn',
              );
            }
          }
        } catch (_) {}

        if (isLoginPage) {
          accessSettledTicks = 0;
        }

        // If user logged in on access.broadcom.com, allow natural SSO redirects to occur.
        // Only trigger an active bridge navigation if settled and staying on access.broadcom.com for at least 3 seconds.
        if (isAccessSettled && !isSupportPortal) {
          accessSettledTicks++;
          final now = DateTime.now();
          final canBridge = accessSettledTicks >= 6 &&
              (lastBridgeAttempt == null ||
                  now.difference(lastBridgeAttempt!) > const Duration(seconds: 15));

          if (canBridge) {
            lastBridgeAttempt = now;
            accessSettledTicks = 0;
            DiagnosticService.instance.info(
              'Auth',
              'Sign-in settled on access.broadcom.com. Navigating to Support Portal for SSO session...',
            );
            onStatusUpdate?.call('Broadcom sign-in verified. Connecting to Support Portal...');
            webview.launch(AppConstants.workstationPortalUrl);
          }
          return;
        }

        // Never attempt capture while user is on the login/SSO page
        if (isLoginPage || !isSupportPortal) {
          return;
        }

        final cleanCookieHeader = compileCookiesForSupportPortal(cookies);
        if (cleanCookieHeader.isEmpty || !cleanCookieHeader.contains('JSESSIONID')) {
          return;
        }

        final csrf = (extractedCsrf != null && extractedCsrf.isNotEmpty)
            ? extractedCsrf
            : '';
        if (csrf.isEmpty) {
          return;
        }

        final bool hasAuthCookies = cleanCookieHeader.contains('SAML_SP_SESSION_KEY') ||
            cleanCookieHeader.contains('sspsession') ||
            cleanCookieHeader.contains('LFR_SESSION_STATE_');

        final bool hasAuthUser = (extractedName != null &&
                extractedName.isNotEmpty &&
                extractedName != 'Guest') ||
            jsIsSignedIn;

        // If neither user identity nor auth cookies exist yet, wait for SSO exchange
        if (!hasAuthUser && !hasAuthCookies) {
          return;
        }

        onStatusUpdate?.call('Broadcom portal detected. Verifying session...');

        // Capture session when on Support Portal and authenticated indicators exist
        final bool isReadyToCapture = !isLoginPage &&
            isSupportPortal &&
            ((hasAuthUser && hasAuthCookies) || jsIsSignedIn);

        if (isReadyToCapture) {
          String userEmail = (extractedEmail != null && extractedEmail.contains('@'))
              ? extractedEmail
              : (extractedName != null && extractedName.isNotEmpty && extractedName != 'Guest'
                  ? '${extractedName.replaceAll(" ", ".").toLowerCase()}@broadcom.user'
                  : 'broadcom.user@broadcom.user');

          String displayName = (extractedName != null &&
                  extractedName.isNotEmpty &&
                  extractedName != 'Guest')
              ? extractedName
              : (userEmail.contains('@')
                  ? userEmail.split('@').first
                  : 'Broadcom Member');

          final cookieDicts = cookies.map((c) => {
            'name': c.name,
            'value': c.value,
            'domain': c.domain,
            'path': c.path,
            'expiresDate': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch / 1000,
            'isSecure': c.secure,
            'isHTTPOnly': c.httpOnly,
          }).toList();

          try {
            await webview.setCookies(cookieDicts);
          } catch (_) {}

          final session = await authenticateManual(
            email: userEmail,
            tokenOrCookie: cleanCookieHeader,
            displayName: displayName,
            csrfToken: csrf,
            cookieJar: jsonEncode(cookieDicts),
          );

          DiagnosticService.instance.info(
            'Auth',
            'In-App WebView session captured! User: $userEmail ($displayName), CSRF: $csrf',
          );

          // Pre-fetch complete catalog & direct download links before closing window
          onStatusUpdate?.call('Pre-fetching complete catalog & direct links...');
          try {
            final catResult =
                await WebviewBridge.instance.fetchFullCatalogInBrowser(webview);
            if (catResult != null && catResult['results'] is List) {
              final ingestedCount = await CatalogService()
                  .ingestBrowserBatchResults(catResult['results'] as List);
              DiagnosticService.instance.info(
                'Auth',
                'Pre-fetched $ingestedCount releases with direct links during login.',
              );
            }
          } catch (e) {
            DiagnosticService.instance.warn('Auth', 'Login pre-fetch notice: $e');
          }

          onStatusUpdate?.call('Login successful! Session captured.');
          await finishWithSession(session);
        }
      } catch (_) {}
    });

    return completer.future;
  }

  /// Silently synchronizes full product catalog and direct download links using the browser runtime.
  /// Bypasses Cloudflare bot detection seamlessly and destroys the webview immediately after completion.
  Future<int> syncCatalogInBrowser({
    BuildContext? context,
    void Function(String message)? onStatusUpdate,
    bool silent = true,
  }) async {
    final osName = Platform.operatingSystem;
    DiagnosticService.instance.info(
      'Auth',
      'Initiating in-browser catalog sync on $osName (silent: $silent)',
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (context == null) {
        final cached = CatalogService().getAllReleases().length;
        if (cached > 0) return cached;
        DiagnosticService.instance.warn('Auth', 'BuildContext is null for mobile sync, skipping UI-bound sync.');
        return 0;
      }
      final session = await Navigator.of(context).push<AuthSession>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MobileWebViewLoginScreen(
            onStatusUpdate: onStatusUpdate,
          ),
        ),
      );
      final releaseCount = CatalogService().getAllReleases().length;
      return session != null ? (releaseCount > 0 ? releaseCount : 1) : 0;
    }

    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      throw UnsupportedError('In-Browser sync is only supported on Desktop and Mobile.');
    }

    final isAvailable = await WebviewWindow.isWebviewAvailable();
    if (!isAvailable) {
      throw StateError('Desktop WebView runtime is not available on this system.');
    }

    final winDataDir = Platform.isWindows ? getWindowsWebviewDataDir() : null;

    onStatusUpdate?.call('Connecting to Broadcom secure session in background...');
    DiagnosticService.instance.info('Auth', 'Creating background sync WebView window...');

    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: '',
        windowWidth: silent ? 1 : 1040,
        windowHeight: silent ? 1 : 760,
        titleBarHeight: 0,
        titleBarTopPadding: 0,
        userDataFolderWindows: winDataDir ?? 'webview_window_WebView2',
      ),
    );

    try {
      final currentSession = await loadSession();
      if (currentSession != null && currentSession.isValid) {
        List<Map<String, dynamic>> cookiesToInject = [];
        if (currentSession.cookieJar != null && currentSession.cookieJar!.trim().startsWith('[')) {
          try {
            final parsed = jsonDecode(currentSession.cookieJar!);
            if (parsed is List) {
              cookiesToInject = parsed.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
            }
          } catch (_) {}
        }
        if (cookiesToInject.isEmpty) {
          cookiesToInject = parseCookieStringToDictList(currentSession.sessionToken);
        }
        if (cookiesToInject.isNotEmpty) {
          DiagnosticService.instance.info(
            'Auth',
            'Restoring ${cookiesToInject.length} session cookies into background WebView before launching URL...',
          );
          try {
            await webview.setCookies(cookiesToInject);
          } catch (_) {}
        }
      }

      webview.launch(
        AppConstants.broadcomProductDownloadsUrl,
        triggerOnUrlRequestEvent: false,
      );

      final sw = Stopwatch()..start();
      int ingestedCount = 0;

      while (sw.elapsed < const Duration(seconds: 25)) {
        await Future.delayed(const Duration(milliseconds: 250));

        // 1. Inspect page status via fast micro-script
        String? pageState;
        try {
          final res = await webview.evaluateJavaScript('''
            (() => {
              const url = window.location.href || '';
              if (url.includes('/c/portal/login') ||
                  url.includes('access.broadcom.com/signin') ||
                  url.includes('/login')) {
                return 'expired';
              }
              const hasAuthToken = Boolean(
                window.Liferay?.authToken ||
                (window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function' && window.themeDisplay.getAuthToken())
              );
              const isLoaded = document.readyState === 'complete' || document.readyState === 'interactive';
              if (hasAuthToken && isLoaded) {
                return 'ready';
              }
              return 'loading';
            })()
          ''');
          if (res != null) {
            pageState = res.toString().replaceAll('"', '').trim();
          }
        } catch (_) {}

        if (pageState == 'expired' && sw.elapsed > const Duration(seconds: 2)) {
          DiagnosticService.instance.warn(
            'Auth',
            'Background sync redirected to login portal, session is expired',
          );
          throw const BroadcomAuthExpiredException();
        }

        if (pageState == 'ready') {
          onStatusUpdate?.call('Fetching complete releases and direct links...');
          final catResult =
              await WebviewBridge.instance.fetchFullCatalogInBrowser(webview);
          if (catResult != null) {
            if (catResult['expired'] == true) {
              DiagnosticService.instance.warn(
                'Auth',
                'In-browser batch fetch indicated session expired',
              );
              throw const BroadcomAuthExpiredException();
            }
            if (catResult['results'] is List) {
              ingestedCount = await CatalogService()
                  .ingestBrowserBatchResults(catResult['results'] as List);
              DiagnosticService.instance.info(
                'Auth',
                'Silent browser sync ingested $ingestedCount releases successfully.',
              );
              break;
            }
          }
        }
      }

      return ingestedCount;
    } finally {
      DiagnosticService.instance.info('Auth', 'Disposing background sync WebView.');
      try {
        webview.close();
      } catch (_) {}
    }
  }
}
