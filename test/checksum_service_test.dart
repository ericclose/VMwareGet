import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vmwareget/services/checksum_service.dart';

void main() {
  late ChecksumService checksumService;
  late File tempTestFile;

  setUp(() async {
    checksumService = ChecksumService();
    tempTestFile = File('test/temp_test_payload.bin');
    // Write sample byte sequence
    await tempTestFile.writeAsString('Broadcom VMwareGet Checksum Verification Test 12345');
  });

  tearDown(() async {
    if (await tempTestFile.exists()) {
      await tempTestFile.delete();
    }
  });

  test('Calculates and verifies accurate SHA256 and MD5', () async {
    final bytes = await tempTestFile.readAsBytes();
    final expectedSha256 = sha256.convert(bytes).toString();
    final expectedMd5 = md5.convert(bytes).toString();

    final result = await checksumService.verifyFile(
      filePath: tempTestFile.path,
      expectedSha256: expectedSha256,
      expectedMd5: expectedMd5,
    );

    expect(result.sha256Matches, isTrue);
    expect(result.md5Matches, isTrue);
    expect(result.isFullyVerified, isTrue);
    expect(result.actualSha256, equals(expectedSha256));
    expect(result.actualMd5, equals(expectedMd5));
  });

  test('Detects mismatched checksums correctly', () async {
    final result = await checksumService.verifyFile(
      filePath: tempTestFile.path,
      expectedSha256: '0000000000000000000000000000000000000000000000000000000000000000',
      expectedMd5: '00000000000000000000000000000000',
    );

    expect(result.sha256Matches, isFalse);
    expect(result.md5Matches, isFalse);
    expect(result.isFullyVerified, isFalse);
  });
}
