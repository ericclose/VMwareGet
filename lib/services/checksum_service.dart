import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class ChecksumVerificationResult {
  final bool sha256Matches;
  final bool md5Matches;
  final String actualSha256;
  final String actualMd5;
  final String expectedSha256;
  final String expectedMd5;

  ChecksumVerificationResult({
    required this.sha256Matches,
    required this.md5Matches,
    required this.actualSha256,
    required this.actualMd5,
    required this.expectedSha256,
    required this.expectedMd5,
  });

  bool get isFullyVerified => sha256Matches && md5Matches;
}

class ChecksumService {
  /// Computes both SHA256 and MD5 in a single stream pass to maximize I/O efficiency on large installers
  Future<ChecksumVerificationResult> verifyFile({
    required String filePath,
    required String expectedSha256,
    required String expectedMd5,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }

    final totalBytes = await file.length();
    int processedBytes = 0;

    Digest? calculatedSha256;
    Digest? calculatedMd5;

    final shaOutputSink = ChunkedConversionSink<Digest>.withCallback((digests) {
      if (digests.isNotEmpty) {
        calculatedSha256 = digests.first;
      }
    });
    final md5OutputSink = ChunkedConversionSink<Digest>.withCallback((digests) {
      if (digests.isNotEmpty) {
        calculatedMd5 = digests.first;
      }
    });

    final shaChunkSink = sha256.startChunkedConversion(shaOutputSink);
    final md5ChunkSink = md5.startChunkedConversion(md5OutputSink);

    final stream = file.openRead();
    await for (final chunk in stream) {
      shaChunkSink.add(chunk);
      md5ChunkSink.add(chunk);
      processedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(processedBytes / totalBytes);
      }
    }

    shaChunkSink.close();
    md5ChunkSink.close();

    final actualSha256Str = calculatedSha256.toString().toLowerCase();
    final actualMd5Str = calculatedMd5.toString().toLowerCase();

    final expSha256Norm = expectedSha256.trim().toLowerCase();
    final expMd5Norm = expectedMd5.trim().toLowerCase();

    final shaMatches =
        expSha256Norm.isEmpty || actualSha256Str == expSha256Norm;
    final md5Matches = expMd5Norm.isEmpty || actualMd5Str == expMd5Norm;

    return ChecksumVerificationResult(
      sha256Matches: shaMatches,
      md5Matches: md5Matches,
      actualSha256: actualSha256Str,
      actualMd5: actualMd5Str,
      expectedSha256: expSha256Norm,
      expectedMd5: expMd5Norm,
    );
  }

  /// Calculates sha256 standalone
  Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Calculates md5 standalone
  Future<String> calculateMd5(String filePath) async {
    final file = File(filePath);
    final stream = file.openRead();
    final digest = await md5.bind(stream).first;
    return digest.toString();
  }
}
