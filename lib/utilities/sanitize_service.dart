import "dart:convert";

class SanitizeService {
  static const _maxStringLength = 200;

  static dynamic sanitize(dynamic input) {
    if (input is String) {
      final bytes = utf8.encode(input).length;
      if (input.length > _maxStringLength) {
        return "Large data, $bytes bytes";
      }
      return input;
    }
    if (input is Map<String, dynamic>) {
      return input.map((key, value) => MapEntry(key, sanitize(value)));
    }
    if (input is List) {
      return input.map(sanitize).toList();
    }
    return input; // numbers, booleans, null, etc.
  }

  static String prettyJson(Map<String, dynamic> json) {
    final sanitized = sanitize(json) as Map<String, dynamic>;

    return const JsonEncoder.withIndent("  ").convert(sanitized);
  }
}
