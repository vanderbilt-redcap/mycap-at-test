import "dart:convert";

import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";

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

  Future<String> readDocsFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return utf8.decode(byteData.buffer.asUint8List());
  }
}
