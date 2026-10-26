import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/orders/cubit/orders_cubit.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CartCubit>().state;

    return OmaPage(
      header: const OmaFlowHeader(title: 'Корзина', eyebrow: 'ОМА · демо'),
      actions: state.items.isEmpty
          ? const []
          : [
              Row(
                children: [
                  Text('Итого', style: OmaType.medium(14, OmaColors.ink)),
                  const Spacer(),
                  Text(
                    '${state.total.toStringAsFixed(2)} р.',
                    style: OmaType.bold(18, OmaColors.ink),
                  ),
                ],
              ),
              if (state.installation != null)
                Text(
                  'Вкл. установка: ${state.installation!.title}',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
              OmaButton(
                label: 'Оформить демо-заказ',
                onPressed: () async {
                  final order = await context.read<OrdersCubit>().place(
                        items: state.items,
                        totalByn: state.total,
                        installation: state.installation,
                      );
                  if (!context.mounted) return;
                  context.read<CartCubit>().clear();
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Заказ оформлен'),
                      content: Text(
                        'Демо-заказ №${order.id.substring(0, 8)}\n'
                        'Оплата не выполняется — это демонстрация.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(AppRoutes.orders);
                          },
                          child: const Text('К истории'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
      children: [
        if (state.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Text(
                  'Корзина пуста',
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
          for (final item in state.items) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OmaColors.white,
                border: Border.all(color: OmaColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    item.product.imageAsset,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: OmaType.medium(14, OmaColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.product.priceLabel,
                          style: OmaType.bold(14, OmaColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context
                                  .read<CartCubit>()
                                  .setQty(item.product.id, item.qty - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.qty}', style: OmaType.medium(14, OmaColors.ink)),
                            IconButton(
                              onPressed: () => context
                                  .read<CartCubit>()
                                  .setQty(item.product.id, item.qty + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => context
                                  .read<CartCubit>()
                                  .remove(item.product.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        Text(
          'Цены демонстрационные. Оплата не подключена.',
          style: OmaType.regular(11, OmaColors.muted),
        ),
      ],
    );
  }
}
