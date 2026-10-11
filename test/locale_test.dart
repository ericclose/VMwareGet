import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vmwareget/l10n/app_localizations.dart';
import 'package:vmwareget/providers/locale_provider.dart';
import 'package:vmwareget/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider & AppLocalizations Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocaleProvider defaults to English', () async {
      final provider = LocaleProvider();
      await provider.loadLocale();
      expect(provider.locale.languageCode, equals('en'));
    });

    test('LocaleProvider persists and updates locale to Chinese and Esperanto', () async {
      final provider = LocaleProvider();
      await provider.loadLocale();

      // Switch to Chinese
      await provider.setLocale(const Locale('zh'));
      expect(provider.locale.languageCode, equals('zh'));

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.storageKeyLocale), equals('zh'));

      // Switch to Esperanto
      await provider.setLocale(const Locale('eo'));
      expect(provider.locale.languageCode, equals('eo'));

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.storageKeyLocale), equals('eo'));

      // New instance should restore 'eo'
      final newProvider = LocaleProvider();
      await newProvider.loadLocale();
      expect(newProvider.locale.languageCode, equals('eo'));
    });

    test('AppLocalizations delivers pure English strings in English mode', () {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      expect(l10nEn.catalog, equals('Catalog'));
      expect(l10nEn.downloads, equals('Downloads'));
      expect(l10nEn.settings, equals('Settings'));
      expect(l10nEn.showInFinder, equals('Show in Finder'));
      expect(l10nEn.copyAllLogs, equals('Copy All Logs'));
      expect(l10nEn.setDownloadDirTitle, equals('Set Storage Directory'));
      expect(l10nEn.systemDownloadsTitle, equals('System Downloads'));
      expect(l10nEn.allPlatforms, equals('All Platforms'));
      expect(l10nEn.signOut, equals('Sign Out'));
      expect(l10nEn.broadcomAuthTitle, equals('Broadcom Authentication'));
      expect(l10nEn.tabInAppBrowser, equals('In-App Web'));
      expect(l10nEn.welcomeTitle, equals('Welcome to VMwareGet'));
      expect(l10nEn.logInWithBroadcom, equals('Log In with Broadcom'));
      expect(l10nEn.speedLabel, equals('Speed'));
      expect(l10nEn.etaLabel, equals('ETA'));
      expect(l10nEn.recommended, equals('Recommended'));
    });

    test('AppLocalizations delivers refined Chinese strings (信达雅)', () {
      final l10nZh = lookupAppLocalizations(const Locale('zh'));
      expect(l10nZh.catalog, equals('软件目录'));
      expect(l10nZh.downloads, equals('传输管理'));
      expect(l10nZh.settings, equals('偏好设置'));
      expect(l10nZh.showInFinder, equals('在访达中显示'));
      expect(l10nZh.copyAllLogs, equals('复制全部日志'));
      expect(l10nZh.setDownloadDirTitle, equals('选择存储目录'));
      expect(l10nZh.systemDownloadsTitle, equals('系统下载文件夹'));
      expect(l10nZh.allPlatforms, equals('全平台'));
      expect(l10nZh.signOut, equals('退出登录'));
      expect(l10nZh.broadcomAuthTitle, equals('Broadcom 账户认证'));
      expect(l10nZh.tabInAppBrowser, equals('内嵌 Web 视图登录'));
      expect(l10nZh.welcomeTitle, equals('欢迎使用 VMwareGet'));
      expect(l10nZh.logInWithBroadcom, equals('登录 Broadcom 账户'));
      expect(l10nZh.speedLabel, equals('速率'));
      expect(l10nZh.etaLabel, equals('预计剩余'));
      expect(l10nZh.recommended, equals('推荐'));
    });

    test('AppLocalizations delivers pure Esperanto strings (eo)', () {
      final l10nEo = lookupAppLocalizations(const Locale('eo'));
      expect(l10nEo.catalog, equals('Katalogo'));
      expect(l10nEo.downloads, equals('Elŝutoj'));
      expect(l10nEo.settings, equals('Agordoj'));
      expect(l10nEo.showInFinder, equals('Montri en Finder'));
      expect(l10nEo.copyAllLogs, equals('Kopii Ĉiujn Protokolojn'));
      expect(l10nEo.setDownloadDirTitle, equals('Agordi Elŝutan Dosierujon'));
      expect(l10nEo.systemDownloadsTitle, equals('Sistema Elŝutujo'));
      expect(l10nEo.allPlatforms, equals('Ĉiuj platformoj'));
      expect(l10nEo.signOut, equals('Elsaluti'));
      expect(l10nEo.broadcomAuthTitle, equals('Aŭtentigo de Broadcom'));
      expect(l10nEo.tabInAppBrowser, equals('En-aplikaĵa Reto'));
      expect(l10nEo.welcomeTitle, equals('Bonvenon al VMwareGet'));
      expect(l10nEo.logInWithBroadcom, equals('Ensaluti per Broadcom'));
      expect(l10nEo.speedLabel, equals('Rapido'));
      expect(l10nEo.etaLabel, equals('Restas'));
      expect(l10nEo.recommended, equals('Rekomendita'));
    });
  });
}
