import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _selected = <String>{'light', 'shelf'};

  @override
  Widget build(BuildContext context) {
    final ideas = [
      (
        'light',
        Icons.lightbulb_outline,
        'Подсветка рабочей зоны',
        'Для столешницы · выбрано',
      ),
      (
        'shelf',
        Icons.view_agenda_outlined,
        'Настенная полка',
        'Для хранения · выбрано',
      ),
      (
        'org',
        Icons.inventory_2_outlined,
        'Органайзер у мойки',
        'Не выбран · можно добавить позже',
      ),
    ];

    return OmaPage(
      header: const OmaDomHeader(title: 'Предложения по заполнению'),
      actions: [
        const DomSoftNote(
          'Это категории-кандидаты, не подтверждённый ассортимент. Изображения и цены условные до проверки.',
        ),
        OmaButton(
          label: 'Применить к комнате (${_selected.length})',
          onPressed: () => context.push(
            AppRoutes.room3dPath(widget.propertyId, widget.roomId),
          ),
        ),
        OmaButton(
          label: 'Вернуться к обзору',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        Text(
          'Что ещё нужно кухне?',
          style: OmaType.bold(22, OmaColors.black),
        ),
        Text(
          'Выбраны две идеи. Подберём конкретные товары после проверки размеров и ваших пожеланий.',
          style: OmaType.regular(14, OmaColors.muted),
        ),
        Text(
          'Выбрано ${_selected.length} из ${ideas.length}',
          style: OmaType.medium(13, OmaColors.blue),
        ),
        for (final idea in ideas)
          DomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DomIconTile(icon: idea.$2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(idea.$3, style: OmaType.bold(15, OmaColors.black)),
                          Text(
                            _selected.contains(idea.$1)
                                ? idea.$4.replaceFirst('Не выбран', 'Выбрано')
                                : 'Не выбран · можно добавить позже',
                            style: OmaType.regular(12, OmaColors.muted),
                          ),
                        ],
                      ),
                    ),
                    DomCheckbox(
                      value: _selected.contains(idea.$1),
                      onTap: () => setState(() {
                        if (_selected.contains(idea.$1)) {
                          _selected.remove(idea.$1);
                        } else {
                          _selected.add(idea.$1);
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Цена уточняется · категория для подбора',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
                const SizedBox(height: 10),
                OmaButton(
                  label: _selected.contains(idea.$1)
                      ? 'Исключить из предложений'
                      : 'Выбрать',
                  kind: OmaButtonKind.secondary,
                  onPressed: () => setState(() {
                    if (_selected.contains(idea.$1)) {
                      _selected.remove(idea.$1);
                    } else {
                      _selected.add(idea.$1);
                    }
                  }),
                ),
                DomInstallBlock(
                  actionLabel: 'Уточнить возможность установки',
                  subtitle: 'Возможность и стоимость не подтверждены',
                  onAction: () => context.push(AppRoutes.installPath('p1')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
