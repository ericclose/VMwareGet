import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/download_item.dart';
import '../models/vmware_product.dart';
import '../services/download_service.dart';
import '../utils/constants.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final Map<String, DownloadItem> _items = {};
  String? _customDownloadDir;
  bool _isDownloadDirConfirmed = false;
  String _defaultSystemDownloadDir = '';

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

  String? get downloadDirectory => _customDownloadDir;
  bool get isDownloadDirConfirmed => _isDownloadDirConfirmed;
  String get defaultSystemDownloadDir => _defaultSystemDownloadDir;

  Future<void> _initDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultSystemDownloadDir =
        await _downloadService.getDefaultDownloadDirectory();
    final savedDir = prefs.getString(AppConstants.storageKeyDownloadDir);
    if (savedDir != null && savedDir.isNotEmpty) {
      _customDownloadDir = savedDir;
      _isDownloadDirConfirmed = true;
    } else {
      _customDownloadDir = _defaultSystemDownloadDir;
      _isDownloadDirConfirmed =
          prefs.getBool('vmwareget_download_dir_confirmed') ?? false;
    }
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

  Future<void> openDownloadDirectory() async {
    final dir = _customDownloadDir ?? _defaultSystemDownloadDir;
    if (dir.isNotEmpty) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      try {
        if (Platform.isMacOS) {
          await Process.run('open', [dir]);
          return;
        } else if (Platform.isWindows) {
          await Process.run('explorer.exe', [dir]);
          return;
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [dir]);
          return;
        }
      } catch (_) {}
    }
  }

  DownloadItem? getItemForRelease(String releaseId) {
    return _items[releaseId];
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

    _downloadService.startOrResumeDownload(
      item: item,
      session: session,
      onUpdate: (updated) {
        _items[updated.id] = updated;
        notifyListeners();
      },
    );
  }

  void pauseDownload(String id) {
    final item = _items[id];
    if (item != null) {
      _downloadService.pauseDownload(item);
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
        onUpdate: (updated) {
          _items[updated.id] = updated;
          notifyListeners();
        },
      );
    }
  }

  Future<void> reVerifyChecksum(String id) async {
    final item = _items[id];
    if (item != null) {
      await _downloadService.verifyDownloadedFile(
        item: item,
        onUpdate: (updated) {
          _items[updated.id] = updated;
          notifyListeners();
        },
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
        } catch (_) {}
      }
      _items.remove(id);
      notifyListeners();
    }
  }
}
