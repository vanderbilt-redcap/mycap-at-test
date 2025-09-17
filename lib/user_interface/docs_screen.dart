import "package:flutter/material.dart";
import "package:markdown_widget/widget/markdown.dart";
import "package:mycap_at_test_app/logical_interface/docs_repository.dart";

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  String? docsContent;

  @override
  void initState() {
    super.initState();
    readDocs();
  }

  Future<void> readDocs() async {
    final content = await DocsRepository.readDocs(context);
    setState(() {
      docsContent = content;
    });
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
