import 'package:flutter_test/flutter_test.dart';
import 'package:vmwareget/models/vmware_product.dart';
import 'package:vmwareget/services/catalog_service.dart';

void main() {
  late CatalogService catalogService;

  setUp(() {
    catalogService = CatalogService();
  });

  test('Catalog is strictly empty initially with no hardcoded fallback entries', () {
    expect(catalogService.getAllReleases().isEmpty, isTrue,
        reason: 'Catalog must not contain hardcoded fallback items');
    expect(
        catalogService
            .getReleasesForFamily(VMwareProductFamily.workstationPro)
            .isEmpty,
        isTrue);
    expect(
        catalogService.getReleasesForFamily(VMwareProductFamily.fusion).isEmpty,
        isTrue);
  });

  test('Dynamically loaded releases satisfy SRS technical metadata requirements', () {
    final sampleReleases = [
      const VMwareReleaseItem(
        id: 'ws-pro-26h1u1-win-25688693',
        family: VMwareProductFamily.workstationPro,
        version: '26H1u1',
        buildNumber: '25688693',
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows 64-bit (.exe)',
        fileName: 'VMware-Workstation-Full-26H1u1-25688693.exe',
        fileSize: '267.6 MB',
        fileSizeBytes: 280609368,
        releaseDate: 'Sep 03, 2026',
        lastUpdated: 'Aug 26, 2026',
        sha256:
            '3d775c3c2153600eef4642f95d519a514ba7e861400bda2598352bff792db473',
        md5: '9209838fcb622438e87422a25622bfa7',
        officialDownloadUrl:
            'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro',
        notes: 'Broadcom live verified release.',
        displayGroup: 'VMware Workstation Pro 26H1 for Windows',
        servicePk: '546859',
        filePath: '546859/VMware-Workstation-Full-26H1u1-25688693.exe',
        eulaId: 17290717,
        releaseDesc: 'VMware Workstation Pro (For Windows)',
        isOnlineFetched: true,
      ),
      const VMwareReleaseItem(
        id: 'fusion-26h1u1-macos-25689522',
        family: VMwareProductFamily.fusion,
        version: '26H1u1',
        buildNumber: '25689522',
        platform: VMwarePlatform.macos,
        platformLabel: 'macOS Universal (.dmg)',
        fileName: 'VMware-Fusion-26H1u1-25689522_universal.dmg',
        fileSize: '497.2 MB',
        fileSizeBytes: 521403629,
        releaseDate: 'Sep 03, 2026',
        lastUpdated: 'Aug 26, 2026',
        sha256:
            'df1911f8de651818a43c20ca1054403da7e39534f15a2e0e0f9d41ffcf728ab8',
        md5: '72390276a1eaef54d57363e008b98c8d',
        officialDownloadUrl:
            'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Fusion',
        notes: 'Broadcom live verified release.',
        displayGroup: 'VMware Fusion 26H1',
        servicePk: '546858',
        filePath: '546858/VMware-Fusion-26H1u1-25689522_universal.dmg',
        eulaId: 17290717,
        releaseDesc: 'VMware Fusion (for Intel-based and Apple silicon Macs)',
        isOnlineFetched: true,
      ),
    ];

    catalogService.setReleases(sampleReleases);

    final workstation =
        catalogService.getReleasesForFamily(VMwareProductFamily.workstationPro);
    final fusion =
        catalogService.getReleasesForFamily(VMwareProductFamily.fusion);

    expect(workstation.isNotEmpty, isTrue);
    expect(fusion.isNotEmpty, isTrue);

    for (final release in [...workstation, ...fusion]) {
      expect(release.fileName.isNotEmpty, isTrue,
          reason: 'File Name must not be empty');
      expect(release.releaseDate.isNotEmpty, isTrue,
          reason: 'Release Date must not be empty');
      expect(release.lastUpdated.isNotEmpty, isTrue,
          reason: 'Last Updated must not be empty');
      expect(release.sha256.length, equals(64),
          reason: 'SHA2 (SHA-256) must be a 64-character hex string');
      expect(release.md5.length, equals(32),
          reason: 'MD5 must be a 32-character hex string');
      expect(release.isOnlineFetched, isTrue);
    }
  });

  test('Search filter filters accurately by version and file name', () {
    catalogService.setReleases([
      const VMwareReleaseItem(
        id: 'ws-pro-26h1u1-win-25688693',
        family: VMwareProductFamily.workstationPro,
        version: '26H1u1',
        buildNumber: '25688693',
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows 64-bit (.exe)',
        fileName: 'VMware-Workstation-Full-26H1u1-25688693.exe',
        fileSize: '267.6 MB',
        fileSizeBytes: 280609368,
        releaseDate: 'Sep 03, 2026',
        lastUpdated: 'Aug 26, 2026',
        sha256:
            '3d775c3c2153600eef4642f95d519a514ba7e861400bda2598352bff792db473',
        md5: '9209838fcb622438e87422a25622bfa7',
        officialDownloadUrl:
            'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro',
        notes: 'Broadcom live verified release.',
        displayGroup: 'VMware Workstation Pro 26H1 for Windows',
        servicePk: '546859',
        filePath: '546859/VMware-Workstation-Full-26H1u1-25688693.exe',
        eulaId: 17290717,
        releaseDesc: 'VMware Workstation Pro (For Windows)',
        isOnlineFetched: true,
      ),
    ]);

    final results = catalogService.searchReleases(
      family: VMwareProductFamily.workstationPro,
      query: '26H1u1',
    );

    expect(results.isNotEmpty, isTrue);
    expect(results.every((r) => r.version == '26H1u1'), isTrue);
  });

  test('searchReleases matches case-insensitively across fileName and platformLabel', () {
    catalogService.setReleases([
      const VMwareReleaseItem(
        id: 'ws-pro-26h1u1-win-25688693',
        family: VMwareProductFamily.workstationPro,
        version: '26H1u1',
        buildNumber: '25688693',
        platform: VMwarePlatform.windows,
        platformLabel: 'Windows 64-bit (.exe)',
        fileName: 'VMware-Workstation-Full-26H1u1-25688693.exe',
        fileSize: '267.6 MB',
        fileSizeBytes: 280609368,
        releaseDate: 'Sep 03, 2026',
        lastUpdated: 'Aug 26, 2026',
        sha256: '3d775c3c2153600eef4642f95d519a514ba7e861400bda2598352bff792db473',
        md5: '9209838fcb622438e87422a25622bfa7',
        officialDownloadUrl: 'https://support.broadcom.com',
        isOnlineFetched: true,
      ),
      const VMwareReleaseItem(
        id: 'fusion-26h1u1-macos-25689522',
        family: VMwareProductFamily.fusion,
        version: '26H1u1',
        buildNumber: '25689522',
        platform: VMwarePlatform.macos,
        platformLabel: 'macOS Universal (.dmg)',
        fileName: 'VMware-Fusion-26H1u1-25689522_universal.dmg',
        fileSize: '497.2 MB',
        fileSizeBytes: 521403629,
        releaseDate: 'Sep 03, 2026',
        lastUpdated: 'Aug 26, 2026',
        sha256: 'df1911f8de651818a43c20ca1054403da7e39534f15a2e0e0f9d41ffcf728ab8',
        md5: '72390276a1eaef54d57363e008b98c8d',
        officialDownloadUrl: 'https://support.broadcom.com',
        isOnlineFetched: true,
      ),
    ]);

    // Search by lowercase platform
    final winResults = catalogService.searchReleases(
      family: VMwareProductFamily.workstationPro,
      query: 'windows',
    );
    expect(winResults.length, equals(1));
    expect(winResults.first.id, equals('ws-pro-26h1u1-win-25688693'));

    // Search by uppercase file extension
    final macResults = catalogService.searchReleases(
      family: VMwareProductFamily.fusion,
      query: '.DMG',
    );
    expect(macResults.length, equals(1));
    expect(macResults.first.id, equals('fusion-26h1u1-macos-25689522'));

    // Blank query returns all releases in family
    final allInFamily = catalogService.searchReleases(
      family: VMwareProductFamily.workstationPro,
      query: '   ',
    );
    expect(allInFamily.length, equals(1));
  });
}
