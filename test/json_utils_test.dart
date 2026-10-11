import 'package:flutter_test/flutter_test.dart';
import 'package:vmwareget/utils/json_utils.dart';

void main() {
  group('JsonUtils parseJsonMap Tests', () {
    test('returns map as-is when already a Map', () {
      final input = {'success': true, 'code': 200};
      final result = parseJsonMap(input);
      expect(result, isNotNull);
      expect(result!['success'], isTrue);
      expect(result['code'], equals(200));
    });

    test('decodes JSON String when returned as String from Dio', () {
      const input = '{"success":true,"data":{"productDetails":{"content":[]}}}';
      final result = parseJsonMap(input);
      expect(result, isNotNull);
      expect(result!['success'], isTrue);
      expect(result['data'], isA<Map>());
    });

    test('returns null for non-JSON string or malformed payload', () {
      expect(parseJsonMap('<html><body>Error 500</body></html>'), isNull);
      expect(parseJsonMap('invalid json'), isNull);
      expect(parseJsonMap(null), isNull);
      expect(parseJsonMap(12345), isNull);
    });
  });
}
