import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class RoomPurchasesScreen extends StatefulWidget {
  const RoomPurchasesScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<RoomPurchasesScreen> createState() => _RoomPurchasesScreenState();
}

class _RoomPurchasesScreenState extends State<RoomPurchasesScreen> {
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
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snap) {
        final product = snap.data;
        if (product == null) {
          return const OmaPage(
            header: OmaDomHeader(title: 'Покупки комнаты'),
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        return OmaPage(
          header: const OmaDomHeader(title: 'Покупки комнаты'),
          actions: [
            DomSoftNote(
              '${product.priceLabel} — стоимость товара из каталога API. Установка не включена.',
            ),
            OmaButton(
              label: 'Недостающие предметы',
              kind: OmaButtonKind.secondary,
              onPressed: () => context.push(
                AppRoutes.roomMissingPath(widget.propertyId, widget.roomId),
              ),
            ),
          ],
          children: [
            DomBreadcrumb('Моя квартира / Кухня'),
            DomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Куплен 1 товар',
                    style: OmaType.medium(13, OmaColors.blue),
                  ),
                  const SizedBox(height: 12),
                  DomProductRow(
                    imageAsset: product.imageUrl ?? product.imageAsset,
                    title: product.name,
                    price: product.priceLabel,
                    status: 'Куплен · 1 шт. · ${product.currency}',
                  ),
                  DomInstallBlock(
                    actionLabel: 'Что входит в услугу?',
                    onAction: () =>
                        context.push(AppRoutes.installPath(product.id)),
                  ),
                ],
              ),
            ),
            Text('Данные покупки', style: OmaType.bold(16, OmaColors.black)),
            DomCard(
              child: Column(
                children: [
                  _NavRow(
                    title: 'Заказ № 261020-014',
                    subtitle: '20.10.2026 · 1 шт.',
                    onTap: () => context.push(AppRoutes.orders),
                  ),
                  const Divider(height: 20),
                  _NavRow(
                    title: 'Расположение',
                    subtitle: 'Моя квартира / Кухня',
                    onTap: () => context.push(
                      AppRoutes.roomPath(widget.propertyId, widget.roomId),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OmaButton(
                    label: 'Открыть оборудование',
                    kind: OmaButtonKind.secondary,
                    onPressed: () =>
                        context.push(AppRoutes.productPath(product.id)),
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

class RoomSavedScreen extends StatefulWidget {
  const RoomSavedScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<RoomSavedScreen> createState() => _RoomSavedScreenState();
}

class _RoomSavedScreenState extends State<RoomSavedScreen> {
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
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snap) {
        final product = snap.data;
        if (product == null) {
          return const OmaPage(
            header: OmaDomHeader(title: 'Сохранено в «Мой дом»'),
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        return OmaPage(
          header: const OmaDomHeader(title: 'Сохранено в «Мой дом»'),
          actions: [
            OmaButton(
              label: 'Открыть комнату',
              onPressed: () => context.push(
                AppRoutes.roomPath(widget.propertyId, widget.roomId),
              ),
            ),
            OmaButton(
              label: 'К покупкам',
              kind: OmaButtonKind.secondary,
              onPressed: () => context.push(
                AppRoutes.roomPurchasesPath(widget.propertyId, widget.roomId),
              ),
            ),
          ],
          children: [
            Text(
              'Покупка уже в вашей кухне',
              style: OmaType.bold(22, OmaColors.black),
            ),
            DomCard(
              child: DomProductRow(
                imageAsset: product.imageUrl ?? product.imageAsset,
                title: product.name,
                price: product.priceLabel,
                status: 'Куплен · 1 шт. · ${product.currency}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OmaType.medium(14, OmaColors.ink)),
                Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: OmaColors.muted),
        ],
      ),
    );
  }
}
