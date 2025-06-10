import "dart:convert";
import "package:flutter/material.dart";

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ResultsScreen({required this.data, super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isBase64(String str) {
    final base64Regex = RegExp(
      r"^([A-Za-z0-9+/]{4})*"
      r"([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\$",
    );
    return base64Regex.hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: widget.data.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          Widget valueWidget;

          if (value is String && _isBase64(value)) {
            try {
              final bytes = base64Decode(value);
              valueWidget = Image.memory(bytes);
            } catch (_) {
              valueWidget = const Text("Invalid image data");
            }
          } else if (value is String && value.length > 200) {
            final size = utf8.encode(value).length;
            valueWidget = Text("Large data, $size bytes");
          } else if (value is List || value is Map) {
            final pretty = const JsonEncoder.withIndent("  ").convert(value);
            valueWidget = ExpansionTile(
              title: const Text("View Details"),
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    pretty,
                    style: const TextStyle(fontFamily: "monospace"),
                  ),
                ),
              ],
            );
          } else {
            valueWidget = Text(value.toString());
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  valueWidget,
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
