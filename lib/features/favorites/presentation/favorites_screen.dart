import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/favorites/cubit/favorites_cubit.dart';
import 'package:oma/shared/widgets/product_card.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<FavoritesCubit>().state.items;

    return OmaPage(
      header: const OmaFlowHeader(title: 'Избранное', eyebrow: 'ОМА · демо'),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Text(
                  'Пока пусто',
                  style: OmaType.medium(16, OmaColors.ink),
                ),
                const SizedBox(height: 12),
                OmaButton(
                  label: 'В каталог',
                  onPressed: () => context.go(AppRoutes.catalog),
                ),
              ],
            ),
          )
        else
          for (final p in items) ...[
            ProductCard(
              product: p,
              onTap: () => context.push(AppRoutes.productPath(p.id)),
              onAdd: () {
                context.read<CartCubit>().add(p);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Добавлено в корзину')),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.read<FavoritesCubit>().toggle(p),
                child: Text(
                  'Убрать',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
      ],
    );
  }
}
