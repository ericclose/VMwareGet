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

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AuthSession?> loadSession() async {
    try {
      final jsonStr =
          await _secureStorage.read(key: AppConstants.storageKeySession);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final session = AuthSession.fromJson(data);
        if (session.isValid) {
          return session;
        }
      }
    } catch (_) {
      // Fallback
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.storageKeySession);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final session = AuthSession.fromJson(data);
        if (session.isValid) {
          return session;
        }
      }
    }
    return null;
  }

  Future<void> saveSession(AuthSession session) async {
    final jsonStr = jsonEncode(session.toJson());
    try {
      await _secureStorage.write(
        key: AppConstants.storageKeySession,
        value: jsonStr,
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.storageKeySession, jsonStr);
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: AppConstants.storageKeySession);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageKeySession);
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
      final dio = Dio();
      final cookieHeader = session.cookieJar ?? session.sessionToken;
      final csrfHeader = session.csrfToken ?? 'YaLAJUoR';
      final resp = await dio.post(
        'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50',
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
            'Origin': 'https://support.broadcom.com',
            'Referer':
                'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language':
                'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
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

    // Check cookies and page authentication state every 1000ms
    pollTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final cookies = await webview.getAllCookies();
        if (cookies.isEmpty) return;

        final broadcomCookies =
            cookies.where((c) => c.domain.contains('broadcom.com')).toList();
        if (broadcomCookies.isEmpty) return;

        final hasJSessionId =
            broadcomCookies.any((c) => c.name.toUpperCase() == 'JSESSIONID');
        final hasSessionCookie = broadcomCookies.any((c) {
          final n = c.name.toLowerCase();
          return n == 'jsessionid' ||
              n.contains('saml') ||
              n.contains('session') ||
              n.contains('liferay') ||
              n.contains('okta');
        });

        // Query active page DOM and Liferay runtime inside WKWebView
        String? extractedCsrf;
        String? extractedEmail;
        String? extractedName;
        bool jsIsSignedIn = false;

        try {
          final jsRaw = await webview.evaluateJavaScript('''
            (() => {
              try {
                const isLoginPage = window.location.href.includes('/login') || 
                                    window.location.hostname.includes('auth.') ||
                                    window.location.hostname.includes('login.');
                const isSupport = window.location.hostname.includes('support.broadcom.com');
                const csrf = window.Liferay?.authToken || window.themeDisplay?.getAuthToken?.() || '';
                const email = window.themeDisplay?.getUserEmailAddress?.() || '';
                let name = window.themeDisplay?.getUserName?.() || '';
                if (!name || name === 'Guest') {
                  const el = document.querySelector('.user-full-name, .user-name, .profile-name, [data-user-name]');
                  if (el) name = el.innerText.trim();
                }
                const hasSignOut = document.body ? (document.body.innerText.includes('Sign Out') || document.body.innerText.includes('Log Out')) : false;
                const isSignedIn = (window.themeDisplay?.isSignedIn?.() === true) ||
                                   (isSupport && !isLoginPage && name.length > 0 && name !== 'Guest') ||
                                   (isSupport && !isLoginPage && (csrf.length > 0 || hasSignOut));

                return JSON.stringify({
                  isSignedIn: !!isSignedIn,
                  csrf: csrf,
                  email: email,
                  name: name,
                  url: window.location.href
                });
              } catch(e) {
                return JSON.stringify({ isSignedIn: false, error: e.toString() });
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

        final isAuthenticated = (hasJSessionId && hasSessionCookie) || jsIsSignedIn;

        if (isAuthenticated) {
          final cookieHeader =
              broadcomCookies.map((c) => '${c.name}=${c.value}').join('; ');

          onStatusUpdate?.call('Broadcom authentication detected! Capturing session...');

          String userEmail = (extractedEmail != null && extractedEmail.contains('@'))
              ? extractedEmail
              : 'account@broadcom.com';

          String displayName = (extractedName != null &&
                  extractedName.isNotEmpty &&
                  extractedName != 'Guest')
              ? extractedName
              : (userEmail.contains('@')
                  ? userEmail.split('@').first
                  : 'Broadcom User');

          final csrf = extractedCsrf ?? 'YaLAJUoR';

          // Try live API check with proper browser User-Agent
          bool apiVerified = false;
          try {
            final dio = Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
                  'Accept': 'application/json, text/plain, */*',
                  'Content-Type': 'application/json;charset=UTF-8',
                  'Origin': 'https://support.broadcom.com',
                  'Referer':
                      'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro',
                  'Cookie': cookieHeader,
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

          // Conclude authentication if API verified OR confirmed signed-in inside WKWebView
          if (apiVerified ||
              (hasJSessionId && jsIsSignedIn) ||
              (hasJSessionId && extractedName != null && extractedName.isNotEmpty)) {
            final session = await authenticateManual(
              email: userEmail,
              tokenOrCookie: cookieHeader,
              displayName: displayName,
              csrfToken: csrf,
            );

            onStatusUpdate?.call('Login successful! Session captured.');
            finishWithSession(session);
          }
        }
      } catch (_) {}
    });

    return completer.future;
  }
}
