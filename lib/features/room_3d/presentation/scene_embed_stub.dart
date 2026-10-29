import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Native Android/iOS renderer for the same backend-owned Three.js scene.
class SceneEmbed extends StatefulWidget {
  const SceneEmbed({required this.url, super.key});

  final String url;

  @override
  State<SceneEmbed> createState() => _SceneEmbedState();
}

class _SceneEmbedState extends State<SceneEmbed> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffe8edef))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!error.isForMainFrame) return;
            if (mounted) setState(() {
              _loading = false;
              _error = 'Не удалось открыть 3D-сцену. Проверьте подключение к интернету и доступность сервера.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(covariant SceneEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _loading = true;
        _error = null;
      });
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const ColoredBox(
              color: Color(0xffe8edef),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xff0065ae)),
                    SizedBox(height: 12),
                    Text(
                      'Загружаем 3D-комнату…',
                      style: TextStyle(
                        color: Color(0xff35556a),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            ColoredBox(
              color: const Color(0xffe8edef),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.view_in_ar_outlined,
                        size: 38,
                        color: Color(0xff607482),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xff35556a),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _controller.reload();
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
