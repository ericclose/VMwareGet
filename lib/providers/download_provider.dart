import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/download_item.dart';
import '../models/vmware_product.dart';
import '../services/diagnostic_service.dart';
import '../services/download_service.dart';
import '../utils/constants.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final Map<String, DownloadItem> _items = {};
  String? _customDownloadDir;
  bool _isDownloadDirConfirmed = false;
  String _defaultSystemDownloadDir = '';
  int _downloadThreads = AppConstants.defaultDownloadThreads;
  DateTime _lastProgressPersistTime = DateTime.now();
  late final Future<void> initFuture;

  DownloadProvider() {
    initFuture = _initDirectory();
  }

  List<DownloadItem> get allDownloads => _items.values.toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<DownloadItem> get activeDownloads => _items.values
      .where((item) =>
          item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.verifying)
      .toList();

  int get activeCount => activeDownloads.length;

  int get completedCount => _items.values
      .where((item) => item.status == DownloadStatus.completed)
      .length;

  String? get downloadDirectory => _customDownloadDir;
  bool get isDownloadDirConfirmed => _isDownloadDirConfirmed;
  String get defaultSystemDownloadDir => _defaultSystemDownloadDir;
  int get downloadThreads => _downloadThreads;

  Future<void> _initDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultSystemDownloadDir =
        await _downloadService.getDefaultDownloadDirectory();
    final savedDir = prefs.getString(AppConstants.storageKeyDownloadDir);
    if (savedDir != null &&
        savedDir.isNotEmpty &&
        !savedDir.contains('/Library/Containers/')) {
      _customDownloadDir = savedDir;
      _isDownloadDirConfirmed = true;
    } else {
      _customDownloadDir = _defaultSystemDownloadDir;
      _isDownloadDirConfirmed =
          prefs.getBool('vmwareget_download_dir_confirmed') ?? false;
      if (savedDir != null && savedDir.contains('/Library/Containers/')) {
        await prefs.setString(
            AppConstants.storageKeyDownloadDir, _defaultSystemDownloadDir);
      }
    }
    _downloadThreads = prefs.getInt(AppConstants.storageKeyDownloadThreads) ??
        AppConstants.defaultDownloadThreads;

    // Restore persisted download history
    final historyJson = prefs.getString(AppConstants.storageKeyDownloadHistory);
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyJson);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              final item = DownloadItem.fromJson(raw);
              _items[item.id] = item;
            }
          }
          DiagnosticService.instance.info(
            'Download',
            'Restored ${_items.length} download records from persistent storage',
          );
        }
      } catch (e) {
        DiagnosticService.instance.warn(
          'Download',
          'Failed to restore download records: $e',
        );
      }
    }

    notifyListeners();
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.values.map((item) => item.toJson()).toList();
      await prefs.setString(
        AppConstants.storageKeyDownloadHistory,
        jsonEncode(list),
      );
    } catch (e) {
      DiagnosticService.instance.warn(
        'Download',
        'Failed to persist download records: $e',
      );
    }
  }

  void _onDownloadUpdate(DownloadItem updated) {
    _items[updated.id] = updated;
    notifyListeners();
    final now = DateTime.now();
    if (updated.status == DownloadStatus.completed ||
        updated.status == DownloadStatus.failed ||
        updated.status == DownloadStatus.paused ||
        now.difference(_lastProgressPersistTime).inSeconds >= 5) {
      _lastProgressPersistTime = now;
      _persistHistory();
    }
  }

  Future<void> setDownloadThreads(int threads) async {
    final clamped = threads.clamp(
      AppConstants.minDownloadThreads,
      AppConstants.maxDownloadThreads,
    );
    _downloadThreads = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.storageKeyDownloadThreads, clamped);
    notifyListeners();
  }

  Future<void> setDownloadDirectory(String directoryPath) async {
    _customDownloadDir = directoryPath;
    _isDownloadDirConfirmed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.storageKeyDownloadDir, directoryPath);
    await prefs.setBool('vmwareget_download_dir_confirmed', true);
    notifyListeners();
  }

  Future<void> confirmDownloadDirectory(String directoryPath) async {
    await setDownloadDirectory(directoryPath);
  }

  Future<void> resetToDefaultDownloadDirectory() async {
    _customDownloadDir = _defaultSystemDownloadDir;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageKeyDownloadDir);
    notifyListeners();
  }

  Future<bool> openDownloadDirectory() async {
    final dir = _customDownloadDir ?? _defaultSystemDownloadDir;
    if (dir.isNotEmpty) {
      return await DownloadService.openDirectory(dir);
    }
    return false;
  }

  DownloadItem? getItemForRelease(String releaseId) {
    return _items[releaseId];
  }

  Future<String> resolveDownloadUrl({
    required VMwareReleaseItem release,
    AuthSession? session,
  }) async {
    final existing = _items[release.id];
    if (existing?.directDownloadUrl != null &&
        existing!.directDownloadUrl!.isNotEmpty) {
      return existing.directDownloadUrl!;
    }

    if (release.directDownloadUrl != null &&
        release.directDownloadUrl!.isNotEmpty) {
      if (existing != null) {
        existing.directDownloadUrl = release.directDownloadUrl;
        _persistHistory();
      }
      return release.directDownloadUrl!;
    }

    if (release.filePath != null) {
      if (session == null) {
        throw const BroadcomAuthExpiredException(
          'Please log in with Broadcom account to generate direct link.',
        );
      }
      final authorized = await _downloadService.generateAuthorizedDownloadUrl(
        release: release,
        session: session,
      );
      if (authorized != null && authorized.isNotEmpty) {
        if (existing != null) {
          existing.directDownloadUrl = authorized;
          _persistHistory();
        }
        return authorized;
      }
    }

    // Only return officialDownloadUrl if it is an actual direct file link (not portal landing page)
    if (release.officialDownloadUrl.isNotEmpty &&
        !release.officialDownloadUrl.contains('support.broadcom.com/group/ecx')) {
      return release.officialDownloadUrl;
    }

    throw const BroadcomAuthExpiredException(
      'Direct download link expired or unavailable. Please re-login or sync catalog.',
    );
  }

  Future<void> startDownload({
    required VMwareReleaseItem release,
    AuthSession? session,
    String? sessionCookie,
    VoidCallback? onAuthExpired,
  }) async {
    if (release.filePath != null && session == null) {
      onAuthExpired?.call();
      return;
    }

    final targetDir = _customDownloadDir ??
        await _downloadService.getDefaultDownloadDirectory();
    final destPath = p.join(targetDir, release.fileName);

    final item = DownloadItem(
      id: release.id,
      release: release,
      destinationPath: destPath,
      totalBytes: release.fileSizeBytes,
      startedAt: DateTime.now(),
    );

    _items[item.id] = item;
    notifyListeners();
    await _persistHistory();

    _downloadService.startOrResumeDownload(
      item: item,
      session: session,
      threads: _downloadThreads,
      onUpdate: (updated) {
        _onDownloadUpdate(updated);
        if (updated.status == DownloadStatus.failed &&
            (updated.errorMessage?.toLowerCase().contains('expired') == true ||
                updated.errorMessage?.toLowerCase().contains('re-login') == true)) {
          onAuthExpired?.call();
        }
      },
    );
  }

  void pauseDownload(String id) {
    final item = _items[id];
    if (item != null) {
      _downloadService.pauseDownload(item);
      _persistHistory();
      notifyListeners();
    }
  }

  void resumeDownload({
    required String id,
    AuthSession? session,
    String? sessionCookie,
  }) {
    final item = _items[id];
    if (item != null) {
      _downloadService.startOrResumeDownload(
        item: item,
        session: session,
        threads: _downloadThreads,
        onUpdate: _onDownloadUpdate,
      );
    }
  }

  Future<void> redownload({
    required String id,
    AuthSession? session,
    VoidCallback? onAuthExpired,
  }) async {
    final item = _items[id];
    if (item == null) return;

    // 1. Delete destination file and vmeta file
    try {
      final file = File(item.destinationPath);
      if (await file.exists()) {
        await file.delete();
      }
      final metaFile = File('${item.destinationPath}.vmeta');
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
    } catch (_) {}

    // 2. Reset item status
    item.downloadedBytes = 0;
    item.speedBytesPerSec = 0;
    item.status = DownloadStatus.downloading;
    item.verificationStatus = VerificationStatus.notStarted;
    item.errorMessage = null;
    item.completedAt = null;
    item.startedAt = DateTime.now();
    item.directDownloadUrl = null;

    notifyListeners();
    await _persistHistory();

    // 3. Initiate clean download
    _downloadService.startOrResumeDownload(
      item: item,
      session: session,
      threads: _downloadThreads,
      onUpdate: (updated) {
        _onDownloadUpdate(updated);
        if (updated.status == DownloadStatus.failed &&
            (updated.errorMessage?.toLowerCase().contains('expired') == true ||
                updated.errorMessage?.toLowerCase().contains('re-login') == true)) {
          onAuthExpired?.call();
        }
      },
    );
  }

  Future<void> reVerifyChecksum(String id) async {
    final item = _items[id];
    if (item != null) {
      final file = File(item.destinationPath);
      if (!await file.exists()) {
        item.verificationStatus = VerificationStatus.failedMismatch;
        item.errorMessage = 'Local file does not exist or has been deleted';
        notifyListeners();
        return;
      }
      item.status = DownloadStatus.verifying;
      item.verificationStatus = VerificationStatus.verifying;
      notifyListeners();
      await _downloadService.verifyDownloadedFile(
        item: item,
        onUpdate: _onDownloadUpdate,
      );
    }
  }

  Future<bool> openContainingFolder(String id) async {
    final item = _items[id];
    if (item != null) {
      final file = File(item.destinationPath);
      if (!await file.exists()) {
        item.errorMessage = 'Local file does not exist or has been deleted';
        notifyListeners();
        final parent = file.parent;
        if (await parent.exists()) {
          await DownloadService.openDirectory(parent.path);
        }
        return false;
      }
      await _downloadService.openContainingFolder(item.destinationPath);
      return true;
    }
    return false;
  }

  Future<bool> openDownloadedFile(String id) async {
    final item = _items[id];
    if (item != null) {
      final file = File(item.destinationPath);
      if (!await file.exists()) {
        item.errorMessage = 'Local file does not exist or has been deleted';
        notifyListeners();
        return false;
      }
      await _downloadService.openFile(item.destinationPath);
      return true;
    }
    return false;
  }

  Future<void> deleteDownload({
    required String id,
    bool deleteLocalFile = false,
  }) async {
    final item = _items[id];
    if (item != null) {
      if (item.status == DownloadStatus.downloading) {
        pauseDownload(id);
      }
      if (deleteLocalFile) {
        try {
          final file = File(item.destinationPath);
          if (await file.exists()) {
            await file.delete();
          }
          final meta = File('${item.destinationPath}.vmeta');
          if (await meta.exists()) {
            await meta.delete();
          }
        } catch (_) {}
      }
      _items.remove(id);
      notifyListeners();
      await _persistHistory();
    }
  }

  Future<void> clearCompletedDownloads() async {
    _items.removeWhere((key, item) => item.status == DownloadStatus.completed);
    notifyListeners();
    await _persistHistory();
  }
}
