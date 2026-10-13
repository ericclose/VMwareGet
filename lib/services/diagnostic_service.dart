import 'package:flutter/foundation.dart';

enum DiagnosticLogLevel {
  info,
  http,
  warning,
  error,
}

class DiagnosticLogEntry {
  final DateTime timestamp;
  final DiagnosticLogLevel level;
  final String tag;
  final String message;
  final String? details;

  const DiagnosticLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.details,
  });

  String get levelLabel {
    switch (level) {
      case DiagnosticLogLevel.info:
        return 'INFO';
      case DiagnosticLogLevel.http:
        return 'HTTP';
      case DiagnosticLogLevel.warning:
        return 'WARN';
      case DiagnosticLogLevel.error:
        return 'ERROR';
    }
  }

  String format() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
    final buffer = StringBuffer('[$timeStr] [$levelLabel] [$tag] $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\n  ↳ Details: $details');
    }
    return buffer.toString();
  }
}

class DiagnosticService extends ChangeNotifier {
  static final DiagnosticService instance = DiagnosticService._internal();

  DiagnosticService._internal();

  final List<DiagnosticLogEntry> _entries = [];
  static const int maxEntries = 500;
  bool enableConsoleLogging = true;

  List<DiagnosticLogEntry> get entries => List.unmodifiable(_entries);

  void log({
    required DiagnosticLogLevel level,
    required String tag,
    required String message,
    String? details,
  }) {
    final entry = DiagnosticLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      details: details,
    );
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    if (enableConsoleLogging) {
      debugPrint(entry.format());
    }
    notifyListeners();
  }

  void info(String tag, String message, [String? details]) {
    log(level: DiagnosticLogLevel.info, tag: tag, message: message, details: details);
  }

  void http(String tag, String message, [String? details]) {
    log(level: DiagnosticLogLevel.http, tag: tag, message: message, details: details);
  }

  void warn(String tag, String message, [String? details]) {
    log(level: DiagnosticLogLevel.warning, tag: tag, message: message, details: details);
  }

  void error(String tag, String message, [String? details]) {
    log(level: DiagnosticLogLevel.error, tag: tag, message: message, details: details);
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportFormattedLogs() {
    if (_entries.isEmpty) {
      return 'No diagnostic logs recorded yet.';
    }
    final buffer = StringBuffer();
    buffer.writeln('=== VMwareGet Technical Diagnostic Report ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Platform: macOS / Flutter (pinned v3.47.7)');
    buffer.writeln('Total Log Entries: ${_entries.length}');
    buffer.writeln('----------------------------------------------------');
    for (final e in _entries) {
      buffer.writeln(e.format());
    }
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('=== End of Diagnostic Report ===');
    return buffer.toString();
  }

  /// Masks sensitive cookie values while preserving key name and partial hash
  static String maskCookie(String name, String value) {
    if (value.length <= 6) return '***';
    return '${value.substring(0, 3)}...${value.substring(value.length - 3)} (len:${value.length})';
  }
}
