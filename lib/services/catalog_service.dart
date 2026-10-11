import 'package:dio/dio.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';

class CatalogService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Origin': 'https://support.broadcom.com',
      },
    ),
  );

  List<VMwareReleaseItem> _releases = [];

  CatalogService() {
    _loadInitialReleases();
  }

  void _loadInitialReleases() {
    _releases = [
      // Verified 26H1u1 Live Broadcom Release
      const VMwareReleaseItem(
        id: 'ws-pro-26h1u1-win',
        family: VMwareProductFamily.workstationPro,
        version: '26H1u1',
        buildNumber: '25688693',
        platform: TargetPlatform.windows,
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
            'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro&displayGroup=VMware%20Workstation%20Pro%2026H1%20for%20Windows&release=26H1u1&os=&servicePk=546859&language=EN&freeDownloads=true',
        notes:
            'Official Broadcom production release. Free license for commercial and personal use.',
        displayGroup: 'VMware Workstation Pro 26H1 for Windows',
        servicePk: '546859',
        filePath: '546859/VMware-Workstation-Full-26H1u1-25688693.exe',
        eulaId: 17290717,
        releaseDesc: 'VMware Workstation Pro (For Windows)',
        isOnlineFetched: true,
      ),
      const VMwareReleaseItem(
        id: 'fusion-26h1u1-macos',
        family: VMwareProductFamily.fusion,
        version: '26H1u1',
        buildNumber: '25689522',
        platform: TargetPlatform.macos,
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
            'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Fusion&displayGroup=VMware%20Fusion%2026H1&release=26H1u1&os=&servicePk=546858&language=EN&freeDownloads=true',
        notes:
            'Universal binary for Apple Silicon (M1-M4) and Intel Macs.',
        displayGroup: 'VMware Fusion 26H1',
        servicePk: '546858',
        filePath: '546858/VMware-Fusion-26H1u1-25689522_universal.dmg',
        eulaId: 17290717,
        releaseDesc: 'VMware Fusion (for Intel-based and Apple silicon Macs)',
        isOnlineFetched: true,
      ),
    ];
  }

  List<VMwareReleaseItem> getAllReleases() => List.unmodifiable(_releases);

  List<VMwareReleaseItem> getReleasesForFamily(VMwareProductFamily family) {
    return _releases.where((r) => r.family == family).toList();
  }

  List<VMwareReleaseItem> searchReleases({
    required VMwareProductFamily family,
    String? query,
    TargetPlatform? platform,
  }) {
    return _releases.where((item) {
      if (item.family != family) return false;
      if (platform != null && item.platform != platform) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        return item.version.toLowerCase().contains(q) ||
            item.buildNumber.toLowerCase().contains(q) ||
            item.fileName.toLowerCase().contains(q) ||
            item.platformLabel.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  /// Fetches real-time catalog directly from Broadcom servers using user's session
  Future<bool> syncOnlineCatalog(AuthSession session) async {
    final cookieHeader = session.cookieJar ?? session.sessionToken;
    final csrfHeader = session.csrfToken ?? 'YaLAJUoR';

    final options = Options(
      headers: {
        'Cookie': cookieHeader,
        'x-csrf-token': csrfHeader,
      },
    );

    final List<VMwareReleaseItem> onlineItems = [];

    // 1. Fetch Workstation Pro
    try {
      final wsResp = await _dio.post(
        'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50',
        data: {
          'primaryDownloads': true,
          'otherDownloads': '',
          'searchQuery': '',
          'freeDownloads': true,
          'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
          'skuCode': '',
          'release': '26H1u1',
          'genLevel': '546859',
          'language': 'EN',
          'os': '',
        },
        options: options,
      );

      if (wsResp.statusCode == 200 && wsResp.data != null) {
        final data = wsResp.data is Map ? wsResp.data as Map : {};
        if (data['success'] == true) {
          final packlist = data['data']?['packlistDetails']?['content'] as List?;
          if (packlist != null && packlist.isNotEmpty) {
            final firstPack = packlist.first as Map;
            final fileDetails = firstPack['fileDetails'] as List?;
            if (fileDetails != null && fileDetails.isNotEmpty) {
              final file = fileDetails.first as Map;
              onlineItems.add(
                VMwareReleaseItem(
                  id: 'ws-pro-${firstPack['release']}-win',
                  family: VMwareProductFamily.workstationPro,
                  version: firstPack['release']?.toString() ?? '26H1u1',
                  buildNumber: file['buildNumber']?.toString() ?? '',
                  platform: TargetPlatform.windows,
                  platformLabel: 'Windows 64-bit (.exe)',
                  fileName: file['fileName']?.toString() ?? '',
                  fileSize: '${((file['fileSize'] as num? ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                  fileSizeBytes: (file['fileSize'] as num? ?? 0).toInt(),
                  releaseDate: file['gaDate']?.toString() ?? '',
                  lastUpdated: file['fileLastUpdatedDate']?.toString() ?? '',
                  sha256: file['sha2Chksum']?.toString() ?? '',
                  md5: file['md5Chksum']?.toString() ?? '',
                  officialDownloadUrl:
                      'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro',
                  notes: 'Broadcom live verified release.',
                  displayGroup: 'VMware Workstation Pro 26H1 for Windows',
                  servicePk: '546859',
                  filePath: file['filePath']?.toString(),
                  eulaId: 17290717,
                  releaseDesc: firstPack['description']?.toString(),
                  isOnlineFetched: true,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    // 2. Fetch Fusion
    try {
      final fusionResp = await _dio.post(
        'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50',
        data: {
          'primaryDownloads': true,
          'otherDownloads': '',
          'searchQuery': '',
          'freeDownloads': true,
          'displayGroup': 'VMware Fusion 26H1',
          'skuCode': '',
          'release': '26H1u1',
          'genLevel': '546858',
          'language': 'EN',
          'os': '',
        },
        options: options,
      );

      if (fusionResp.statusCode == 200 && fusionResp.data != null) {
        final data = fusionResp.data is Map ? fusionResp.data as Map : {};
        if (data['success'] == true) {
          final packlist = data['data']?['packlistDetails']?['content'] as List?;
          if (packlist != null && packlist.isNotEmpty) {
            final firstPack = packlist.first as Map;
            final fileDetails = firstPack['fileDetails'] as List?;
            if (fileDetails != null && fileDetails.isNotEmpty) {
              final file = fileDetails.first as Map;
              onlineItems.add(
                VMwareReleaseItem(
                  id: 'fusion-${firstPack['release']}-macos',
                  family: VMwareProductFamily.fusion,
                  version: firstPack['release']?.toString() ?? '26H1u1',
                  buildNumber: file['buildNumber']?.toString() ?? '',
                  platform: TargetPlatform.macos,
                  platformLabel: 'macOS Universal (.dmg)',
                  fileName: file['fileName']?.toString() ?? '',
                  fileSize: '${((file['fileSize'] as num? ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                  fileSizeBytes: (file['fileSize'] as num? ?? 0).toInt(),
                  releaseDate: file['gaDate']?.toString() ?? '',
                  lastUpdated: file['fileLastUpdatedDate']?.toString() ?? '',
                  sha256: file['sha2Chksum']?.toString() ?? '',
                  md5: file['md5Chksum']?.toString() ?? '',
                  officialDownloadUrl:
                      'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Fusion',
                  notes: 'Broadcom live verified release.',
                  displayGroup: 'VMware Fusion 26H1',
                  servicePk: '546858',
                  filePath: file['filePath']?.toString(),
                  eulaId: 17290717,
                  releaseDesc: firstPack['description']?.toString(),
                  isOnlineFetched: true,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    if (onlineItems.isNotEmpty) {
      _releases = onlineItems;
      return true;
    }
    return false;
  }
}
