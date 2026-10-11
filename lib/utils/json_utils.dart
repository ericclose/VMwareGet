import 'dart:convert';

/// Safely parses dynamic or string payload into a `Map<String, dynamic>`.
/// Handles Dio returning `String` when Content-Type is non-standard.
Map<String, dynamic>? parseJsonMap(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((k, v) => MapEntry(k.toString(), v));
  }
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
