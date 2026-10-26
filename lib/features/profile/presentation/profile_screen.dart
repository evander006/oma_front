import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/features/orders/cubit/orders_cubit.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertiesCubit>().state;
    final orders = context.watch<OrdersCubit>().state.orders;
    final selected = props.selected;

    return OmaPage(
      header: const OmaDomHeader(title: 'Профиль'),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: OmaColors.blueSoft,
              child: Icon(Icons.person_outline, color: OmaColors.blue, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Анна Ковалёва', style: OmaType.bold(16, OmaColors.black)),
                  Text(
                    '+375 (29) •••-••-48',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ОМА ДОМ / Мой дом',
                style: OmaType.bold(15, OmaColors.blue),
              ),
              const SizedBox(height: 6),
              Text(
                'Управляйте объектами, переходите к паспорту дома и добавляйте новые объекты.',
                style: OmaType.regular(12, OmaColors.muted),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < props.properties.length; i++) ...[
                if (i > 0) const Divider(height: 20),
                _HomeEntry(
                  property: props.properties[i],
                  onTap: () {
                    final p = props.properties[i];
                    context.read<PropertiesCubit>().select(p.id);
                    if (p.isDraft) {
                      context.push(AppRoutes.propertyEditPath(p.id));
                    } else {
                      context.push(AppRoutes.propertyPath(p.id));
                    }
                  },
                ),
              ],
              if (props.properties.isEmpty)
                Text(
                  'Объектов пока нет',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
              const SizedBox(height: 14),
              OmaButton(
                label: 'Перейти к списку объектов',
                kind: OmaButtonKind.secondary,
                onPressed: () {
                  if (props.hasProperty) {
                    context.push(AppRoutes.myHome);
                  } else {
                    context.push(AppRoutes.onboarding);
                  }
                },
              ),
              const SizedBox(height: 10),
              OmaButton(
                label: '+ Добавить объект',
                kind: OmaButtonKind.secondary,
                onPressed: () => context.push(AppRoutes.onboarding),
              ),
            ],
          ),
        ),
        _MenuTile(
          title: 'Мои заказы',
          subtitle: orders.isEmpty
              ? 'Пока нет демо-заказов'
              : 'Заказ № ${orders.first.id}',
          onTap: () => context.push(AppRoutes.orders),
        ),
        _MenuTile(
          title: 'Адреса',
          subtitle: selected?.address ?? 'Добавьте адрес объекта',
          onTap: () {
            if (selected != null) {
              context.push(AppRoutes.propertyEditPath(selected.id));
            }
          },
        ),
        _MenuTile(
          title: 'Избранное',
          onTap: () => context.go(AppRoutes.favorites),
        ),
        _MenuTile(title: 'Купленные товары', onTap: () {}),
        _MenuTile(
          title: 'История заказов',
          onTap: () => context.push(AppRoutes.orders),
        ),
        _MenuTile(title: 'История просмотров', onTap: () {}),
        _MenuTile(title: 'История уведомлений', onTap: () {}),
        _MenuTile(title: 'Настройки уведомлений', onTap: () {}),
        _MenuTile(
          title: 'Моя информация',
          subtitle: 'Личные данные и настройки аккаунта',
          onTap: () {},
        ),
        Text('ЛИЧНЫЙ КАБИНЕТ', style: OmaType.medium(12, OmaColors.muted)),
        _MenuTile(title: 'Настройки аккаунта', onTap: () {}),
        _MenuTile(title: 'Безопасность и пароль', onTap: () {}),
        Text('ПОМОЩЬ', style: OmaType.medium(12, OmaColors.muted)),
        _MenuTile(title: 'Помощь', onTap: () {}),
        _MenuTile(title: 'Позвонить нам', onTap: () {}),
        _MenuTile(title: 'Возврат и гарантия', onTap: () {}),
        _MenuTile(title: 'Договор публичной оферты', onTap: () {}),
        _MenuTile(title: 'Адреса магазинов', onTap: () {}),
        Text(
          'Управляйте заказами, адресами и данными вашего дома.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Выйти из профиля',
              style: OmaType.medium(14, const Color(0xFFC62828)),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeEntry extends StatelessWidget {
  const _HomeEntry({required this.property, required this.onTap});

  final Property property;
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
                Text(property.name, style: OmaType.medium(14, OmaColors.ink)),
                Text(
                  property.isDraft
                      ? 'Черновик · объект не заполнен'
                      : [
                          if (property.address != null) property.address!,
                          if (property.areaSqm != null)
                            '${property.areaSqm!.toStringAsFixed(0)} м²',
                          if (property.livingRooms != null)
                            '${property.livingRooms} комнаты',
                        ].where((e) => e.isNotEmpty).join(' · '),
                  style: OmaType.regular(12, OmaColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: OmaColors.muted),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: OmaColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: OmaType.medium(14, OmaColors.ink)),
                    if (subtitle != null)
                      Text(subtitle!, style: OmaType.regular(12, OmaColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: OmaColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
