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

  DownloadProvider() {
    _initDirectory();
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

    if (session != null && release.filePath != null) {
      try {
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
      } catch (e) {
        DiagnosticService.instance.warn(
          'Download',
          'Failed to resolve direct download link: $e',
        );
      }
    }

    return release.officialDownloadUrl;
  }

  Future<void> startDownload({
    required VMwareReleaseItem release,
    AuthSession? session,
    String? sessionCookie,
  }) async {
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
      onUpdate: _onDownloadUpdate,
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

  Future<void> reVerifyChecksum(String id) async {
    final item = _items[id];
    if (item != null) {
      await _downloadService.verifyDownloadedFile(
        item: item,
        onUpdate: _onDownloadUpdate,
      );
    }
  }

  Future<void> openContainingFolder(String id) async {
    final item = _items[id];
    if (item != null) {
      await _downloadService.openContainingFolder(item.destinationPath);
    }
  }

  Future<void> openDownloadedFile(String id) async {
    final item = _items[id];
    if (item != null) {
      await _downloadService.openFile(item.destinationPath);
    }
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
