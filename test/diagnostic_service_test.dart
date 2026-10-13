import 'package:flutter_test/flutter_test.dart';
import 'package:vmwareget/services/diagnostic_service.dart';

void main() {
  group('DiagnosticService & Logging Tests', () {
    setUp(() {
      DiagnosticService.instance.enableConsoleLogging = false;
      DiagnosticService.instance.clear();
    });

    tearDown(() {
      DiagnosticService.instance.enableConsoleLogging = true;
    });

    test('Initial log buffer is empty after clear', () {
      expect(DiagnosticService.instance.entries.isEmpty, isTrue);
    });

    test('Logs various levels and formats entries correctly', () {
      DiagnosticService.instance.info('Auth', 'Session initialized', 'User: test@broadcom.user');
      DiagnosticService.instance.http('Network', 'POST /getProductSkuDetails', 'HTTP 200 OK');
      DiagnosticService.instance.warn('Storage', 'Low disk space warning');
      DiagnosticService.instance.error('Download', 'Connection timed out', 'Err code: 504');

      final entries = DiagnosticService.instance.entries;
      expect(entries.length, equals(4));

      expect(entries[0].level, equals(DiagnosticLogLevel.info));
      expect(entries[0].levelLabel, equals('INFO'));
      expect(entries[0].tag, equals('Auth'));
      expect(entries[0].message, equals('Session initialized'));
      expect(entries[0].details, equals('User: test@broadcom.user'));
      expect(entries[0].format().contains('[INFO] [Auth] Session initialized'), isTrue);
      expect(entries[0].format().contains('↳ Details: User: test@broadcom.user'), isTrue);

      expect(entries[1].level, equals(DiagnosticLogLevel.http));
      expect(entries[1].levelLabel, equals('HTTP'));

      expect(entries[2].level, equals(DiagnosticLogLevel.warning));
      expect(entries[2].levelLabel, equals('WARN'));

      expect(entries[3].level, equals(DiagnosticLogLevel.error));
      expect(entries[3].levelLabel, equals('ERROR'));
    });

    test('Caps entry buffer at maxEntries (500) in ring-buffer style', () {
      for (int i = 0; i < 600; i++) {
        DiagnosticService.instance.info('Test', 'Message $i');
      }

      final entries = DiagnosticService.instance.entries;
      expect(entries.length, equals(DiagnosticService.maxEntries));
      // First 100 messages were discarded; oldest entry in buffer should be Message 100
      expect(entries.first.message, equals('Message 100'));
      expect(entries.last.message, equals('Message 599'));
    });

    test('Notifies listeners on new log entries', () {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }

      DiagnosticService.instance.addListener(listener);
      DiagnosticService.instance.info('Test', 'Ping 1');
      DiagnosticService.instance.info('Test', 'Ping 2');
      DiagnosticService.instance.removeListener(listener);

      expect(notifyCount, equals(2));
    });

    test('exportFormattedLogs formats header, entries and footer correctly', () {
      DiagnosticService.instance.info('Test', 'Export check message');
      final report = DiagnosticService.instance.exportFormattedLogs();
      expect(report.contains('=== VMwareGet Technical Diagnostic Report ==='), isTrue);
      expect(report.contains('[INFO] [Test] Export check message'), isTrue);
      expect(report.contains('=== End of Diagnostic Report ==='), isTrue);
    });

    test('maskCookie obfuscates sensitive cookie values while preserving length and key hints', () {
      expect(DiagnosticService.maskCookie('JSESSIONID', 'short'), equals('***'));
      final masked = DiagnosticService.maskCookie('JSESSIONID', 'ABC123456789XYZ');
      expect(masked.startsWith('ABC...'), isTrue);
      expect(masked.contains('XYZ'), isTrue);
      expect(masked.contains('len:15'), isTrue);
    });
  });
}
