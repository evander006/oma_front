import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Embeds the backend's WebGL viewer in Flutter web.
class SceneEmbed extends StatefulWidget {
  const SceneEmbed({required this.url, super.key});
  final String url;

  @override
  State<SceneEmbed> createState() => _SceneEmbedState();
}

class _SceneEmbedState extends State<SceneEmbed> {
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'oma-scene-' + identityHashCode(this).toString();
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
      iframe.setAttribute('title', 'Интерактивная 3D-квартира ОМА');
      iframe.setAttribute('allow', 'fullscreen');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
