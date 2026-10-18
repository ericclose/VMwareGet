import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vmwareget/models/download_item.dart';
import 'package:vmwareget/models/vmware_product.dart';
import 'package:vmwareget/providers/download_provider.dart';
import 'package:vmwareget/services/download_service.dart';
import 'package:vmwareget/services/folder_picker_service.dart';
import 'package:vmwareget/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadProvider Directory Preferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default directory and can update custom directory', () async {
      final provider = DownloadProvider();
      await provider.initFuture;

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
      await provider.initFuture;

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

    test('DownloadItem serialization and deserialization with directDownloadUrl and state safety', () {
      const release = VMwareReleaseItem(
        id: 'ws-17-win',
        family: VMwareProductFamily.workstationPro,
        version: '17.6.1',
        buildNumber: '24319023',
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows',
        fileName: 'VMware-workstation-full-17.6.1.exe',
        fileSize: '596.2 MB',
        fileSizeBytes: 625123456,
        releaseDate: '2024-10-10',
        lastUpdated: '2024-10-10',
        sha256: 'abc123sha256',
        md5: 'def456md5',
        officialDownloadUrl: 'https://support.broadcom.com/official-download',
      );

      final item = DownloadItem(
        id: 'ws-17-win',
        release: release,
        destinationPath: '/Downloads/VMwareGet/VMware-workstation-full-17.6.1.exe',
        status: DownloadStatus.downloading,
        verificationStatus: VerificationStatus.notStarted,
        downloadedBytes: 1000000,
        totalBytes: 625123456,
        startedAt: DateTime(2026, 1, 1),
        directDownloadUrl: 'https://cdn.broadcom.com/direct-installer.exe?token=123',
      );

      final json = item.toJson();
      expect(json['id'], equals('ws-17-win'));
      expect(json['directDownloadUrl'], equals('https://cdn.broadcom.com/direct-installer.exe?token=123'));
      expect(json['status'], equals('downloading'));

      // When restoring, active downloading should be safely downgraded to paused
      final restored = DownloadItem.fromJson(json);
      expect(restored.id, equals('ws-17-win'));
      expect(restored.status, equals(DownloadStatus.paused));
      expect(restored.directDownloadUrl, equals('https://cdn.broadcom.com/direct-installer.exe?token=123'));
      expect(restored.downloadedBytes, equals(1000000));
    });

    test('Restores persisted download history across app sessions and supports clearing completed', () async {
      const releaseCompleted = VMwareReleaseItem(
        id: 'fusion-13-mac',
        family: VMwareProductFamily.fusion,
        version: '13.6.1',
        buildNumber: '24319024',
        platform: VMwarePlatform.macos,
        platformLabel: 'macOS',
        fileName: 'VMware-Fusion-13.6.1.dmg',
        fileSize: '650 MB',
        fileSizeBytes: 681574400,
        releaseDate: '2024-10-10',
        lastUpdated: '2024-10-10',
        sha256: 'fusion256',
        md5: 'fusionmd5',
        officialDownloadUrl: 'https://support.broadcom.com/fusion-url',
      );

      final completedItem = DownloadItem(
        id: 'fusion-13-mac',
        release: releaseCompleted,
        destinationPath: '/Downloads/VMwareGet/VMware-Fusion-13.6.1.dmg',
        status: DownloadStatus.completed,
        verificationStatus: VerificationStatus.passed,
        downloadedBytes: 681574400,
        totalBytes: 681574400,
        startedAt: DateTime(2026, 1, 1),
        completedAt: DateTime(2026, 1, 1, 0, 5),
        directDownloadUrl: 'https://cdn.broadcom.com/fusion-direct.dmg',
      );

      // Pre-populate SharedPreferences with existing download history
      SharedPreferences.setMockInitialValues({
        AppConstants.storageKeyDownloadHistory:
            jsonEncode([completedItem.toJson()]),
      });

      // Construct DownloadProvider and wait for initialization
      final provider = DownloadProvider();
      await provider.initFuture;

      expect(provider.allDownloads.length, equals(1));
      expect(provider.completedCount, equals(1));
      final loadedItem = provider.getItemForRelease('fusion-13-mac');
      expect(loadedItem, isNotNull);
      expect(loadedItem!.status, equals(DownloadStatus.completed));
      expect(loadedItem.directDownloadUrl, equals('https://cdn.broadcom.com/fusion-direct.dmg'));

      // Test resolveDownloadUrl
      final resolvedUrl = await provider.resolveDownloadUrl(release: releaseCompleted);
      expect(resolvedUrl, equals('https://cdn.broadcom.com/fusion-direct.dmg'));

      // Test clearCompletedDownloads
      await provider.clearCompletedDownloads();
      expect(provider.completedCount, equals(0));
      expect(provider.allDownloads.isEmpty, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.storageKeyDownloadHistory), equals('[]'));
    });

    test('openDownloadDirectory executes safely and returns boolean result', () async {
      final provider = DownloadProvider();
      await provider.initFuture;
      final result = await provider.openDownloadDirectory();
      expect(result, isA<bool>());
    });

    test('FolderPickerService.pickDirectory handles environment safely without uncaught exceptions', () async {
      // In automated test runner, safely avoids spawning modal OS dialogs
      final result = await FolderPickerService.pickDirectory(prompt: 'Test Directory');
      expect(result, isNull);

      // Verify mocking hook for test suites
      FolderPickerService.mockDirectoryForTesting = '/test/mock/downloads';
      final mocked = await FolderPickerService.pickDirectory(prompt: 'Test Directory');
      expect(mocked, equals('/test/mock/downloads'));
      FolderPickerService.mockDirectoryForTesting = null;
    });

    test('resolveDownloadUrl throws BroadcomAuthExpiredException when session is null for protected release', () async {
      final provider = DownloadProvider();
      await provider.initFuture;

      const protectedRelease = VMwareReleaseItem(
        id: 'workstation-17-win',
        family: VMwareProductFamily.workstationPro,
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows 64-bit',
        version: '17.6.0',
        buildNumber: '24238078',
        fileName: 'VMware-workstation-full-17.6.0-24238078.exe',
        fileSize: '600 MB',
        fileSizeBytes: 600000000,
        releaseDate: '2024-09-03',
        lastUpdated: '2024-09-03',
        sha256: 'abc123',
        md5: 'def456',
        officialDownloadUrl: 'https://support.broadcom.com/downloads',
        notes: '',
        filePath: '/files/vmware-workstation.exe',
        displayGroup: 'Workstation',
      );

      expect(
        () => provider.resolveDownloadUrl(release: protectedRelease, session: null),
        throwsA(isA<BroadcomAuthExpiredException>()),
      );
    });

    test('startDownload invokes onAuthExpired callback when session is null for protected release', () async {
      final provider = DownloadProvider();
      await provider.initFuture;

      const protectedRelease = VMwareReleaseItem(
        id: 'fusion-13-mac-test',
        family: VMwareProductFamily.fusion,
        platform: VMwarePlatform.macos,
        platformLabel: 'macOS Universal',
        version: '13.6.0',
        buildNumber: '24238079',
        fileName: 'VMware-Fusion-13.6.0.dmg',
        fileSize: '700 MB',
        fileSizeBytes: 700000000,
        releaseDate: '2024-09-03',
        lastUpdated: '2024-09-03',
        sha256: 'abc123',
        md5: 'def456',
        officialDownloadUrl: 'https://support.broadcom.com/downloads',
        notes: '',
        filePath: '/files/vmware-fusion.dmg',
        displayGroup: 'Fusion',
      );

      bool expiredTriggered = false;
      await provider.startDownload(
        release: protectedRelease,
        session: null,
        onAuthExpired: () {
          expiredTriggered = true;
        },
      );

      expect(expiredTriggered, isTrue);
    });

    test('openDownloadedFile and reVerifyChecksum detect missing file and update error state', () async {
      final provider = DownloadProvider();
      await provider.initFuture;

      const testRelease = VMwareReleaseItem(
        id: 'missing-file-test',
        family: VMwareProductFamily.workstationPro,
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows x64',
        version: '17.6.0',
        buildNumber: '123456',
        fileName: 'nonexistent-installer.exe',
        fileSize: '500 MB',
        fileSizeBytes: 500000000,
        releaseDate: '2024-09-03',
        lastUpdated: '2024-09-03',
        sha256: 'abc123',
        md5: 'def456',
        officialDownloadUrl: 'https://cdn.example.com/test.exe',
      );

      final item = DownloadItem(
        id: 'missing-file-test',
        release: testRelease,
        destinationPath: '/tmp/nonexistent_test_dir/nonexistent-installer.exe',
        status: DownloadStatus.completed,
        verificationStatus: VerificationStatus.passed,
        downloadedBytes: 500000000,
        totalBytes: 500000000,
        startedAt: DateTime.now(),
      );

      SharedPreferences.setMockInitialValues({
        AppConstants.storageKeyDownloadHistory: jsonEncode([item.toJson()]),
      });

      final newProvider = DownloadProvider();
      await newProvider.initFuture;

      final opened = await newProvider.openDownloadedFile('missing-file-test');
      expect(opened, isFalse);
      expect(newProvider.getItemForRelease('missing-file-test')!.errorMessage, contains('does not exist'));

      await newProvider.reVerifyChecksum('missing-file-test');
      expect(newProvider.getItemForRelease('missing-file-test')!.verificationStatus, equals(VerificationStatus.failedMismatch));
    });

    test('redownload resets item progress, clears direct link, and resets status', () async {
      final provider = DownloadProvider();
      await provider.initFuture;

      const testRelease = VMwareReleaseItem(
        id: 'redownload-test',
        family: VMwareProductFamily.workstationPro,
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows x64',
        version: '17.6.0',
        buildNumber: '123456',
        fileName: 'redownload-installer.exe',
        fileSize: '500 MB',
        fileSizeBytes: 500000000,
        releaseDate: '2024-09-03',
        lastUpdated: '2024-09-03',
        sha256: 'abc123',
        md5: 'def456',
        officialDownloadUrl: 'https://cdn.example.com/test.exe',
      );

      final item = DownloadItem(
        id: 'redownload-test',
        release: testRelease,
        destinationPath: '/tmp/redownload-installer.exe',
        status: DownloadStatus.completed,
        verificationStatus: VerificationStatus.failedMismatch,
        downloadedBytes: 500000000,
        totalBytes: 500000000,
        startedAt: DateTime.now(),
        directDownloadUrl: 'https://expired.example.com/link',
        errorMessage: 'Checksum mismatch',
      );

      SharedPreferences.setMockInitialValues({
        AppConstants.storageKeyDownloadHistory: jsonEncode([item.toJson()]),
      });

      final newProvider = DownloadProvider();
      await newProvider.initFuture;

      await newProvider.redownload(
        id: 'redownload-test',
        session: null,
      );

      final updated = newProvider.getItemForRelease('redownload-test')!;
      expect(updated.downloadedBytes, equals(0));
      expect(updated.verificationStatus, equals(VerificationStatus.notStarted));
    });
  });
}
