import "dart:convert";
import "dart:io";

import "package:archive/archive.dart";
import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";

import "results_screen.dart";

class WebViewScreen extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> queryParams;

  const WebViewScreen({
    required this.filePath,
    this.queryParams = const {},
    super.key,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _indexFilePath;
  final List<String> logs = [];

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

  Future<void> _prepareLocalFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final extractionDir = Directory("${docs.path}/website_test");

    if (!await extractionDir.exists()) {
      await extractionDir.create(recursive: true);
    }

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

    final found = await _findIndexHtml(extractionDir.path);
    if (found == null) {
      throw Exception("index.html not found inside ZIP");
    }

    setState(() {
      _indexFilePath = found;
      _isLoading = false;
    });
  }

  void _setupJavaScriptHandler() {
    _webViewController?.addJavaScriptHandler(
      handlerName: "returnData",
      callback: (args) {
        late Map<String, dynamic> payload;

        payload = {"logs": logs};
        if (args.isEmpty && payload.isEmpty) return;

        final raw = args[0];
        if (raw is! String) {
          debugPrint("❌ Expected String but got ${raw.runtimeType}");
          return;
        }

        try {
          final decoded = jsonDecode(raw);
          if (decoded is String) {
            payload = jsonDecode(decoded) as Map<String, dynamic>;
          } else if (decoded is Map<String, dynamic>) {
            payload = decoded;
          } else {
            debugPrint("❌ JSON structure unexpected: ${decoded.runtimeType}");
            return;
          }
          payload["logs"] = logs;

          debugPrint("📥 Received payload: $payload");
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultsScreen(data: payload)),
          );
        } catch (e) {
          debugPrint("❌ JSON decode failed: $e");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _indexFilePath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build a file:// URI with query parameters
    final params = widget.queryParams.map((key, value) {
      if (value is Iterable) {
        // flatten an Iterable of non-String
        return MapEntry(key, value.map((e) => e.toString()).toList());
      } else {
        return MapEntry(key, value.toString());
      }
    });
    final uri = Uri.file(_indexFilePath!).replace(queryParameters: params);

    print("The URI is: $uri");
    print("The received query params: ${widget.queryParams}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Embedded Website"),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
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
            final jsonParams = jsonEncode(widget.queryParams);
            await controller.evaluateJavascript(
              source:
                  """
    window.searchParams = new URLSearchParams(window.location.search);
    window.flutterQueryParams = $jsonParams;
    null;
  """,
            );
          },

          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("WebView console: ${consoleMessage.message}");
            logs.add(
              "${DateTime.now().toIso8601String()}: ${consoleMessage.message}",
            );
          },
          onReceivedServerTrustAuthRequest: (controller, challenge) async {
            return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED,
            );
          },
        ),
      ),
    );
  }
}
