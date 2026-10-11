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
  });
}
