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
}
