import "package:flutter/material.dart";
import "package:markdown_widget/widget/markdown.dart";

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  String? docsContent;

  Future<void> readDocs() async {
    try {
      final content = await DefaultAssetBundle.of(
        context,
      ).loadString("README.md");
      setState(() {
        docsContent = content;
      });
    } catch (e) {
      print("Error loading docs: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    readDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Docs"), centerTitle: true),
      body: docsContent == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MarkdownWidget(data: docsContent!),
            ),
    );
  }
}
