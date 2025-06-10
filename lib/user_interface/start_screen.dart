import "dart:io";
import "package:dio/dio.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:mycap_at_test_app/user_interface/docs_screen.dart";
import "package:mycap_at_test_app/user_interface/web_view_screen.dart";
import "package:path_provider/path_provider.dart";

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _authController = TextEditingController();
  final Dio _dio = Dio();

  bool _isDownloading = false;
  bool _hasExisting = false;
  String? _existingPath;

  @override
  void initState() {
    super.initState();
    _checkForExistingZip();
  }

  Future<void> _checkForExistingZip() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/test.zip");
    final exists = await file.exists();
    setState(() {
      _hasExisting = exists;
      _existingPath = exists ? file.path : null;
    });
  }

  Future<void> _pickLocalZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["zip"],
    );
    if (result != null && result.files.single.path != null) {
      final picked = File(result.files.single.path!);
      final dir = await getApplicationDocumentsDirectory();
      final dest = File("${dir.path}/test.zip");
      await picked.copy(dest.path);
      await _checkForExistingZip();
      _navigateToWebView(dest.path);
    }
  }

  Future<void> _downloadZip() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isDownloading = true);
    try {
      final headers = <String, String>{};
      final auth = _authController.text.trim();
      if (auth.isNotEmpty) headers["Authorization"] = auth;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/test.zip";

      await _dio.download(
        url,
        savePath,
        options: Options(headers: headers),
        onReceiveProgress: (received, total) {
          // update progress indicator if desired
        },
      );

      await _checkForExistingZip();
      _navigateToWebView(savePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _useBundledZip() async {
    // Load the bundled zip from assets and copy it into docs
    final byteData = await rootBundle.load("assets/test.zip");
    final dir = await getApplicationDocumentsDirectory();
    final dest = File("${dir.path}/test.zip");
    await dest.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    await _checkForExistingZip();
    _navigateToWebView(dest.path);
  }

  void _useExisting() {
    if (_existingPath != null) {
      _navigateToWebView(_existingPath!);
    }
  }

  void _navigateToWebView(String filepath) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebViewScreen(filePath: filepath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Screen"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DocsScreen()));
            },
            child: const Text("Docs"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload ZIP from Device"),
              onPressed: _pickLocalZip,
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.insert_drive_file),
              label: const Text("Use Bundled Test ZIP"),
              onPressed: _useBundledZip,
            ),
            const SizedBox(height: 24),

            const Text(
              "Download ZIP from URL",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "ZIP File URL",
                hintText: "https://example.com/archive.zip",
              ),
              keyboardType: TextInputType.url,
            ),
            TextField(
              controller: _authController,
              decoration: const InputDecoration(
                labelText: "Optional Auth Header",
                hintText: "Bearer your_token_here",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isDownloading ? "Downloading…" : "Download ZIP"),
              onPressed: _isDownloading ? null : _downloadZip,
            ),
            const SizedBox(height: 24),

            if (_hasExisting && _existingPath != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text("Existing ZIP Found"),
                subtitle: Text(_existingPath!),
                trailing: ElevatedButton(
                  onPressed: _useExisting,
                  child: const Text("Use Existing"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _authController.dispose();
    super.dispose();
  }
}
