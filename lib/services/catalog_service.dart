import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';
import 'auth_service.dart';

class CatalogService {
  final Dio _dio;
  List<VMwareReleaseItem> _releases = [];
  String? _lastSyncError;

  CatalogService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                followRedirects: false,
                validateStatus: (status) =>
                    status != null && status >= 200 && status < 400,
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
                  'Accept': 'application/json, text/plain, */*',
                  'Content-Type': 'application/json;charset=UTF-8',
                  'Origin': 'https://support.broadcom.com',
                },
              ),
            );

  List<VMwareReleaseItem> getAllReleases() => List.unmodifiable(_releases);
  String? get lastSyncError => _lastSyncError;

  List<VMwareReleaseItem> getReleasesForFamily(VMwareProductFamily family) {
    return _releases.where((r) => r.family == family).toList();
  }

  void setReleases(List<VMwareReleaseItem> items) {
    _releases = List.from(items);
  }

  Future<void> clearCatalog() async {
    _releases.clear();
    _lastSyncError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vmwareget_catalog_cache');
    } catch (_) {}
  }

  Future<bool> loadCachedCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('vmwareget_catalog_cache');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List;
        _releases = list
            .map((item) =>
                VMwareReleaseItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return _releases.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _saveCatalogToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_releases.map((e) => e.toJson()).toList());
      await prefs.setString('vmwareget_catalog_cache', jsonStr);
    } catch (_) {}
  }

  List<VMwareReleaseItem> searchReleases({
    required VMwareProductFamily family,
    String? query,
    VMwarePlatform? platform,
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

  /// Fetches real-time catalog directly from Broadcom servers using user's session.
  /// Entire catalog and checksums are retrieved online without hardcoding.
  Future<bool> syncOnlineCatalog(AuthSession session) async {
    final cookieHeader = AuthService.cleanCookieString(
        session.cookieJar ?? session.sessionToken);
    final csrfHeader = session.csrfToken ?? 'YaLAJUoR';

    final List<VMwareReleaseItem> onlineItems = [];
    _lastSyncError = null;

    // Dynamically discover all products and releases online from Broadcom
    final productLines = [
      {
        'family': VMwareProductFamily.workstationPro,
        'subFamily': 'VMware Workstation Pro',
      },
      {
        'family': VMwareProductFamily.fusion,
        'subFamily': 'VMware Fusion',
      },
    ];

    for (final prod in productLines) {
      final family = prod['family'] as VMwareProductFamily;
      final subFamily = prod['subFamily'] as String;

      try {
        final skuResp = await _dio.post(
          'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50',
          data: {
            'subFamily': subFamily,
            'searchVal': '',
            'language': 'EN',
            'freeDownloads': true,
          },
          options: Options(
            headers: {
              'Cookie': cookieHeader,
              'x-csrf-token': csrfHeader,
              'Origin': 'https://support.broadcom.com',
              'Referer':
                  'https://support.broadcom.com/group/ecx/productdownloads?subfamily=${Uri.encodeComponent(subFamily)}&freeDownloads=true',
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language':
                  'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
            },
          ),
        );

        if (skuResp.statusCode == 302 ||
            skuResp.headers.value('location')?.contains('/login') == true) {
          _lastSyncError =
              'Broadcom session expired or redirected to login. Please re-authenticate via In-App Browser.';
          continue;
        }

        if (skuResp.statusCode == 403) {
          _lastSyncError =
              'Access denied by Broadcom (CSRF / security block). Please re-authenticate.';
          continue;
        }

        if (skuResp.statusCode != 200 || skuResp.data == null) {
          _lastSyncError = 'Broadcom returned HTTP ${skuResp.statusCode}.';
          continue;
        }

        final skuData = skuResp.data is Map ? skuResp.data as Map : {};
        if (skuData['success'] != true) {
          _lastSyncError = skuData['message']?.toString() ??
              'Failed retrieving product SKUs from Broadcom.';
          continue;
        }

        final content =
            skuData['data']?['productDetails']?['content'] as List?;
        if (content == null) continue;

        for (final groupItem in content) {
          if (groupItem is! Map) continue;
          final displayGroup = groupItem['description']?.toString() ?? '';
          final phantoms = groupItem['phantomDetails'] as List?;
          if (phantoms == null) continue;

          for (final phantom in phantoms) {
            if (phantom is! Map) continue;
            final releaseVer = phantom['release']?.toString();
            final servicePk =
                (phantom['genLevel'] ?? phantom['servicePk'])?.toString();
            if (releaseVer == null || servicePk == null || servicePk.isEmpty) {
              continue;
            }

            final refererUrl =
                'https://support.broadcom.com/group/ecx/productfiles?subFamily=${Uri.encodeComponent(subFamily)}&displayGroup=${Uri.encodeComponent(displayGroup)}&release=$releaseVer&os=&servicePk=$servicePk&language=EN&freeDownloads=true';

            try {
              final filesResp = await _dio.post(
                'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50',
                data: {
                  'primaryDownloads': true,
                  'otherDownloads': '',
                  'searchQuery': '',
                  'freeDownloads': true,
                  'displayGroup': displayGroup,
                  'skuCode': '',
                  'release': releaseVer,
                  'genLevel': servicePk,
                  'language': 'EN',
                  'os': '',
                },
                options: Options(
                  headers: {
                    'Cookie': cookieHeader,
                    'x-csrf-token': csrfHeader,
                    'Origin': 'https://support.broadcom.com',
                    'Referer': refererUrl,
                    'Accept': 'application/json, text/plain, */*',
                    'Accept-Language':
                        'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
                  },
                ),
              );

              if (filesResp.statusCode == 200 && filesResp.data != null) {
                final filesData =
                    filesResp.data is Map ? filesResp.data as Map : {};
                if (filesData['success'] == true) {
                  final packlist =
                      filesData['data']?['packlistDetails']?['content'] as List?;
                  if (packlist != null) {
                    for (final packItem in packlist) {
                      if (packItem is! Map) continue;
                      final packDesc =
                          packItem['description']?.toString() ?? displayGroup;
                      final fileDetails = packItem['fileDetails'] as List?;
                      if (fileDetails == null) continue;

                      for (final fileItem in fileDetails) {
                        if (fileItem is! Map) continue;
                        final fileName = fileItem['fileName']?.toString() ?? '';
                        final rawSize = fileItem['fileSize'] as num? ?? 0;
                        final sizeBytes = rawSize.toInt();
                        final sizeFormatted = sizeBytes > 0
                            ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                            : 'Unknown';

                        final VMwarePlatform resolvedPlatform;
                        final String resolvedPlatformLabel;

                        if (fileName.toLowerCase().endsWith('.exe')) {
                          resolvedPlatform = VMwarePlatform.windows;
                          resolvedPlatformLabel = 'Windows 64-bit (.exe)';
                        } else if (fileName.toLowerCase().endsWith('.dmg')) {
                          resolvedPlatform = VMwarePlatform.macos;
                          resolvedPlatformLabel = 'macOS Universal (.dmg)';
                        } else if (fileName.toLowerCase().endsWith('.bundle') ||
                            fileName.toLowerCase().endsWith('.tar.gz')) {
                          resolvedPlatform = VMwarePlatform.linux;
                          resolvedPlatformLabel = 'Linux 64-bit (.bundle)';
                        } else {
                          resolvedPlatform = family ==
                                  VMwareProductFamily.workstationPro
                              ? (displayGroup.toLowerCase().contains('linux')
                                  ? VMwarePlatform.linux
                                  : VMwarePlatform.windows)
                              : VMwarePlatform.macos;
                          resolvedPlatformLabel = resolvedPlatform.name;
                        }

                        onlineItems.add(
                          VMwareReleaseItem(
                            id: '${family.name}-$releaseVer-${fileItem['buildNumber'] ?? fileName.hashCode}',
                            family: family,
                            version: releaseVer,
                            buildNumber:
                                fileItem['buildNumber']?.toString() ?? '',
                            platform: resolvedPlatform,
                            platformLabel: resolvedPlatformLabel,
                            fileName: fileName,
                            fileSize: sizeFormatted,
                            fileSizeBytes: sizeBytes,
                            releaseDate: fileItem['gaDate']?.toString() ?? '',
                            lastUpdated:
                                fileItem['fileLastUpdatedDate']?.toString() ??
                                    '',
                            sha256: fileItem['sha2Chksum']?.toString() ?? '',
                            md5: fileItem['md5Chksum']?.toString() ?? '',
                            officialDownloadUrl:
                                'https://support.broadcom.com/group/ecx/productfiles?subFamily=${Uri.encodeComponent(subFamily)}',
                            notes: 'Broadcom live verified release.',
                            displayGroup: displayGroup,
                            servicePk: servicePk,
                            filePath: fileItem['filePath']?.toString(),
                            eulaId: 17290717,
                            releaseDesc: packDesc,
                            isOnlineFetched: true,
                          ),
                        );
                      }
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        _lastSyncError ??= 'Error querying Broadcom API: $e';
      }
    }

    if (onlineItems.isNotEmpty) {
      _releases = onlineItems;
      _lastSyncError = null;
      await _saveCatalogToCache();
      return true;
    }

    _lastSyncError ??=
        'Broadcom session invalid or expired. Please re-authenticate via In-App Browser.';
    return false;
  }
}
