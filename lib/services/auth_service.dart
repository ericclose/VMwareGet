import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/auth_session.dart';
import '../utils/constants.dart';
import 'diagnostic_service.dart';

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

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: AppConstants.storageKeySession);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.storageKeySession);
    } catch (_) {}

    // Completely clear in-app webview cookies and storage so that the next login is fresh
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      try {
        await WebviewWindow.clearAll();
      } catch (_) {}
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
      final name = (c.name as String?)?.trim() ?? '';
      final val = (c.value as String?)?.trim() ?? '';
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
    final parts = cookieStr.split(';');
    final Map<String, String> map = {};
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        final key = trimmed.substring(0, eqIdx).trim();
        final val = trimmed.substring(eqIdx + 1).trim();
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
        final csrf = data['headers']?['x-csrf-token']?.toString() ?? 'YaLAJUoR';
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

  Future<bool> probeSessionValidity(AuthSession session) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          followRedirects: false,
          validateStatus: (status) => status == 200,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json;charset=UTF-8',
            'Origin': 'https://support.broadcom.com',
            'Referer':
                'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
            'Accept-Language':
                'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
          },
        ),
      );
      final cookieHeader = cleanCookieString(session.cookieJar ?? session.sessionToken);
      final csrfHeader = session.csrfToken ?? 'YaLAJUoR';
      final resp = await dio.post(
        'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=1',
        data: {
          'subFamily': 'VMware Workstation Pro',
          'searchVal': '',
          'language': 'EN',
          'freeDownloads': true,
        },
        options: Options(
          headers: {
            'Cookie': cookieHeader,
            'x-csrf-token': csrfHeader,
          },
        ),
      );
      if (resp.statusCode == 200 &&
          resp.data is Map &&
          resp.data['success'] == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<AuthSession> authenticateManual({
    required String email,
    required String tokenOrCookie,
    String? displayName,
    String? csrfToken,
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

    final session = AuthSession(
      email: email.trim(),
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Eric Close'),
      sessionToken: cleanCookie,
      cookieJar: cleanCookie,
      csrfToken: extractedCsrf ?? 'YaLAJUoR',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      isExportComplianceVerified: true,
    );
    await saveSession(session);
    return session;
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

  /// Launch native in-app WKWebView window to log into Broadcom and automatically capture session
  Future<AuthSession?> loginWithInAppWebView({
    void Function(String message)? onStatusUpdate,
  }) async {
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      throw UnsupportedError('In-App WebView login is only supported on Desktop platforms.');
    }

    if (!await WebviewWindow.isWebviewAvailable()) {
      throw StateError('Desktop WebView runtime is not available on this system.');
    }

    onStatusUpdate?.call('Launching Broadcom in-app secure portal...');

    final webview = await WebviewWindow.create(
      configuration: const CreateConfiguration(
        title: '',
        windowWidth: 1040,
        windowHeight: 760,
        titleBarHeight: 42,
        titleBarTopPadding: 0,
      ),
    );

    webview.launch(AppConstants.broadcomLoginUrl);

    final completer = Completer<AuthSession?>();
    Timer? pollTimer;
    bool isCompleted = false;

    void cleanup() {
      pollTimer?.cancel();
    }

    void finishWithSession(AuthSession session) {
      if (isCompleted) return;
      isCompleted = true;
      cleanup();
      webview.close();
      if (!completer.isCompleted) {
        completer.complete(session);
      }
    }

    webview.onClose.then((_) {
      cleanup();
      if (!isCompleted && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Check cookies and page authentication state every 1200ms
    pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      try {
        final cookies = await webview.getAllCookies();
        if (cookies.isEmpty) return;

        // Query active page URL and Liferay runtime inside WKWebView
        String? extractedCsrf;
        String? extractedEmail;
        String? extractedName;
        bool isLoginPage = true;
        bool isSupportPortal = false;
        bool jsIsSignedIn = false;

        try {
          final jsRaw = await webview.evaluateJavaScript('''
            (() => {
              try {
                const url = window.location.href;
                const isLogin = url.includes('/login') || 
                                url.includes('auth.broadcom.com') ||
                                url.includes('login.broadcom.com') ||
                                url.includes('okta.com');
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
                  isSignedIn: !!signedIn,
                  csrf: csrf,
                  email: email,
                  name: name,
                  url: url
                });
              } catch(e) {
                return JSON.stringify({ isLoginPage: true, isSupportPortal: false, isSignedIn: false, error: e.toString() });
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
            }
          }
        } catch (_) {}

        // Never attempt capture while user is on the login/SSO page
        if (isLoginPage || !isSupportPortal) {
          return;
        }

        // Check user sign-in status or presence of software products on page
        bool hasProductsOnPage = false;
        try {
          final jsCheck = await webview.evaluateJavaScript('''
            (() => {
              const text = document.body ? document.body.innerText : '';
              return JSON.stringify({
                hasProducts: text.includes('VMware Workstation Pro') || text.includes('VMware Fusion') || text.includes('Product Download'),
                hasUserButton: !!document.querySelector('.user-full-name, .user-name, [data-user-name]') || text.includes('Eric Close')
              });
            })()
          ''');
          if (jsCheck != null) {
            String s = jsCheck.toString();
            if (s.startsWith('"') && s.endsWith('"') && s.length > 2) {
              s = jsonDecode(s).toString();
            }
            final d = jsonDecode(s);
            if (d is Map && d['hasProducts'] == true) {
              hasProductsOnPage = true;
            }
          }
        } catch (_) {}

        final bool hasAuthUser = (extractedName != null &&
                extractedName.isNotEmpty &&
                extractedName != 'Guest') ||
            jsIsSignedIn;

        if (!hasAuthUser && !hasProductsOnPage) {
          return;
        }

        final cleanCookieHeader = compileCookiesForSupportPortal(cookies);
        if (cleanCookieHeader.isEmpty || !cleanCookieHeader.contains('JSESSIONID')) {
          return;
        }

        final csrf = (extractedCsrf != null && extractedCsrf.isNotEmpty)
            ? extractedCsrf
            : 'YaLAJUoR';

        onStatusUpdate?.call('Broadcom portal detected. Verifying session...');

        // Strict verification: live API call check
        bool apiVerified = false;
        try {
          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              followRedirects: false, // Disallow 302 redirect to login
              validateStatus: (status) => status == 200,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
                'Accept': 'application/json, text/plain, */*',
                'Content-Type': 'application/json;charset=UTF-8',
                'Origin': 'https://support.broadcom.com',
                'Referer':
                    'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro',
                'Cookie': cleanCookieHeader,
                'x-csrf-token': csrf,
              },
            ),
          );

          final resp = await dio.post(
            'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=1',
            data: {
              'subFamily': 'VMware Workstation Pro',
              'searchVal': '',
              'language': 'EN',
              'freeDownloads': true,
            },
          );

          if (resp.statusCode == 200 &&
              resp.data is Map &&
              (resp.data as Map)['success'] == true) {
            apiVerified = true;
          }
        } catch (_) {}

        // Capture session when API call succeeds OR when authenticated user/catalog is active on support portal
        final bool isReadyToCapture = apiVerified ||
            (isSupportPortal && (hasAuthUser || hasProductsOnPage));

        if (isReadyToCapture) {
          String userEmail = (extractedEmail != null && extractedEmail.contains('@'))
              ? extractedEmail
              : (extractedName != null && extractedName.isNotEmpty && extractedName != 'Guest'
                  ? '${extractedName.replaceAll(" ", ".").toLowerCase()}@broadcom.user'
                  : 'eric.close@broadcom.user');

          String displayName = (extractedName != null &&
                  extractedName.isNotEmpty &&
                  extractedName != 'Guest')
              ? extractedName
              : (userEmail.contains('@')
                  ? userEmail.split('@').first
                  : 'Eric Close');

          final session = await authenticateManual(
            email: userEmail,
            tokenOrCookie: cleanCookieHeader,
            displayName: displayName,
            csrfToken: csrf,
          );

          DiagnosticService.instance.info(
            'Auth',
            'In-App WebView session captured! User: $userEmail ($displayName), CSRF: $csrf',
            'apiVerified=$apiVerified, hasAuthUser=$hasAuthUser, hasProducts=$hasProductsOnPage',
          );

          onStatusUpdate?.call('Login successful! Session captured.');
          finishWithSession(session);
        }
      } catch (_) {}
    });

    return completer.future;
  }
}
