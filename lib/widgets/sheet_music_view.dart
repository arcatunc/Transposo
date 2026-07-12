import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// Renders an ABC notation string as sheet music via the bundled ABCJS
/// template inside a webview.
///
/// The ABCJS source is spliced inline into the template at load time and the
/// page is fed through [WebViewController.loadHtmlString], so the webview
/// never has to resolve relative asset URLs (which is unreliable on Android).
///
/// On platforms without a webview implementation (widget tests, desktop),
/// or if the page reports a JavaScript error, falls back to showing the raw
/// ABC text so the rest of the app keeps working.
class SheetMusicView extends StatefulWidget {
  const SheetMusicView({super.key, required this.abc});

  /// The full ABC document (header + partitioned body) to render.
  final String abc;

  @override
  State<SheetMusicView> createState() => _SheetMusicViewState();
}

class _SheetMusicViewState extends State<SheetMusicView> {
  static const _templateAsset = 'assets/abcjs_template.html';
  static const _libraryAsset = 'assets/abcjs-basic-min.js';
  static const _scriptTag = '<script src="abcjs-basic-min.js"></script>';

  WebViewController? _controller;
  bool _pageReady = false;
  bool _renderFailed = false;

  static bool get _webViewSupported => WebViewPlatform.instance != null;

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'SheetBridge',
          onMessageReceived: (message) {
            if (message.message.startsWith('error:')) {
              debugPrint('SheetMusicView JS error: ${message.message}');
              if (mounted) setState(() => _renderFailed = true);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              _pageReady = true;
              _render();
            },
          ),
        );
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    final html = await rootBundle.loadString(_templateAsset);
    final js = await rootBundle.loadString(_libraryAsset);
    // replaceFirst treats the replacement literally, so the JS source needs
    // no escaping.
    final page = html.replaceFirst(_scriptTag, '<script>\n$js\n</script>');
    await _controller?.loadHtmlString(page);
  }

  @override
  void didUpdateWidget(SheetMusicView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.abc != oldWidget.abc) {
      _render();
    }
  }

  void _render() {
    if (!_pageReady || _controller == null) return;
    // jsonEncode produces a valid JS string literal, escaping quotes/newlines.
    _controller!.runJavaScript('renderAbc(${jsonEncode(widget.abc)});');
  }

  @override
  Widget build(BuildContext context) {
    if (!_webViewSupported || _renderFailed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          widget.abc,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontFamily: 'monospace'),
        ),
      );
    }
    return SizedBox(
      height: 320,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
