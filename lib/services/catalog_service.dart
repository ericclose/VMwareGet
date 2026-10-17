import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/vmware_product.dart';
import 'auth_service.dart';
import 'diagnostic_service.dart';
import 'download_service.dart';

class CatalogService {
  List<VMwareReleaseItem> _releases = [];
  String? _lastSyncError;

  CatalogService({dynamic dio});

  List<VMwareReleaseItem> getAllReleases() => List.unmodifiable(_releases);
  String? get lastSyncError => _lastSyncError;

  List<VMwareReleaseItem> getReleasesForFamily(VMwareProductFamily family) {
    return _releases.where((r) => r.family == family).toList();
  }

  void setReleases(List<VMwareReleaseItem> items) {
    _releases = List.from(items);
  }

  /// Ingests full batch catalog results collected directly via browser context fetch.
  Future<int> ingestBrowserBatchResults(List<dynamic> rawBatchResults) async {
    final List<VMwareReleaseItem> parsedItems = [];
    for (final entry in rawBatchResults) {
      if (entry is! Map) continue;
      final target = entry['target'] as Map?;
      final filesData = entry['filesData'] as Map?;
      if (target == null || filesData == null) continue;

      final subFamily =
          target['subFamily']?.toString() ?? 'VMware Workstation Pro';
      final family = subFamily.contains('Fusion')
          ? VMwareProductFamily.fusion
          : VMwareProductFamily.workstationPro;
      final displayGroup = target['displayGroup']?.toString() ?? '';
      final releaseVer = target['release']?.toString() ?? '';
      final servicePk = target['servicePk']?.toString() ?? '';

      final packlist =
          filesData['data']?['packlistDetails']?['content'] as List?;
      if (packlist == null) continue;

      for (final packItem in packlist) {
        if (packItem is! Map) continue;
        final packDesc = packItem['description']?.toString() ?? displayGroup;
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
            resolvedPlatform = family == VMwareProductFamily.workstationPro
                ? (displayGroup.toLowerCase().contains('linux')
                    ? VMwarePlatform.linux
                    : VMwarePlatform.windows)
                : VMwarePlatform.macos;
            resolvedPlatformLabel = resolvedPlatform.name;
          }

          parsedItems.add(
            VMwareReleaseItem(
              id: '${family.name}-$releaseVer-${resolvedPlatform.name}-${fileItem['buildNumber'] ?? ''}-${fileName.hashCode}',
              family: family,
              version: releaseVer,
              buildNumber: fileItem['buildNumber']?.toString() ?? '',
              platform: resolvedPlatform,
              platformLabel: resolvedPlatformLabel,
              fileName: fileName,
              fileSize: sizeFormatted,
              fileSizeBytes: sizeBytes,
              releaseDate: fileItem['gaDate']?.toString() ?? '',
              lastUpdated: fileItem['fileLastUpdatedDate']?.toString() ?? '',
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
              directDownloadUrl: fileItem['directDownloadUrl']?.toString(),
            ),
          );
        }
      }
    }

    if (parsedItems.isNotEmpty) {
      _releases = parsedItems;
      _lastSyncError = null;
      await _saveCatalogToCache();
      DiagnosticService.instance.info(
        'Catalog',
        'Successfully ingested ${parsedItems.length} software releases directly from in-browser fetch batch.',
      );
    }
    return parsedItems.length;
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

  /// Synchronizes real-time catalog directly in the genuine browser runtime, completely bypassing Cloudflare WAF.
  Future<bool> syncOnlineCatalog(
    AuthSession? session, {
    BuildContext? context,
    void Function(String message)? onStatusUpdate,
  }) async {
    final totalSw = Stopwatch()..start();
    _lastSyncError = null;

    DiagnosticService.instance.info(
      'Catalog',
      'Starting silent in-browser catalog sync (0% Cloudflare block)...',
    );

    try {
      final updatedCount = await AuthService().syncCatalogInBrowser(
        context: context,
        onStatusUpdate: onStatusUpdate,
        silent: true,
      );

      totalSw.stop();

      if (updatedCount > 0) {
        _lastSyncError = null;
        DiagnosticService.instance.info(
          'Catalog',
          'Catalog sync completed in ${(totalSw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s! Ingested $updatedCount releases.',
        );
        return true;
      }
    } on BroadcomAuthExpiredException {
      _lastSyncError = 'Broadcom session expired. Please re-login.';
      rethrow;
    } catch (e) {
      DiagnosticService.instance.warn('Catalog', 'Browser sync notice: $e');
      _lastSyncError = e.toString();
    }

    if (_releases.isNotEmpty) {
      DiagnosticService.instance.info(
        'Catalog',
        'Retained ${_releases.length} local release packages.',
      );
      return true;
    }

    _lastSyncError ??= 'Unable to synchronize catalog online.';
    return false;
  }
}
