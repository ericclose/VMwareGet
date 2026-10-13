import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';
import '../utils/json_utils.dart';
import 'auth_service.dart';
import 'diagnostic_service.dart';

class CatalogService {
  final Dio _dio;
  List<VMwareReleaseItem> _releases = [];
  String? _lastSyncError;

  CatalogService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 45),
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
        DiagnosticService.instance.info(
          'Catalog',
          'Loaded ${_releases.length} cached software releases from local storage',
        );
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
      DiagnosticService.instance.info(
        'Catalog',
        'Cached ${_releases.length} software releases to local storage',
      );
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
  /// Uses concurrent batch fetching for optimal throughput and logs latency metrics.
  Future<bool> syncOnlineCatalog(AuthSession session) async {
    final cookieHeader = AuthService.cleanCookieString(
        session.cookieJar ?? session.sessionToken);
    final csrfHeader = session.csrfToken ?? '';
    final totalSw = Stopwatch()..start();

    DiagnosticService.instance.info(
      'Catalog',
      'Starting concurrent online catalog synchronization for: ${session.email}',
      'CSRF token: $csrfHeader, Cookie keys: ${cookieHeader.split(';').map((s) => s.split('=').first.trim()).join(', ')}',
    );

    final List<VMwareReleaseItem> onlineItems = [];
    _lastSyncError = null;

    // Fetch Workstation Pro and Fusion in parallel
    final results = await Future.wait([
      _fetchFamilyCatalog(
        family: VMwareProductFamily.workstationPro,
        subFamily: 'VMware Workstation Pro',
        cookieHeader: cookieHeader,
        csrfHeader: csrfHeader,
      ),
      _fetchFamilyCatalog(
        family: VMwareProductFamily.fusion,
        subFamily: 'VMware Fusion',
        cookieHeader: cookieHeader,
        csrfHeader: csrfHeader,
      ),
    ]);

    for (final list in results) {
      onlineItems.addAll(list);
    }

    totalSw.stop();

    if (onlineItems.isNotEmpty) {
      _releases = onlineItems;
      _lastSyncError = null;
      await _saveCatalogToCache();
      DiagnosticService.instance.info(
        'Catalog',
        'Catalog sync completed in ${(totalSw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s! Retrieved ${onlineItems.length} official packages',
      );
      return true;
    }

    _lastSyncError ??=
        'Broadcom session invalid or expired. Please re-authenticate via In-App Browser.';
    DiagnosticService.instance.warn(
      'Catalog',
      'Catalog sync finished with 0 items after ${(totalSw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s: $_lastSyncError',
    );
    return false;
  }

  Future<List<VMwareReleaseItem>> _fetchFamilyCatalog({
    required VMwareProductFamily family,
    required String subFamily,
    required String cookieHeader,
    required String csrfHeader,
  }) async {
    final List<VMwareReleaseItem> familyItems = [];
    final familySw = Stopwatch()..start();

    String currentCsrf = csrfHeader;
    if (currentCsrf.isEmpty) {
      final dynToken = await AuthService().fetchDynamicCsrfToken(cookieHeader);
      if (dynToken != null && dynToken.isNotEmpty) {
        currentCsrf = dynToken;
      }
    }

    try {
      DiagnosticService.instance.http(
        'Catalog',
        'POST getProductSkuDetails for $subFamily',
        'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50',
      );

      final skuSw = Stopwatch()..start();
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
            'x-csrf-token': currentCsrf,
            'Origin': 'https://support.broadcom.com',
            'Referer': 'https://support.broadcom.com/group/ecx/productdownloads',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language':
                'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
          },
        ),
      );
      skuSw.stop();

      DiagnosticService.instance.http(
        'Catalog',
        'Response getProductSkuDetails for $subFamily: HTTP ${skuResp.statusCode} (took ${skuSw.elapsedMilliseconds}ms)',
        'Type: ${skuResp.data.runtimeType}, Preview: ${skuResp.data.toString().length > 400 ? '${skuResp.data.toString().substring(0, 400)}...' : skuResp.data}',
      );

      if (skuResp.statusCode == 302 ||
          skuResp.headers.value('location')?.contains('/login') == true) {
        final loc = skuResp.headers.value('location') ?? '';
        _lastSyncError =
            'Broadcom session expired or redirected to login ($loc). Please re-authenticate via In-App Browser.';
        DiagnosticService.instance.warn('Catalog', _lastSyncError!);
        return [];
      }

      if (skuResp.statusCode == 403) {
        _lastSyncError =
            'Access denied by Broadcom (CSRF / security block). Please re-authenticate.';
        DiagnosticService.instance.error('Catalog', _lastSyncError!);
        return [];
      }

      if (skuResp.statusCode != 200 || skuResp.data == null) {
        _lastSyncError = 'Broadcom returned HTTP ${skuResp.statusCode}.';
        DiagnosticService.instance.warn('Catalog', _lastSyncError!);
        return [];
      }

      Map<String, dynamic>? skuData = parseJsonMap(skuResp.data);
      if (skuData == null) {
        DiagnosticService.instance.warn(
          'Catalog',
          'Empty or non-JSON SKU response for $subFamily, bootstrapping portal session...',
        );
        try {
          final pageResp = await _dio.get(
            'https://support.broadcom.com/group/ecx/productdownloads?subfamily=${Uri.encodeComponent(subFamily)}&freeDownloads=true',
            options: Options(
              headers: {
                'Cookie': cookieHeader,
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              },
            ),
          );
          final match = RegExp(r'''Liferay\.authToken\s*=\s*['"]([^'"]+)['"]''').firstMatch(pageResp.data.toString());
          if (match != null) {
            currentCsrf = match.group(1)!;
            DiagnosticService.instance.info('Catalog', 'Extracted fresh dynamic Liferay.authToken: $currentCsrf');
          }
          final retryResp = await _dio.post(
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
                'x-csrf-token': currentCsrf,
                'Origin': 'https://support.broadcom.com',
                'Referer': 'https://support.broadcom.com/group/ecx/productdownloads',
                'Accept': 'application/json, text/plain, */*',
              },
            ),
          );
          skuData = parseJsonMap(retryResp.data);
        } catch (e) {
          DiagnosticService.instance.warn('Catalog', 'Portal bootstrap retry failed: $e');
        }
      }

      if (skuData == null) {
        final preview = skuResp.data.toString();
        _lastSyncError = 'Broadcom returned non-JSON response body: ${preview.length > 150 ? '${preview.substring(0, 150)}...' : preview}';
        DiagnosticService.instance.error(
          'Catalog',
          'Non-JSON response for $subFamily',
          _lastSyncError!,
        );
        return [];
      }

      if (skuData['success'] != true) {
        final errorMsg = skuData['message']?.toString() ??
            skuData['errors']?.toString() ??
            skuData['error']?.toString() ??
            'Broadcom returned success=false (data: $skuData)';
        _lastSyncError = errorMsg;
        DiagnosticService.instance.error(
          'Catalog',
          'Broadcom returned success!=true for $subFamily',
          errorMsg,
        );
        return [];
      }

      final content =
          skuData['data']?['productDetails']?['content'] as List?;
      if (content == null || content.isEmpty) {
        DiagnosticService.instance.warn(
          'Catalog',
          'No productDetails content returned for $subFamily',
        );
        return [];
      }

      final List<_ReleaseFetchTarget> targets = [];
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
          targets.add(_ReleaseFetchTarget(
            displayGroup: displayGroup,
            releaseVer: releaseVer,
            servicePk: servicePk,
          ));
        }
      }

      DiagnosticService.instance.info(
        'Catalog',
        'Found ${content.length} product groups and ${targets.length} releases for $subFamily. Fetching file metadata concurrently...',
      );

      // Concurrent batch fetching with concurrency pool of 6 requests
      const int batchSize = 6;
      for (var i = 0; i < targets.length; i += batchSize) {
        final batch = targets.sublist(i, (i + batchSize).clamp(0, targets.length));
        final batchResults = await Future.wait(batch.map((target) => _fetchReleaseFiles(
          family: family,
          subFamily: subFamily,
          target: target,
          cookieHeader: cookieHeader,
          csrfHeader: currentCsrf,
        )));
        for (final items in batchResults) {
          familyItems.addAll(items);
        }
      }

      familySw.stop();
      DiagnosticService.instance.info(
        'Catalog',
        'Finished $subFamily fetch in ${(familySw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s (${familyItems.length} packages)',
      );
    } catch (e) {
      _lastSyncError ??= 'Error querying Broadcom API: $e';
      DiagnosticService.instance.error(
        'Catalog',
        'Exception during $subFamily catalog fetch',
        e.toString(),
      );
    }

    return familyItems;
  }

  Future<List<VMwareReleaseItem>> _fetchReleaseFiles({
    required VMwareProductFamily family,
    required String subFamily,
    required _ReleaseFetchTarget target,
    required String cookieHeader,
    required String csrfHeader,
  }) async {
    final List<VMwareReleaseItem> items = [];
    final sw = Stopwatch()..start();
    const refererUrl = 'https://support.broadcom.com/group/ecx/productfiles';

    try {
      final filesResp = await _dio.post(
        'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50',
        data: {
          'primaryDownloads': true,
          'otherDownloads': '',
          'searchQuery': '',
          'freeDownloads': true,
          'displayGroup': target.displayGroup,
          'skuCode': '',
          'release': target.releaseVer,
          'genLevel': target.servicePk,
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
      sw.stop();

      if (filesResp.statusCode == 200 && filesResp.data != null) {
        final filesData = parseJsonMap(filesResp.data);
        if (filesData != null && filesData['success'] == true) {
          final packlist =
              filesData['data']?['packlistDetails']?['content'] as List?;
          if (packlist != null) {
            for (final packItem in packlist) {
              if (packItem is! Map) continue;
              final packDesc =
                  packItem['description']?.toString() ?? target.displayGroup;
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
                      ? (target.displayGroup.toLowerCase().contains('linux')
                          ? VMwarePlatform.linux
                          : VMwarePlatform.windows)
                      : VMwarePlatform.macos;
                  resolvedPlatformLabel = resolvedPlatform.name;
                }

                items.add(
                  VMwareReleaseItem(
                    id: '${family.name}-${target.releaseVer}-${resolvedPlatform.name}-${fileItem['buildNumber'] ?? ''}-${fileName.hashCode}',
                    family: family,
                    version: target.releaseVer,
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
                    displayGroup: target.displayGroup,
                    servicePk: target.servicePk,
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

      DiagnosticService.instance.http(
        'Catalog',
        'getDownloadableFiles for ${target.displayGroup} (${target.releaseVer}): HTTP ${filesResp.statusCode} (took ${sw.elapsedMilliseconds}ms, found ${items.length} files)',
      );
    } catch (err) {
      sw.stop();
      DiagnosticService.instance.warn(
        'Catalog',
        'Error fetching files for ${target.displayGroup} (${target.releaseVer}) after ${sw.elapsedMilliseconds}ms: $err',
      );
    }

    return items;
  }
}

class _ReleaseFetchTarget {
  final String displayGroup;
  final String releaseVer;
  final String servicePk;

  const _ReleaseFetchTarget({
    required this.displayGroup,
    required this.releaseVer,
    required this.servicePk,
  });
}
