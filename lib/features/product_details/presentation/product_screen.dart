import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/favorites/cubit/favorites_cubit.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/features/product_3d/presentation/product_3d_viewer.dart';
import 'package:oma/shared/widgets/product_image.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({required this.productId, super.key});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _product;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final product =
          await context.read<CatalogRepository>().byId(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
        _error = product == null ? 'Товар не найден' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmaPage(
        header: OmaFlowHeader(title: 'Товар'),
        children: [Center(child: CircularProgressIndicator())],
      );
    }

    final product = _product;
    if (product == null) {
      return OmaPage(
        header: const OmaFlowHeader(title: 'Товар'),
        children: [
          Text(
            _error ?? 'Товар не найден',
            style: OmaType.regular(14, OmaColors.muted),
          ),
          OmaButton(
            label: 'В каталог',
            onPressed: () => context.go(AppRoutes.catalog),
          ),
        ],
      );
    }

    final fav = context.watch<FavoritesCubit>().state.contains(product.id);
    final installs =
        context.read<CatalogRepository>().installationsFor(product);
    final selected = context.watch<PropertiesCubit>().state.selected;
    RoomLink? roomLink;
    if (selected != null && selected.rooms.isNotEmpty) {
      final kitchen = selected.rooms.where((r) => r.kind == 'kitchen');
      final room = kitchen.isNotEmpty ? kitchen.first : selected.rooms.first;
      roomLink = RoomLink(propertyId: selected.id, roomId: room.id);
    }

    return OmaPage(
      header: OmaFlowHeader(
        title: product.name,
        eyebrow: 'Карточка товара · API',
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AspectRatio(
            aspectRatio: 1,
            child: ProductImage(product: product, fit: BoxFit.contain),
          ),
        ),
        if (product.sku != null)
          Text(product.sku!, style: OmaType.regular(11, OmaColors.muted)),
        Text(product.name, style: OmaType.regular(17, OmaColors.ink)),
        Text(product.priceLabel, style: OmaType.bold(23, OmaColors.black)),
        Text(
          'Цена за штуку · ${product.currency} · снимок каталога',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        Row(
          children: [
            Expanded(
              child: OmaButton(
                label: fav ? 'В избранном' : 'В избранное',
                kind: OmaButtonKind.orange,
                onPressed: () =>
                    context.read<FavoritesCubit>().toggle(product),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmaButton(
                label: 'В корзину',
                onPressed: () async {
                  await context.read<CartCubit>().add(product);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавлено в корзину')),
                  );
                },
              ),
            ),
          ],
        ),
        if (roomLink case final link?)
          OmaButton(
            label: 'Посмотреть в комнате',
            kind: OmaButtonKind.secondary,
            onPressed: () => context.push(
              AppRoutes.room3dPath(link.propertyId, link.roomId),
            ),
          ),
        OmaButton(
          label: 'Заказать установку / услугу',
          kind: OmaButtonKind.secondary,
          onPressed: () {
            if (installs.isNotEmpty) {
              context.push(AppRoutes.installPath(product.id));
            } else {
              context.go(AppRoutes.services);
            }
          },
        ),
        if (installs.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OmaColors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: OmaColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Нужна установка?', style: OmaType.bold(15, OmaColors.ink)),
                const SizedBox(height: 6),
                Text(
                  product.installHint ?? 'Платная услуга · Стоимость уточняется',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
                const SizedBox(height: 10),
                OmaButton(
                  label: 'Добавить установку',
                  kind: OmaButtonKind.secondary,
                  onPressed: () =>
                      context.push(AppRoutes.installPath(product.id)),
                ),
              ],
            ),
          ),
        Text('3D-модель', style: OmaType.bold(15, OmaColors.ink)),
        Product3dViewer(product: product),
        if (product.description.isNotEmpty) ...[
          Text('Описание', style: OmaType.bold(15, OmaColors.ink)),
          Text(product.description, style: OmaType.regular(13, OmaColors.ink)),
        ],
        if (product.specs.isNotEmpty) ...[
          Text('Характеристики', style: OmaType.bold(15, OmaColors.ink)),
          for (final e in product.specs.entries)
            OmaDataRow(label: e.key, value: e.value),
        ],
      ],
    );
  }
}

class RoomLink {
  const RoomLink({required this.propertyId, required this.roomId});
  final String propertyId;
  final String roomId;
}
