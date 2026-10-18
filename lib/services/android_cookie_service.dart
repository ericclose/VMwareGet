import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class AndroidCookieService {
  static const MethodChannel _channel =
      MethodChannel('io.github.vmwareget/cookies');

  /// Fetches the cookie header string directly from Android's android.webkit.CookieManager
  static Future<String?> getCookies(String url) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final result =
          await _channel.invokeMethod<String>('getCookies', {'url': url});
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Fetches combined cookies across all Broadcom portals from Android's android.webkit.CookieManager
  static Future<String?> getAllCookies() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<String>('getAllCookies');
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (_) {
      return null;
    }
  }

  /// Clears all cookies from Android's android.webkit.CookieManager
  static Future<bool> clearCookies() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('clearCookies');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Injects a single cookie string into Android's android.webkit.CookieManager
  static Future<bool> setCookie(String url, String cookie) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setCookie', {
        'url': url,
        'cookie': cookie,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Injects a list of structured cookies into Android's android.webkit.CookieManager with 30-day persistence
  static Future<bool> setCookies(List<Map<String, dynamic>> cookies) async {
    if (kIsWeb || !Platform.isAndroid || cookies.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setCookies', {
        'cookies': cookies,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
