import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vmwareget/models/auth_session.dart';
import 'package:vmwareget/services/auth_service.dart';
import 'package:vmwareget/utils/constants.dart';
import 'dart:convert';
import 'dart:io';

class MockCookie {
  final String name;
  final String value;
  final String domain;
  final String path;

  MockCookie({
    required this.name,
    required this.value,
    required this.domain,
    this.path = '/',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Cookie & Session Processing', () {
    test('cleanCookieString removes duplicate cookie keys keeping valid format', () {
      const raw = 'JSESSIONID=FIRST_123; foo=bar; JSESSIONID=SECOND_456; baz=qux';
      final cleaned = AuthService.cleanCookieString(raw);
      expect(cleaned.contains('foo=bar'), isTrue);
      expect(cleaned.contains('baz=qux'), isTrue);
      // Key JSESSIONID should only occur once
      final matches = RegExp(r'JSESSIONID=').allMatches(cleaned);
      expect(matches.length, equals(1));
    });

    test('compileCookiesForSupportPortal prioritizes support.broadcom.com JSESSIONID and preserves broadcom tokens', () {
      final cookies = [
        MockCookie(name: 'JSESSIONID', value: 'LOGIN_COOKIE', domain: 'login.broadcom.com'),
        MockCookie(name: 'sspsession', value: 'AUTH_TOKEN', domain: 'auth.broadcom.com'),
        MockCookie(name: 'JSESSIONID', value: 'SUPPORT_SESSION', domain: 'support.broadcom.com'),
        MockCookie(name: 'liferay-ingress', value: 'ROUTING_KEY', domain: '.broadcom.com'),
        MockCookie(name: 'google-analytics', value: 'IGNORE_ME', domain: 'google.com'),
      ];

      final header = AuthService.compileCookiesForSupportPortal(cookies);

      // Must NOT contain external non-broadcom cookies
      expect(header.contains('IGNORE_ME'), isFalse);

      // Support portal JSESSIONID must win over login.broadcom.com JSESSIONID
      expect(header.contains('JSESSIONID=SUPPORT_SESSION'), isTrue);
      expect(header.contains('LOGIN_COOKIE'), isFalse);

      // SSO tokens must be preserved
      expect(header.contains('sspsession=AUTH_TOKEN'), isTrue);
      expect(header.contains('liferay-ingress=ROUTING_KEY'), isTrue);
    });

    test('loadSession falls back to SharedPreferences if SecureStorage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final session = AuthSession(
        email: 'test@broadcom.user',
        displayName: 'Test User',
        sessionToken: 'test_token',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await prefs.setString(AppConstants.storageKeySession, jsonEncode(session.toJson()));

      final authService = AuthService();
      final loaded = await authService.loadSession();

      expect(loaded, isNotNull);
      expect(loaded?.email, equals('test@broadcom.user'));
      expect(loaded?.displayName, equals('Test User'));
      expect(loaded?.isValid, isTrue);
    });

    test('getWindowsWebviewDataDir returns non-empty user-writable path', () {
      AuthService.resetWindowsWebviewDataDirForTesting();
      final dataDir = AuthService.getWindowsWebviewDataDir();
      expect(dataDir.isNotEmpty, isTrue);
      expect(Directory(dataDir).existsSync(), isTrue);
    });
  });
}
