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
        title: 'Broadcom Account Authentication - VMwareGet',
        windowWidth: 1040,
        windowHeight: 760,
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

    // Check cookies every 1200ms
    pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      try {
        final cookies = await webview.getAllCookies();
        if (cookies.isEmpty) return;

        final broadcomCookies =
            cookies.where((c) => c.domain.contains('broadcom.com')).toList();
        if (broadcomCookies.isEmpty) return;

        final hasJSessionId =
            broadcomCookies.any((c) => c.name.toUpperCase() == 'JSESSIONID');
        final hasOktaOrIngress = broadcomCookies.any((c) =>
            c.name.toLowerCase().contains('okta') ||
            c.name.toLowerCase().contains('liferay') ||
            c.name.toLowerCase().contains('portal'));

        if (hasJSessionId && hasOktaOrIngress) {
          final cookieHeader =
              broadcomCookies.map((c) => '${c.name}=${c.value}').join('; ');

          String? csrfToken;
          try {
            final csrfResult = await webview
                .evaluateJavaScript('window.Liferay?.authToken || ""');
            if (csrfResult != null &&
                csrfResult.toString().isNotEmpty &&
                csrfResult.toString() != '""') {
              csrfToken = csrfResult.toString().replaceAll('"', '').trim();
            }
          } catch (_) {}

          onStatusUpdate?.call('Broadcom authentication detected! Validating session...');

          // Test verification with live SKU API
          try {
            final dio = Dio();
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
                  'x-csrf-token': csrfToken ?? 'YaLAJUoR',
                  'Origin': 'https://support.broadcom.com',
                  'Referer': AppConstants.broadcomLoginUrl,
                },
              ),
            );

            if (resp.statusCode == 200 &&
                resp.data is Map &&
                (resp.data as Map)['success'] == true) {
              String userEmail = 'account@broadcom.com';
              try {
                final emailResult = await webview.evaluateJavaScript(
                    'window.themeDisplay?.getUserEmailAddress() || ""');
                if (emailResult != null &&
                    emailResult.toString().contains('@')) {
                  userEmail =
                      emailResult.toString().replaceAll('"', '').trim();
                }
              } catch (_) {}

              final session = await authenticateManual(
                email: userEmail,
                tokenOrCookie: cookieHeader,
                displayName: userEmail.contains('@')
                    ? userEmail.split('@').first
                    : 'Broadcom User',
                csrfToken: csrfToken ?? 'YaLAJUoR',
              );

              onStatusUpdate?.call('Login successful! Session captured.');
              finishWithSession(session);
            }
          } catch (_) {
            // User still interacting or authenticating, keep waiting
          }
        }
      } catch (_) {}
    });

    return completer.future;
  }
}
