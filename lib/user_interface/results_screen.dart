import "dart:convert";
import "package:flutter/material.dart";

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  static const _maxStringLength = 200;

  const ResultsScreen({required this.data, super.key});

  dynamic _sanitize(dynamic input) {
    if (input is String) {
      final bytes = utf8.encode(input).length;
      if (input.length > _maxStringLength) {
        return "Large data, $bytes bytes";
      }
      return input;
    }
    if (input is Map<String, dynamic>) {
      return input.map((key, value) => MapEntry(key, _sanitize(value)));
    }
    if (input is List) {
      return input.map(_sanitize).toList();
    }
    return input; // numbers, booleans, null, etc.
  }

  String _prettyJson(Map<String, dynamic> json) {
    return const JsonEncoder.withIndent("  ").convert(json);
  }

  @override
  Widget build(BuildContext context) {
    final sanitized = _sanitize(data) as Map<String, dynamic>;
    final prettyString = _prettyJson(sanitized);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Column(
        children: [
          if (sanitized["error"] != null && sanitized["error"] == true)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "This would have thrown an error, and we would display this to the user in a real app. ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                prettyString,
                style: const TextStyle(fontFamily: "monospace", fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
