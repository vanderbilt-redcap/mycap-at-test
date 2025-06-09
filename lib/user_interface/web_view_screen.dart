// lib/user_interface/web_view_screen.dart

import "dart:convert";
import "dart:io";

import "package:archive/archive.dart";
import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";

import "results_screen.dart";

class WebViewScreen extends StatefulWidget {
  /// Local path to the ZIP file (e.g. from StartScreen)
  final String filePath;

  const WebViewScreen({required this.filePath, super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _indexFilePath;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _prepareLocalFiles();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.location.request();
  }

  /// Search a directory recursively for index.html (skip __MACOSX folders).
  Future<String?> _findIndexHtml(String dirPath) async {
    final dir = Directory(dirPath);
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          entity.path.endsWith("index.html") &&
          !entity.path.contains("__MACOSX")) {
        return entity.path;
      }
    }
    return null;
  }

  /// If already extracted, reuse; otherwise unzip `widget.filePath` here.
  Future<void> _prepareLocalFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final extractionDir = Directory("${docs.path}/website_test");

    if (!await extractionDir.exists()) {
      await extractionDir.create(recursive: true);
    }

    // Clear prior contents if desired:
    // await extractionDir.delete(recursive: true);
    // await extractionDir.create(recursive: true);

    // Decode & extract the ZIP from widget.filePath
    final bytes = await File(widget.filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final outPath = "${extractionDir.path}/${file.name}";
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    // Locate the extracted index.html
    final found = await _findIndexHtml(extractionDir.path);
    if (found == null) {
      throw Exception("index.html not found inside ZIP");
    }

    setState(() {
      _indexFilePath = found;
      _isLoading = false;
    });
  }

  /// Install a JS handler so your page can call:
  ///   window.returnData.postMessage(JSON.stringify({...}));
  void _setupJavaScriptHandler() {
    _webViewController?.addJavaScriptHandler(
      handlerName: "returnData",
      callback: (args) {
        if (args.isEmpty) return;
        final raw = args.first.toString();
        Map<String, dynamic> data;
        try {
          data = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          data = {"error": "Invalid JSON"};
        }
        // Navigate to ResultsScreen with the decoded data
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ResultsScreen(data: data)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Embedded Website"),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri("file://$_indexFilePath"),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  allowingReadAccessTo: WebUri(
                    'file://${_indexFilePath!.substring(0, _indexFilePath!.lastIndexOf('/'))}/',
                  ),
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  _setupJavaScriptHandler();
                },
                onLoadStop: (controller, url) async {
                  // Override window.returnData if not already done.
                  await controller.evaluateJavascript(
                    source: '''
                    if (!window.returnDataOverridden) {
                      window.returnDataOverridden = true;
                      window.returnData.postMessage = function(data) {
                        window.flutter_inappwebview.callHandler("returnData", data);
                      };
                    }
                  ''',
                  );
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onConsoleMessage: (controller, msg) {
                  debugPrint("WebView console: ${msg.message}");
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                      return ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.PROCEED,
                      );
                    },
              ),
            ),
    );
  }
}
