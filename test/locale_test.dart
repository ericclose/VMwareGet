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

    test('LocaleProvider persists and updates locale to Chinese', () async {
      final provider = LocaleProvider();
      await provider.loadLocale();
      await provider.setLocale(const Locale('zh'));

      expect(provider.locale.languageCode, equals('zh'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.storageKeyLocale), equals('zh'));

      // New instance should load 'zh'
      final newProvider = LocaleProvider();
      await newProvider.loadLocale();
      expect(newProvider.locale.languageCode, equals('zh'));
    });

    test('AppLocalizations delivers pure English strings in English mode', () {
      final l10nEn = AppLocalizations(const Locale('en'));
      expect(l10nEn.catalog, equals('Catalog'));
      expect(l10nEn.downloads, equals('Downloads'));
      expect(l10nEn.settings, equals('Settings'));
      expect(l10nEn.showInFinder, equals('Show in Finder'));
      expect(l10nEn.copyAllLogs, equals('Copy All Logs'));
      expect(l10nEn.setDownloadDirTitle, equals('Set Download Directory'));
      expect(l10nEn.systemDownloadsTitle, equals('System Downloads Folder'));
      expect(l10nEn.allPlatforms, equals('All Platforms'));
      expect(l10nEn.signOut, equals('Sign Out'));
      expect(l10nEn.broadcomAuthTitle, equals('Broadcom Authentication'));
      expect(l10nEn.tabInAppBrowser, equals('In-App Browser'));
      expect(l10nEn.welcomeTitle, equals('Welcome to VMwareGet'));
      expect(l10nEn.logInWithBroadcom, equals('Log In with Broadcom'));
      expect(l10nEn.speedLabel, equals('Speed'));
      expect(l10nEn.etaLabel, equals('ETA'));
      expect(l10nEn.recommended, equals('Recommended'));
    });

    test('AppLocalizations delivers pure Chinese strings in Chinese mode', () {
      final l10nZh = AppLocalizations(const Locale('zh'));
      expect(l10nZh.catalog, equals('产品目录'));
      expect(l10nZh.downloads, equals('下载列表'));
      expect(l10nZh.settings, equals('设置'));
      expect(l10nZh.showInFinder, equals('在访达中显示'));
      expect(l10nZh.copyAllLogs, equals('一键复制全部日志'));
      expect(l10nZh.setDownloadDirTitle, equals('设置下载保存目录'));
      expect(l10nZh.systemDownloadsTitle, equals('系统下载目录'));
      expect(l10nZh.allPlatforms, equals('全部平台'));
      expect(l10nZh.signOut, equals('退出登录'));
      expect(l10nZh.broadcomAuthTitle, equals('Broadcom 账户认证'));
      expect(l10nZh.tabInAppBrowser, equals('内置安全浏览器'));
      expect(l10nZh.welcomeTitle, equals('欢迎使用 VMwareGet'));
      expect(l10nZh.logInWithBroadcom, equals('使用 Broadcom 账号登录'));
      expect(l10nZh.speedLabel, equals('速度'));
      expect(l10nZh.etaLabel, equals('剩余时间'));
      expect(l10nZh.recommended, equals('推荐'));
    });
  });
}
