import 'package:flutter_test/flutter_test.dart';
import 'package:vmwareget/models/vmware_product.dart';
import 'package:vmwareget/services/catalog_service.dart';

void main() {
  late CatalogService catalogService;

  setUp(() {
    catalogService = CatalogService();
  });

  test('Catalog contains valid Workstation Pro and Fusion releases', () {
    final workstation =
        catalogService.getReleasesForFamily(VMwareProductFamily.workstationPro);
    final fusion =
        catalogService.getReleasesForFamily(VMwareProductFamily.fusion);

    expect(workstation.isNotEmpty, isTrue);
    expect(fusion.isNotEmpty, isTrue);

    // Verify all releases satisfy SRS technical metadata requirements
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
    }
  });

  test('Search filter filters accurately by version and file name', () {
    final results = catalogService.searchReleases(
      family: VMwareProductFamily.workstationPro,
      query: '26H1u1',
    );

    expect(results.isNotEmpty, isTrue);
    expect(results.every((r) => r.version == '26H1u1'), isTrue);
  });
}
