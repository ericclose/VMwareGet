import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vmwareget/providers/download_provider.dart';
import 'package:vmwareget/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadProvider Directory Preferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default directory and can update custom directory', () async {
      final provider = DownloadProvider();
      // Allow async _initDirectory to settle
      await Future.delayed(const Duration(milliseconds: 50));

      final defaultDir = provider.defaultSystemDownloadDir;
      expect(defaultDir, isNotEmpty);

      // Change directory
      const customPath = '/tmp/custom_vmware_downloads';
      await provider.setDownloadDirectory(customPath);

      expect(provider.downloadDirectory, equals(customPath));
      expect(provider.isDownloadDirConfirmed, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.storageKeyDownloadDir), equals(customPath));
      expect(prefs.getBool('vmwareget_download_dir_confirmed'), isTrue);

      // Reset directory
      await provider.resetToDefaultDownloadDirectory();
      expect(provider.downloadDirectory, equals(defaultDir));
      expect(prefs.containsKey(AppConstants.storageKeyDownloadDir), isFalse);
    });

    test('Initializes with default 16 threads and persists custom thread count up to 64', () async {
      final provider = DownloadProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.downloadThreads, equals(16));

      // Update to 32 threads
      await provider.setDownloadThreads(32);
      expect(provider.downloadThreads, equals(32));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppConstants.storageKeyDownloadThreads), equals(32));

      // Test clamping: exceeds max (64)
      await provider.setDownloadThreads(128);
      expect(provider.downloadThreads, equals(64));
      expect(prefs.getInt(AppConstants.storageKeyDownloadThreads), equals(64));

      // Test clamping: below min (1)
      await provider.setDownloadThreads(0);
      expect(provider.downloadThreads, equals(1));
      expect(prefs.getInt(AppConstants.storageKeyDownloadThreads), equals(1));
    });
  });
}
