import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/orders/cubit/orders_cubit.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersCubit>().state.orders;

    return OmaPage(
      header: const OmaFlowHeader(title: 'Заказы', eyebrow: 'История · демо'),
      children: [
        if (orders.isEmpty)
          Text(
            'Заказов пока нет',
            style: OmaType.regular(14, OmaColors.muted),
          )
        else
          for (final order in orders) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OmaColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OmaColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '№${order.id.substring(0, 8)}',
                    style: OmaType.bold(15, OmaColors.ink),
                  ),
                  Text(
                    '${order.createdAt.day}.${order.createdAt.month}.${order.createdAt.year}'
                    ' · ${order.totalByn.toStringAsFixed(2)} р.',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                  const SizedBox(height: 8),
                  for (final item in order.items)
                    Text(
                      '· ${item.product.name} × ${item.qty}',
                      style: OmaType.regular(13, OmaColors.ink),
                    ),
                  if (order.installation != null)
                    Text(
                      '· Установка: ${order.installation!.title}',
                      style: OmaType.regular(13, OmaColors.blue),
                    ),
                  if (order.note != null)
                    Text(order.note!, style: OmaType.regular(12, OmaColors.muted)),
                  const SizedBox(height: 8),
                  OmaTextAction(
                    label: 'Добавить товар в комнату',
                    onPressed: () {
                      final prop =
                          context.read<PropertiesCubit>().state.selected;
                      if (prop == null || prop.rooms.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Сначала создайте объект'),
                          ),
                        );
                        return;
                      }
                      final first = order.items.first;
                      context.read<PropertiesCubit>().addItemToRoom(
                            propertyId: prop.id,
                            roomId: prop.rooms.first.id,
                            productId: first.product.id,
                            name: first.product.name,
                            qty: first.qty,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Добавлено в «${prop.rooms.first.name}» '
                            '(не означает установку)',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        OmaButton(
          label: 'В профиль',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.go(AppRoutes.profile),
        ),
      ],
    );
  }
}
