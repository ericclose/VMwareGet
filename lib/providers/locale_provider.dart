import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Future<void>? _loadFuture;

  LocaleProvider() {
    _loadFuture = loadLocale();
  }

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final future = () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final code = prefs.getString(AppConstants.storageKeyLocale);
        if (code != null &&
            AppLocalizations.supportedLocales.any((l) => l.languageCode == code)) {
          _locale = Locale(code);
        } else {
          _locale = const Locale('en');
        }
        notifyListeners();
      } catch (_) {}
    }();
    _loadFuture = future;
    return future;
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.storageKeyLocale,
        newLocale.languageCode,
      );
    } catch (_) {}
  }
}
