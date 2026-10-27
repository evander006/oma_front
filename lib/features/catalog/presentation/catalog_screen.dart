import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/catalog/cubit/catalog_cubit.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/shared/widgets/product_card.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        final categories = [
          const CatalogCategory(id: 'Все', name: 'Все'),
          ...state.categories,
        ];

        return OmaPage(
          header: const OmaFlowHeader(
            title: 'Каталог',
            eyebrow: 'ОМА · API',
            showCart: true,
          ),
          children: [
            TextField(
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  context.read<CatalogCubit>().setQuery(v);
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск товаров',
                filled: true,
                fillColor: OmaColors.searchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: OmaColors.muted),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in categories) ...[
                    ChoiceChip(
                      label: Text(c.name),
                      selected: state.categoryId == c.id,
                      onSelected: (_) =>
                          context.read<CatalogCubit>().setCategory(c.id),
                      selectedColor: OmaColors.blueSoft,
                      labelStyle: OmaType.medium(
                        12,
                        state.categoryId == c.id
                            ? OmaColors.blue
                            : OmaColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                Text('Сортировка:', style: OmaType.regular(12, OmaColors.muted)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: state.sort,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('По названию')),
                    DropdownMenuItem(value: 'price', child: Text('По цене')),
                  ],
                  onChanged: (v) =>
                      context.read<CatalogCubit>().setSort(v ?? 'name'),
                ),
              ],
            ),
            if (state.status == CatalogStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.status == CatalogStatus.failure)
              Column(
                children: [
                  Text(
                    state.error ?? 'Не удалось загрузить каталог',
                    style: OmaType.regular(13, OmaColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<CatalogCubit>().load(),
                    child: const Text('Повторить'),
                  ),
                ],
              )
            else if (state.products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Ничего не найдено',
                    style: OmaType.regular(14, OmaColors.muted),
                  ),
                ),
              )
            else
              for (final Product p in state.products) ...[
                ProductCard(
                  product: p,
                  onTap: () => context.push(AppRoutes.productPath(p.id)),
                  onAdd: () async {
                    await context.read<CartCubit>().add(p);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Добавлено в корзину')),
                    );
                  },
                ),
              ],
            Text(
              'Цены из бэкенда OMA. Дом — снимок каталога, не онлайн-наличие магазина.',
              style: OmaType.regular(11, OmaColors.muted),
            ),
          ],
        );
      },
    );
  }
}
