import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class Room3dScreen extends StatefulWidget {
  const Room3dScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<Room3dScreen> createState() => _Room3dScreenState();
}

class _Room3dScreenState extends State<Room3dScreen> {
  bool _is3d = true;
  Future<Product?>? _productFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productFuture ??= context
        .read<CatalogRepository>()
        .products(pageSize: 1)
        .then((list) => list.isEmpty ? null : list.first);
  }

  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertiesCubit>().state.properties;
    final hasIdeas = props
        .expand((p) => p.rooms)
        .any((r) => r.id == widget.roomId && r.items.isNotEmpty);

    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snap) {
        final product = snap.data;
        return OmaPage(
          header: const OmaDomHeader(title: 'Посмотреть в комнате'),
          actions: [
            const DomSoftNote(
              'Освещение и хранение можно добавить как идеи для подбора. Примерка не оформляет покупку.',
            ),
            if (product != null)
              OmaButton(
                label: 'Открыть карточку товара',
                kind: OmaButtonKind.secondary,
                onPressed: () =>
                    context.push(AppRoutes.productPath(product.id)),
              ),
            OmaButton(
              label: 'Предложения по заполнению',
              onPressed: () => context.push(
                AppRoutes.roomSuggestionsPath(
                  widget.propertyId,
                  widget.roomId,
                ),
              ),
            ),
          ],
          children: [
            _ModeToggle(
              is3d: _is3d,
              onChanged: (v) => setState(() => _is3d = v),
            ),
            Room3dViewer(is3d: _is3d),
            Text(
              'Приблизительная визуализация. Масштаб и положение условные.',
              style: OmaType.regular(12, OmaColors.muted),
            ),
            Text(
              hasIdeas
                  ? 'Выбран 1 товар · у мойки'
                  : 'Добавлены 2 идеи · не куплены',
              style: OmaType.medium(13, OmaColors.blue),
            ),
            if (product != null)
              DomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DomProductRow(
                      imageAsset: product.imageUrl ?? product.imageAsset,
                      title: product.name,
                      price: product.priceLabel,
                      status: 'Цена из бэкенда · ${product.currency}',
                    ),
                    DomInstallBlock(
                      onAction: () =>
                          context.push(AppRoutes.installPath(product.id)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.is3d, required this.onChanged});

  final bool is3d;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.line.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _Seg(
                label: '2D',
                selected: !is3d,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _Seg(
                label: '3D',
                selected: is3d,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? OmaColors.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              style: OmaType.semibold(
                13,
                selected ? OmaColors.white : OmaColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Swappable 3D viewer placeholder. Replace later with GLB/GLTF loader.
class Room3dViewer extends StatelessWidget {
  const Room3dViewer({this.is3d = true, this.roomName, this.itemCount, super.key});

  final bool is3d;
  final String? roomName;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: OmaColors.blueSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OmaColors.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  OmaImages.kitchen,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      is3d ? '3D placeholder' : '2D placeholder',
                      style: OmaType.medium(14, OmaColors.blue),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 100,
              top: 90,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: OmaColors.orange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('1', style: OmaType.bold(12, OmaColors.white)),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  for (final icon in [
                    Icons.threed_rotation,
                    Icons.zoom_in,
                    Icons.fullscreen,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: OmaColors.white,
                        child: Icon(icon, size: 16, color: OmaColors.ink),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
