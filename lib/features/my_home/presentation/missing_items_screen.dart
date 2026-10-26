import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MissingItemsScreen extends StatelessWidget {
  const MissingItemsScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'Недостающие предметы'),
      actions: [
        const DomSoftNote(
          'Итого: 1 купленный товар, 2 запланированные категории и 1 кандидат без выбора. Подбор не оформляет заказ.',
        ),
        OmaButton(
          label: 'Подобрать недостающие товары',
          onPressed: () =>
              context.push(AppRoutes.roomAiPath(propertyId, roomId)),
        ),
        OmaButton(
          label: 'Открыть покупки комнаты',
          kind: OmaButtonKind.secondary,
          onPressed: () =>
              context.push(AppRoutes.roomPurchasesPath(propertyId, roomId)),
        ),
      ],
      children: [
        DomBreadcrumb('Моя квартира / Кухня'),
        Text('Куплено · 1', style: OmaType.bold(16, OmaColors.black)),
        DomCard(
          onTap: () =>
              context.push(AppRoutes.roomPurchasesPath(propertyId, roomId)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Смеситель Ledeme L4399U-12 → покупки',
                      style: OmaType.medium(14, OmaColors.ink),
                    ),
                    Text(
                      'Установка отдельно, на согласовании.',
                      style: OmaType.regular(12, OmaColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: OmaColors.muted),
            ],
          ),
        ),
        Text('Запланировано · 2', style: OmaType.bold(16, OmaColors.black)),
        _IdeaCard(
          icon: Icons.lightbulb_outline,
          title: 'Подсветка рабочей зоны',
          selected: true,
          onAi: () => context.push(AppRoutes.roomAiPath(propertyId, roomId)),
          onInstall: () => context.push(AppRoutes.installPath('p1')),
        ),
        _IdeaCard(
          icon: Icons.view_agenda_outlined,
          title: 'Настенная полка',
          selected: true,
          onAi: () => context.push(AppRoutes.roomAiPath(propertyId, roomId)),
          onInstall: () => context.push(AppRoutes.installPath('p1')),
        ),
        Text('Ещё не выбрано · 1', style: OmaType.bold(16, OmaColors.black)),
        _IdeaCard(
          icon: Icons.inventory_2_outlined,
          title: 'Органайзер у мойки',
          selected: false,
          status: 'Исключён из примерки · не куплен',
          actionLabel: 'Перенести в подбор',
          onAi: () =>
              context.push(AppRoutes.roomSuggestionsPath(propertyId, roomId)),
          onInstall: () => context.push(AppRoutes.installPath('p1')),
        ),
        DomCard(
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.photo_camera_outlined, color: OmaColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Фото кухни после установки',
                      style: OmaType.medium(14, OmaColors.ink),
                    ),
                    Text(
                      'Не добавлено · добавить позже',
                      style: OmaType.regular(12, OmaColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: OmaColors.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onAi,
    required this.onInstall,
    this.status,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final String? status;
  final String? actionLabel;
  final VoidCallback onAi;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return DomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DomIconTile(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: OmaType.bold(15, OmaColors.black)),
                    Text(
                      status ??
                          (selected
                              ? 'Идея применена · товар не выбран'
                              : 'Не выбран'),
                      style: OmaType.regular(12, OmaColors.muted),
                    ),
                  ],
                ),
              ),
              DomCheckbox(value: selected),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Цена уточняется · категория для подбора',
            style: OmaType.regular(12, OmaColors.muted),
          ),
          const SizedBox(height: 10),
          OmaButton(
            label: actionLabel ?? 'Перенести в ИИ-подбор',
            kind: OmaButtonKind.secondary,
            onPressed: onAi,
          ),
          DomInstallBlock(
            actionLabel: 'Уточнить возможность установки',
            subtitle: 'Возможность и стоимость не подтверждены',
            linkStyle: true,
            onAction: onInstall,
          ),
        ],
      ),
    );
  }
}
