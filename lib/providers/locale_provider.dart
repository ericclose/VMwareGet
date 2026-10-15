import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class AppLanguage {
  final String code;
  final String flag;
  final String nativeName;
  final String englishName;

  const AppLanguage({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.englishName,
  });
}

class LocaleProvider extends ChangeNotifier {
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'en',
      flag: '🇺🇸',
      nativeName: 'English',
      englishName: 'English (United States)',
    ),
    AppLanguage(
      code: 'zh',
      flag: '🇨🇳',
      nativeName: '简体中文',
      englishName: '简体中文 (Simplified Chinese)',
    ),
    AppLanguage(
      code: 'eo',
      flag: '🌐',
      nativeName: 'Esperanto',
      englishName: 'Esperanto (Internacia Lingvo)',
    ),
  ];

  Locale _locale = const Locale('en');
  Future<void>? _loadFuture;

  LocaleProvider() {
    _loadFuture = loadLocale();
  }

  Locale get locale => _locale;

  AppLanguage get currentLanguage => supportedLanguages.firstWhere(
        (l) => l.code == _locale.languageCode,
        orElse: () => supportedLanguages.first,
      );

  String get currentLanguageFlag => currentLanguage.flag;
  String get currentLanguageNativeName => currentLanguage.nativeName;

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
