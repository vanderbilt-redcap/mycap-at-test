import "package:flutter/material.dart";
import "package:markdown_widget/widget/markdown.dart";

class DocsScreen extends StatelessWidget {
  final String docsContent;

  const DocsScreen({required this.docsContent, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Docs"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: MarkdownWidget(data: docsContent),
      ),
    );
  }
}
