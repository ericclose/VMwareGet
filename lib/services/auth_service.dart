import 'dart:convert';
import 'dart:io';
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
        'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50',
        data: {
          'primaryDownloads': true,
          'otherDownloads': '',
          'searchQuery': '',
          'freeDownloads': true,
          'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
          'skuCode': '',
          'release': '26H1u1',
          'genLevel': '546859',
          'language': 'EN',
          'os': '',
        },
        options: Options(
          headers: {
            'Cookie': cookieHeader,
            'x-csrf-token': csrfHeader,
            'Origin': 'https://support.broadcom.com',
            'Referer':
                'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro&displayGroup=VMware%20Workstation%20Pro%2026H1%20for%20Windows&release=26H1u1&os=&servicePk=546859&language=EN&freeDownloads=true',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language':
                'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
          },
        ),
      );
      if (resp.statusCode == 200 && resp.data is Map && resp.data['success'] == true) {
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
      final cookieMatch = RegExp(r"-[-a-zA-Z]*[hb]\s+['" + r'"](?:Cookie:\s*)?([^' + r'"' + r"']+)['" + r'"]')
          .firstMatch(cleanCookie);
      if (cookieMatch != null) {
        cleanCookie = cookieMatch.group(1) ?? cleanCookie;
      }
      final csrfMatch = RegExp(r"x-csrf-token:\s*([^\s'" + r'"]+)', caseSensitive: false)
          .firstMatch(tokenOrCookie);
      if (csrfMatch != null) {
        extractedCsrf = csrfMatch.group(1);
      }
    } else {
      // Search for x-csrf-token inside text if present
      final csrfMatch = RegExp(r"x-csrf-token:\s*([^\s'" + r'"]+)', caseSensitive: false)
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
}
