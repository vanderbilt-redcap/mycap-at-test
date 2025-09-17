import "package:flutter/material.dart";
import "package:mycap_at_test_app/utilities/sanitize_service.dart";

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultsScreen({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final sanitized = SanitizeService.sanitize(data) as Map<String, dynamic>;
    final prettyString = SanitizeService.prettyJson(sanitized);

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
