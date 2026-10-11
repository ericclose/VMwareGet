import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/download_item.dart';
import '../models/vmware_product.dart';
import 'checksum_service.dart';

class DownloadService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 60),
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  final ChecksumService _checksumService = ChecksumService();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, int> _lastSampleBytes = {};
  final Map<String, DateTime> _lastSampleTimes = {};

  Future<String> getDefaultDownloadDirectory() async {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final dir = await getDownloadsDirectory();
        if (dir != null) {
          final vmDir = Directory(p.join(dir.path, 'VMwareGet'));
          if (!await vmDir.exists()) {
            await vmDir.create(recursive: true);
          }
          return vmDir.path;
        }
      }
    } catch (_) {}

    final appDocDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(appDocDir.path, 'VMwareGet'));
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir.path;
  }

  Future<void> startOrResumeDownload({
    required DownloadItem item,
    required void Function(DownloadItem updatedItem) onUpdate,
    String? sessionCookie,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    item.status = DownloadStatus.downloading;
    item.errorMessage = null;
    onUpdate(item);

    final file = File(item.destinationPath);
    int existingBytes = 0;
    if (await file.exists()) {
      existingBytes = await file.length();
    }
    item.downloadedBytes = existingBytes;

    _lastSampleBytes[item.id] = existingBytes;
    _lastSampleTimes[item.id] = DateTime.now();

    final options = Options(
      responseType: ResponseType.stream,
      headers: {
        if (existingBytes > 0) 'Range': 'bytes=$existingBytes-',
        if (sessionCookie != null && sessionCookie.isNotEmpty)
          'Cookie': sessionCookie,
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      },
    );

    try {
      final response = await _dio.get<ResponseBody>(
        item.release.officialDownloadUrl,
        options: options,
        cancelToken: cancelToken,
      );

      final totalHeader = response.headers.value(Headers.contentLengthHeader);
      int contentLength = totalHeader != null ? int.parse(totalHeader) : 0;
      if (existingBytes > 0 && contentLength > 0) {
        item.totalBytes = existingBytes + contentLength;
      } else if (item.totalBytes <= 0 && contentLength > 0) {
        item.totalBytes = contentLength;
      }

      final sink = file.openWrite(
        mode: existingBytes > 0 ? FileMode.append : FileMode.write,
      );

      final stream = response.data!.stream;
      await for (final chunk in stream) {
        if (cancelToken.isCancelled) {
          await sink.close();
          return;
        }

        sink.add(chunk);
        item.downloadedBytes += chunk.length;

        // Speed calculation every 500ms
        final now = DateTime.now();
        final lastTime = _lastSampleTimes[item.id] ?? now;
        final timeDiffMs = now.difference(lastTime).inMilliseconds;
        if (timeDiffMs >= 500) {
          final lastBytes = _lastSampleBytes[item.id] ?? existingBytes;
          final bytesDiff = item.downloadedBytes - lastBytes;
          item.speedBytesPerSec = (bytesDiff / (timeDiffMs / 1000.0));
          _lastSampleBytes[item.id] = item.downloadedBytes;
          _lastSampleTimes[item.id] = now;
          onUpdate(item);
        }
      }

      await sink.flush();
      await sink.close();

      // Download complete, now perform checksum verification
      item.speedBytesPerSec = 0;
      item.status = DownloadStatus.verifying;
      item.verificationStatus = VerificationStatus.verifying;
      onUpdate(item);

      await verifyDownloadedFile(item: item, onUpdate: onUpdate);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.message ?? 'Network download failed';
      }
      item.speedBytesPerSec = 0;
      onUpdate(item);
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
      item.speedBytesPerSec = 0;
      onUpdate(item);
    } finally {
      _cancelTokens.remove(item.id);
      _lastSampleBytes.remove(item.id);
      _lastSampleTimes.remove(item.id);
    }
  }

  void pauseDownload(DownloadItem item) {
    if (_cancelTokens.containsKey(item.id)) {
      _cancelTokens[item.id]!.cancel('User paused download');
      item.status = DownloadStatus.paused;
      item.speedBytesPerSec = 0;
    }
  }

  Future<void> verifyDownloadedFile({
    required DownloadItem item,
    required void Function(DownloadItem updatedItem) onUpdate,
  }) async {
    try {
      item.verificationStatus = VerificationStatus.verifying;
      onUpdate(item);

      final result = await _checksumService.verifyFile(
        filePath: item.destinationPath,
        expectedSha256: item.release.sha256,
        expectedMd5: item.release.md5,
      );

      if (result.isFullyVerified) {
        item.status = DownloadStatus.completed;
        item.verificationStatus = VerificationStatus.passed;
        item.completedAt = DateTime.now();
      } else {
        item.status = DownloadStatus.completed;
        item.verificationStatus = VerificationStatus.failedMismatch;
        item.errorMessage =
            'Checksum mismatch: Expected SHA256 [${item.release.sha256.substring(0, 10)}...], Actual [${result.actualSha256.substring(0, 10)}...]';
      }
    } catch (e) {
      item.verificationStatus = VerificationStatus.failedMismatch;
      item.errorMessage = 'Verification error: $e';
    }
    onUpdate(item);
  }

  Future<void> openContainingFolder(String filePath) async {
    final file = File(filePath);
    final directoryPath = file.parent.path;
    final uri = Uri.directory(directoryPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directoryPath]);
      }
    }
  }

  Future<void> openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
    }
  }
}
