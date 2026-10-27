import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/shared/widgets/product_image.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_controls.dart';

/// Lazy 3D / fallback viewer for catalog GLB assets.
///
/// Downloads are triggered only when this widget is shown for a product with
/// `has3dModel` / `model3dUrl`. We intentionally do not prefetch thousands of
/// models. Full interactive GLB viewing can be wired via `model_viewer_plus`
/// when platform WebView support is confirmed; until then we show an honest
/// fallback with metadata and image.
class Product3dViewer extends StatefulWidget {
  const Product3dViewer({
    required this.product,
    this.height = 280,
    super.key,
  });

  final Product product;
  final double height;

  @override
  State<Product3dViewer> createState() => _Product3dViewerState();
}

class _Product3dViewerState extends State<Product3dViewer> {
  var _attemptLoad = false;
  var _failed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final url = product.model3dUrl;
    final available = product.has3dModel && url != null && url.isNotEmpty;

    if (!available) {
      return _Fallback(
        product: product,
        height: widget.height,
        message: '3D-модель пока недоступна для этого товара',
      );
    }

    if (!_attemptLoad) {
      return SizedBox(
        height: widget.height,
        child: OmaSurfaceCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '3D-модель доступна',
                style: OmaType.semibold(14, OmaColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Загрузка по запросу · ~GLB с backend',
                style: OmaType.regular(12, OmaColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OmaButton(
                label: 'Загрузить модель',
                onPressed: () => setState(() => _attemptLoad = true),
              ),
            ],
          ),
        ),
      );
    }

    if (_failed || kIsWeb) {
      return _Fallback(
        product: product,
        height: widget.height,
        message: _failed
            ? 'Не удалось отобразить модель. Показано фото товара.'
            : 'Интерактивный 3D на этой платформе ограничен. Используйте фото.',
        url: url,
      );
    }

    // Architecture-ready placeholder for a GLB viewer package.
    // Avoid bundling a heavy WebView dependency until verified on target devices.
    return SizedBox(
      height: widget.height,
      child: OmaSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_in_ar, size: 48, color: OmaColors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Просмотрщик 3D готов к подключению',
                      style: OmaType.semibold(14, OmaColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'URL: $url',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OmaType.regular(11, OmaColors.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Жесты вращения будут доступны после интеграции model_viewer_plus / эквивалента.',
                      style: OmaType.regular(11, OmaColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            OmaButton(
              label: 'Показать фото вместо 3D',
              kind: OmaButtonKind.secondary,
              onPressed: () => setState(() => _failed = true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.product,
    required this.height,
    required this.message,
    this.url,
  });

  final Product product;
  final double height;
  final String message;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OmaSurfaceCard(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ProductImage(
                  product: product,
                  width: 160,
                  height: 160,
                ),
              ),
            ),
            Text(message, style: OmaType.regular(12, OmaColors.muted), textAlign: TextAlign.center),
            if (url != null) ...[
              const SizedBox(height: 4),
              Text(
                'model3dUrl сохранён для ленивой загрузки',
                style: OmaType.regular(10, OmaColors.hint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
