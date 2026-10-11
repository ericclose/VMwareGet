import 'dart:convert';
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
      // Fallback for environments where keychain is inaccessible
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
    } catch (_) {
      // Fallback
    }
    // Also save in prefs as backup
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

  Future<AuthSession> authenticateManual({
    required String email,
    required String tokenOrCookie,
    String? displayName,
  }) async {
    final session = AuthSession(
      email: email.trim(),
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Broadcom User'),
      sessionToken: tokenOrCookie.trim(),
      cookieJar: tokenOrCookie.contains('=') ? tokenOrCookie.trim() : null,
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
