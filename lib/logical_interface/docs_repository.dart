import "package:flutter/cupertino.dart";

class DocsRepository {
  static Future<String> readDocs(BuildContext context) async {
    try {
      final content = await DefaultAssetBundle.of(
        context,
      ).loadString("README.md");
      return content;
    } catch (e) {
      print("Error loading docs: $e");
      rethrow;
    }
  }
}
