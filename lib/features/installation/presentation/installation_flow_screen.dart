import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/orders/cubit/orders_cubit.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class InstallationFlowScreen extends StatefulWidget {
  const InstallationFlowScreen({required this.productId, super.key});

  final String productId;

  @override
  State<InstallationFlowScreen> createState() => _InstallationFlowScreenState();
}

class _InstallationFlowScreenState extends State<InstallationFlowScreen> {
  int _step = 0;
  InstallationOption? _option;
  final _address = TextEditingController(text: 'Минск, ул. Демо, 1');
  String _slot = 'Завтра, 10:00–12:00';
  String? _lastOrderId;
  Future<(Product?, List<InstallationOption>)>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= () async {
      final repo = context.read<CatalogRepository>();
      final product = await repo.byId(widget.productId);
      final options = product == null
          ? const <InstallationOption>[]
          : await repo.installations();
      return (product, options);
    }();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Product?, List<InstallationOption>)>(
      future: _load,
      builder: (context, snap) {
        final product = snap.data?.$1;
        final options = snap.data?.$2 ?? const <InstallationOption>[];
        _option ??= options.isEmpty ? null : options.first;

        if (snap.connectionState != ConnectionState.done) {
          return const OmaPage(
            header: OmaFlowHeader(title: 'Установка'),
            children: [Center(child: CircularProgressIndicator())],
          );
        }

        if (product == null) {
          return OmaPage(
            header: const OmaFlowHeader(title: 'Установка'),
            children: [
              Text(
                'Товар не найден',
                style: OmaType.regular(14, OmaColors.muted),
              ),
            ],
          );
        }

        return OmaPage(
          header: OmaFlowHeader(
            title: 'Установка',
            eyebrow: 'Шаг ${_step + 1} из 6 · демо',
          ),
          children: [..._buildStep(product, options)],
        );
      },
    );
  }

  List<Widget> _buildStep(Product product, List<InstallationOption> options) {
    switch (_step) {
      case 0:
        return [
          Text('Состав услуги', style: OmaType.bold(16, OmaColors.ink)),
          Text(
            'Демонтаж (при необходимости), монтаж, проверка. '
            'Стоимость ориентировочная — уточняется мастером.',
            style: OmaType.regular(14, OmaColors.ink),
          ),
          for (final o in options)
            _SelectTile(
              selected: _option?.id == o.id,
              title: o.title,
              subtitle:
                  '${o.priceLabel} · ${o.subtitle ?? 'Стоимость уточняется'}',
              onTap: () => setState(() => _option = o),
            ),
          OmaButton(label: 'Далее', onPressed: () => setState(() => _step = 1)),
        ];
      case 1:
        return [
          Text('Адрес', style: OmaType.bold(16, OmaColors.ink)),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Адрес установки',
            ),
          ),
          OmaButton(label: 'Далее', onPressed: () => setState(() => _step = 2)),
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: () => setState(() => _step = 0),
          ),
        ];
      case 2:
        return [
          Text(
            'Дата и время (демо-слоты)',
            style: OmaType.bold(16, OmaColors.ink),
          ),
          Text(
            'Слоты не настоящие — только для демонстрации.',
            style: OmaType.regular(12, OmaColors.muted),
          ),
          for (final s in [
            'Завтра, 10:00–12:00',
            'Послезавтра, 14:00–16:00',
            'Суббота, 11:00–13:00',
          ])
            _SelectTile(
              selected: _slot == s,
              title: s,
              onTap: () => setState(() => _slot = s),
            ),
          OmaButton(label: 'Далее', onPressed: () => setState(() => _step = 3)),
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: () => setState(() => _step = 1),
          ),
        ];
      case 3:
        return [
          Text('Сводка', style: OmaType.bold(16, OmaColors.ink)),
          _Line('Товар', product.name),
          _Line('Цена товара', product.priceLabel),
          _Line('Услуга', _option?.title ?? '—'),
          _Line(
            'Стоимость',
            _option == null
                ? 'Стоимость уточняется'
                : 'от ${_option!.priceFromByn.toStringAsFixed(0)} р.',
          ),
          _Line('Адрес', _address.text),
          _Line('Слот', _slot),
          OmaButton(
            label: 'Подтвердить',
            onPressed: () => setState(() => _step = 4),
          ),
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: () => setState(() => _step = 2),
          ),
        ];
      case 4:
        return [
          Text('Подтверждение', style: OmaType.bold(16, OmaColors.ink)),
          Text(
            'Оформить демо-заказ с товаром и услугой установки?',
            style: OmaType.regular(14, OmaColors.ink),
          ),
          OmaButton(
            label: 'Оформить',
            onPressed: () async {
              final cart = context.read<CartCubit>();
              cart.add(product);
              cart.setInstallation(_option);
              final order = await context.read<OrdersCubit>().place(
                    items: cart.state.items,
                    totalByn: cart.state.total,
                    installation: _option,
                    note: '${_address.text} · $_slot',
                  );
              cart.clear();
              if (!mounted) return;
              setState(() {
                _lastOrderId = order.id;
                _step = 5;
              });
            },
          ),
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: () => setState(() => _step = 3),
          ),
        ];
      default:
        return [
          const Icon(Icons.check_circle, color: OmaColors.green, size: 56),
          Text('Заявка принята', style: OmaType.bold(20, OmaColors.ink)),
          Text(
            'Демо-заказ №${(_lastOrderId ?? '--------').substring(0, 8)}',
            style: OmaType.regular(14, OmaColors.muted),
          ),
          Text(
            'Оплата не выполняется. Слоты демонстрационные.',
            style: OmaType.regular(13, OmaColors.muted),
          ),
          OmaButton(
            label: 'К истории заказов',
            onPressed: () => context.go(AppRoutes.orders),
          ),
          OmaButton(
            label: 'На главную',
            kind: OmaButtonKind.secondary,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ];
    }
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: OmaColors.white,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? OmaColors.blue : OmaColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? OmaColors.blue : OmaColors.muted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: OmaType.medium(14, OmaColors.ink)),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: OmaType.regular(12, OmaColors.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: OmaType.regular(13, OmaColors.muted)),
          ),
          Expanded(
            child: Text(value, style: OmaType.medium(13, OmaColors.ink)),
          ),
        ],
      ),
    );
  }
}
