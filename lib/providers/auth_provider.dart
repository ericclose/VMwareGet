import 'package:flutter/material.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _authService.loadSession();
      if (session != null && session.isValid) {
        _currentSession = session;
        _status = AuthStatus.authenticated;
      } else {
        _currentSession = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithManualToken({
    required String email,
    required String token,
    String? displayName,
    String? csrfToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.authenticateManual(
        email: email,
        tokenOrCookie: token,
        displayName: displayName,
        csrfToken: csrfToken,
      );
      _currentSession = session;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Authentication error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.clearSession();
    _currentSession = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> openBroadcomLoginPortal() async {
    return await _authService.launchBroadcomLogin();
  }

  Future<bool> openBroadcomRegistrationPortal() async {
    return await _authService.launchBroadcomRegister();
  }

  Future<bool> loginWithInAppWebView({
    void Function(String message)? onStatusUpdate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.loginWithInAppWebView(
        onStatusUpdate: onStatusUpdate,
      );
      if (session != null) {
        _currentSession = session;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadLocalTestSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final testData = await _authService.loadSessionFromLocalTestFile();
      if (testData != null && testData['cookie']?.isNotEmpty == true) {
        final email = testData['email']?.isNotEmpty == true
            ? testData['email']!
            : 'ZetaGo@protonmail.com';
        return await loginWithManualToken(
          email: email,
          token: testData['cookie']!,
          csrfToken: testData['csrf']?.toString(),
        );
      }
      _errorMessage = 'No verified session found in tools/.session.json';
      return false;
    } catch (e) {
      _errorMessage = 'Failed importing session: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
