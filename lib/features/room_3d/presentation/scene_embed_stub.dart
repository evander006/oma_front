import 'package:flutter/material.dart';

/// No fake 3D illustration on unsupported platforms.
class SceneEmbed extends StatelessWidget {
  const SceneEmbed({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xffeaf2f6),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Интерактивная 3D-квартира сейчас доступна в веб-версии ОМА. Дом.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
