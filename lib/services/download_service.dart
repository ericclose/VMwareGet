import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/auth_session.dart';
import '../models/download_item.dart';
import '../models/vmware_product.dart';
import '../utils/constants.dart';
import '../utils/json_utils.dart';
import 'auth_service.dart';
import 'checksum_service.dart';
import 'diagnostic_service.dart';

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
      if (Platform.isMacOS || Platform.isLinux) {
        String? home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          if (home.contains('/Library/Containers/')) {
            final match = RegExp(r'^(/Users/[^/]+)').firstMatch(home);
            if (match != null) {
              home = match.group(1);
            }
          }
          final userDownloads = Directory(p.join(home!, 'Downloads'));
          if (await userDownloads.exists()) {
            final vmDir = Directory(p.join(userDownloads.path, 'VMwareGet'));
            if (!await vmDir.exists()) {
              await vmDir.create(recursive: true);
            }
            return vmDir.path;
          }
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final winDownloads = Directory(p.join(userProfile, 'Downloads', 'VMwareGet'));
          if (!await winDownloads.exists()) {
            await winDownloads.create(recursive: true);
          }
          return winDownloads.path;
        }
      } else if (Platform.isAndroid) {
        const publicDownload = '/storage/emulated/0/Download';
        final pubDir = Directory(publicDownload);
        if (await pubDir.exists()) {
          final vmDir = Directory(p.join(pubDir.path, 'VMwareGet'));
          if (!await vmDir.exists()) {
            await vmDir.create(recursive: true);
          }
          return vmDir.path;
        }
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final vmDir = Directory(p.join(extDir.path, 'VMwareGet'));
          if (!await vmDir.exists()) {
            await vmDir.create(recursive: true);
          }
          return vmDir.path;
        }
      }

      final dir = await getDownloadsDirectory();
      if (dir != null) {
        String realPath = dir.path;
        try {
          realPath = await dir.resolveSymbolicLinks();
        } catch (_) {}
        if (realPath.contains('/Library/Containers/')) {
          final match = RegExp(r'^(/Users/[^/]+)').firstMatch(realPath);
          if (match != null) {
            realPath = p.join(match.group(1)!, 'Downloads');
          }
        }
        final vmDir = Directory(p.join(realPath, 'VMwareGet'));
        if (!await vmDir.exists()) {
          await vmDir.create(recursive: true);
        }
        return vmDir.path;
      }
    } catch (_) {}

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory(p.join(appDocDir.path, 'VMwareGet'));
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir.path;
    } catch (_) {}

    final tempFallback = Directory(p.join(Directory.systemTemp.path, 'VMwareGet'));
    if (!await tempFallback.exists()) {
      await tempFallback.create(recursive: true);
    }
    return tempFallback.path;
  }

  Future<String?> generateAuthorizedDownloadUrl({
    required VMwareReleaseItem release,
    required AuthSession session,
  }) async {
    if (release.filePath == null || release.displayGroup == null) {
      return null;
    }

    try {
      final cookieHeader = session.cookieJar ?? session.sessionToken;
      String? csrf = session.csrfToken;
      if (csrf == null || csrf.isEmpty) {
        csrf = await AuthService().fetchDynamicCsrfToken(cookieHeader);
      }

      final orderResp = await _dio.post(
        'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/createProductDownloadOrder',
        data: {
          'downloadType': 'HTTP',
          'productName': release.family == VMwareProductFamily.workstationPro
              ? 'VMware Workstation Pro'
              : 'VMware Fusion',
          'releaseDescription': release.releaseDesc ??
              (release.family == VMwareProductFamily.workstationPro
                  ? 'VMware Workstation Pro (For Windows)'
                  : 'VMware Fusion (for Intel-based and Apple silicon Macs)'),
          'skuCode': '',
          'displayGroup': release.displayGroup,
          'release': release.version,
          'genLevel': release.servicePk ?? '',
          'language': 'EN',
          'os': '',
          'eulaId': release.eulaId ?? 17290717,
          'accessToken': false,
          'siteId': '105246',
          'orderedFiles': [
            {
              'filePath': release.filePath,
              'fileSize': release.fileSizeBytes,
            }
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json;charset=UTF-8',
            'Origin': 'https://support.broadcom.com',
            'Referer': 'https://support.broadcom.com/group/ecx/productfiles',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language':
                'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
            'Cookie': cookieHeader,
            'x-csrf-token': csrf ?? '',
          },
        ),
      );

      if (orderResp.statusCode == 200 && orderResp.data != null) {
        final data = parseJsonMap(orderResp.data);
        if (data != null && data['success'] == true) {
          final dlUrl = data['data']?['downloadUrl'] as String?;
          return dlUrl;
        }
      }
    } catch (e) {
      print('Error generating download order: $e');
    }
    return null;
  }

  Future<void> startOrResumeDownload({
    required DownloadItem item,
    required void Function(DownloadItem updatedItem) onUpdate,
    AuthSession? session,
    int threads = AppConstants.defaultDownloadThreads,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    item.status = DownloadStatus.downloading;
    item.errorMessage = null;
    onUpdate(item);

    // 1. Resolve authorized download link
    String downloadUrl = item.release.officialDownloadUrl;
    if (session != null && item.release.filePath != null) {
      final authorizedUrl = await generateAuthorizedDownloadUrl(
        release: item.release,
        session: session,
      );
      if (authorizedUrl != null && authorizedUrl.isNotEmpty) {
        downloadUrl = authorizedUrl;
      }
    }
    item.directDownloadUrl = downloadUrl;

    try {
      // 2. Check Range capability & remote file size via probe
      bool supportsRange = false;
      int remoteTotalBytes = item.release.fileSizeBytes;

      try {
        final probeResp = await _dio.get<ResponseBody>(
          downloadUrl,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Range': 'bytes=0-0',
              'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
            },
            validateStatus: (status) => status != null && status < 400,
          ),
          cancelToken: cancelToken,
        );

        if (probeResp.statusCode == 206) {
          supportsRange = true;
          final cr = probeResp.headers.value('content-range');
          if (cr != null && cr.contains('/')) {
            final totalStr = cr.split('/').last.trim();
            final parsed = int.tryParse(totalStr);
            if (parsed != null && parsed > 0) {
              remoteTotalBytes = parsed;
            }
          }
        }
        await probeResp.data?.stream.drain();
      } catch (e) {
        DiagnosticService.instance.log(
          level: DiagnosticLogLevel.warning,
          tag: 'Download',
          message: 'Range probe notice for ${item.release.fileName}: $e',
        );
      }

      if (remoteTotalBytes > 0) {
        item.totalBytes = remoteTotalBytes;
      }

      final effectiveThreads = threads.clamp(
        AppConstants.minDownloadThreads,
        AppConstants.maxDownloadThreads,
      );

      // If server supports Range, file > 2MB, and threads > 1
      if (supportsRange && remoteTotalBytes > 2 * 1024 * 1024 && effectiveThreads > 1) {
        await _downloadMultiThreaded(
          item: item,
          downloadUrl: downloadUrl,
          totalBytes: remoteTotalBytes,
          threads: effectiveThreads,
          cancelToken: cancelToken,
          onUpdate: onUpdate,
        );
      } else {
        await _downloadSingleStream(
          item: item,
          downloadUrl: downloadUrl,
          cancelToken: cancelToken,
          onUpdate: onUpdate,
        );
      }
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

  Future<void> _downloadMultiThreaded({
    required DownloadItem item,
    required String downloadUrl,
    required int totalBytes,
    required int threads,
    required CancelToken cancelToken,
    required void Function(DownloadItem updatedItem) onUpdate,
  }) async {
    final file = File(item.destinationPath);
    final metaFile = File('${item.destinationPath}.vmeta');

    int workerCount = threads;
    const minChunkSize = 512 * 1024; // 512KB min chunk
    if (totalBytes < workerCount * minChunkSize) {
      workerCount = (totalBytes / minChunkSize).floor().clamp(1, workerCount);
    }

    List<Map<String, int>> chunks = [];
    bool loadedFromMeta = false;

    if (await metaFile.exists() && await file.exists()) {
      try {
        final metaContent = await metaFile.readAsString();
        final metaJson = jsonDecode(metaContent);
        if (metaJson is Map &&
            metaJson['totalBytes'] == totalBytes &&
            metaJson['chunks'] is List) {
          final list = metaJson['chunks'] as List;
          chunks = list.map((c) => {
            'start': (c['start'] as num).toInt(),
            'end': (c['end'] as num).toInt(),
            'current': (c['current'] as num).toInt(),
          }).toList();
          loadedFromMeta = true;
        }
      } catch (_) {}
    }

    if (!loadedFromMeta || chunks.isEmpty) {
      chunks = [];
      final chunkSize = (totalBytes / workerCount).ceil();
      for (int i = 0; i < workerCount; i++) {
        final start = i * chunkSize;
        final end = (i == workerCount - 1) ? totalBytes - 1 : ((i + 1) * chunkSize - 1);
        chunks.add({
          'start': start,
          'end': end,
          'current': start,
        });
      }
    }

    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final raf = await file.open(mode: FileMode.append);
    try {
      final currentLength = await raf.length();
      if (currentLength < totalBytes) {
        await raf.truncate(totalBytes);
      }
    } catch (_) {}

    int initialDownloaded = 0;
    for (final c in chunks) {
      final done = (c['current']! - c['start']!).clamp(0, c['end']! - c['start']! + 1);
      initialDownloaded += done;
    }
    item.downloadedBytes = initialDownloaded;
    _lastSampleBytes[item.id] = initialDownloaded;
    _lastSampleTimes[item.id] = DateTime.now();

    DiagnosticService.instance.log(
      level: DiagnosticLogLevel.info,
      tag: 'Download',
      message:
          'Executing native multi-threaded download: ${chunks.length} Range workers for ${item.release.fileName} (Total: $totalBytes bytes, Resumed: $initialDownloaded bytes)',
    );

    Future<void> writeQueue = Future.value();
    Future<void> writeAt(int position, List<int> data) {
      final completer = Completer<void>();
      writeQueue = writeQueue.then((_) async {
        try {
          await raf.setPosition(position);
          await raf.writeFrom(data);
        } finally {
          completer.complete();
        }
      });
      return completer.future;
    }

    Future<void> saveMetadata() async {
      try {
        final metaData = {
          'totalBytes': totalBytes,
          'chunks': chunks,
        };
        await metaFile.writeAsString(jsonEncode(metaData), flush: true);
      } catch (_) {}
    }

    DateTime lastMetaSave = DateTime.now();

    Future<void> runWorker(Map<String, int> chunk) async {
      if (chunk['current']! > chunk['end']!) return;
      int retries = 0;

      while (chunk['current']! <= chunk['end']! && !cancelToken.isCancelled) {
        final rangeStart = chunk['current']!;
        final rangeEnd = chunk['end']!;

        try {
          final resp = await _dio.get<ResponseBody>(
            downloadUrl,
            options: Options(
              responseType: ResponseType.stream,
              headers: {
                'Range': 'bytes=$rangeStart-$rangeEnd',
                'User-Agent':
                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
              },
            ),
            cancelToken: cancelToken,
          );

          final stream = resp.data!.stream;
          await for (final buffer in stream) {
            if (cancelToken.isCancelled) break;
            final writePos = chunk['current']!;
            chunk['current'] = writePos + buffer.length;
            item.downloadedBytes += buffer.length;

            await writeAt(writePos, buffer);

            final now = DateTime.now();
            final lastTime = _lastSampleTimes[item.id] ?? now;
            final diffMs = now.difference(lastTime).inMilliseconds;
            if (diffMs >= 500) {
              final lastB = _lastSampleBytes[item.id] ?? initialDownloaded;
              final diffB = item.downloadedBytes - lastB;
              item.speedBytesPerSec = (diffB / (diffMs / 1000.0));
              _lastSampleBytes[item.id] = item.downloadedBytes;
              _lastSampleTimes[item.id] = now;
              onUpdate(item);
            }

            if (now.difference(lastMetaSave).inSeconds >= 2) {
              lastMetaSave = now;
              await saveMetadata();
            }
          }
          break;
        } catch (e) {
          if (cancelToken.isCancelled) break;
          retries++;
          if (retries > 3) rethrow;
          await Future.delayed(Duration(milliseconds: 300 * retries));
        }
      }
    }

    try {
      await Future.wait(chunks.map((c) => runWorker(c)));
      await writeQueue;
      await raf.flush();
      await raf.close();

      if (cancelToken.isCancelled) {
        await saveMetadata();
        item.status = DownloadStatus.paused;
        item.speedBytesPerSec = 0;
        onUpdate(item);
        return;
      }

      final allFinished = chunks.every((c) => c['current']! > c['end']!);
      if (allFinished) {
        if (await metaFile.exists()) {
          await metaFile.delete();
        }
        item.speedBytesPerSec = 0;
        item.status = DownloadStatus.verifying;
        item.verificationStatus = VerificationStatus.verifying;
        onUpdate(item);

        await verifyDownloadedFile(item: item, onUpdate: onUpdate);
      }
    } catch (e) {
      try {
        await saveMetadata();
        await raf.flush();
        await raf.close();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _downloadSingleStream({
    required DownloadItem item,
    required String downloadUrl,
    required CancelToken cancelToken,
    required void Function(DownloadItem updatedItem) onUpdate,
  }) async {
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
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
      },
    );

    final response = await _dio.get<ResponseBody>(
      downloadUrl,
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

    item.speedBytesPerSec = 0;
    item.status = DownloadStatus.verifying;
    item.verificationStatus = VerificationStatus.verifying;
    onUpdate(item);

    await verifyDownloadedFile(item: item, onUpdate: onUpdate);
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
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
        return;
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
        return;
      } else if (Platform.isLinux) {
        final directoryPath = File(filePath).parent.path;
        await Process.run('xdg-open', [directoryPath]);
        return;
      } else if (Platform.isAndroid) {
        const channel = MethodChannel('io.github.vmwareget/platform');
        final directoryPath = File(filePath).parent.path;
        await channel.invokeMethod('openDirectory', {'path': directoryPath});
        return;
      }
    } catch (_) {}

    final file = File(filePath);
    final directoryPath = file.parent.path;
    final uri = Uri.directory(directoryPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openFile(String filePath) async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('io.github.vmwareget/platform');
        await channel.invokeMethod('openFile', {'path': filePath});
        return;
      } catch (_) {}
    }
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
