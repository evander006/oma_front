import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class TurnkeyWizardScreen extends StatefulWidget {
  const TurnkeyWizardScreen({this.requestId, super.key});

  final String? requestId;

  @override
  State<TurnkeyWizardScreen> createState() => _TurnkeyWizardScreenState();
}

class _TurnkeyWizardScreenState extends State<TurnkeyWizardScreen> {
  static const _totalSteps = 10;

  RenovationRequest? _draft;
  var _step = 0;
  var _loading = true;
  var _saving = false;
  String? _error;

  final _area = TextEditingController();
  final _rooms = TextEditingController();
  final _styleNotes = TextEditingController();
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final cubit = context.read<ProjectsCubit>();
      RenovationRequest draft;
      final id = widget.requestId;
      if (id != null) {
        RenovationRequest? existing;
        for (final e in cubit.state.items) {
          if (e.id == id) {
            existing = e;
            break;
          }
        }
        draft = existing ?? await cubit.createDraft();
      } else {
        draft = await cubit.createDraft();
      }
      _syncControllers(draft);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _syncControllers(RenovationRequest d) {
    _area.text = d.areaSqm?.toString() ?? '';
    _rooms.text = d.roomsCount?.toString() ?? '';
    _styleNotes.text = d.styleNotes ?? '';
    _address.text = d.address ?? '';
    _name.text = d.contactName ?? '';
    _phone.text = d.contactPhone ?? '';
  }

  RenovationRequest _collect(RenovationRequest base) {
    return base.copyWith(
      areaSqm: double.tryParse(_area.text.replaceAll(',', '.')),
      roomsCount: int.tryParse(_rooms.text),
      styleNotes: _styleNotes.text.trim(),
      address: _address.text.trim(),
      contactName: _name.text.trim(),
      contactPhone: _phone.text.trim(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _persist({bool submit = false}) async {
    final current = _draft;
    if (current == null) return;
    setState(() => _saving = true);
    final next = _collect(current);
    try {
      if (submit) {
        if (!next.consentPersonalData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нужно согласие на обработку персональных данных'),
            ),
          );
          setState(() => _saving = false);
          return;
        }
        final cubit = context.read<ProjectsCubit>();
        await cubit.submit(next);
        if (!mounted) return;
        setState(() {
          _draft = next.copyWith(status: RenovationProjectStatus.submitted);
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Заявка отправлена в OMA. Дом API. Дата работ не подтверждена автоматически.',
            ),
          ),
        );
        if (!mounted) return;
        context.go(AppRoutes.projectPath(next.id));
      } else {
        final cubit = context.read<ProjectsCubit>();
        await cubit.save(next);
        if (!mounted) return;
        setState(() {
          _draft = next;
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  bool _validateStep() {
    final d = _draft;
    if (d == null) return false;
    switch (_step) {
      case 0:
        return d.propertyKind != null;
      case 1:
        return d.scope != null;
      case 2:
        return _area.text.trim().isNotEmpty;
      case 3:
        return d.selectedRooms.isNotEmpty;
      case 5:
        return d.style != null;
      case 6:
        return d.budgetRange != null;
      case 7:
        return d.materialTier != null;
      case 8:
        return _address.text.trim().isNotEmpty &&
            _phone.text.trim().isNotEmpty &&
            d.consentPersonalData;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _area.dispose();
    _rooms.dispose();
    _styleNotes.dispose();
    _address.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OmaPage(
        header: OmaFlowHeader(title: 'Ремонт под ключ'),
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (_error != null || _draft == null) {
      return OmaPage(
        header: const OmaFlowHeader(title: 'Ремонт под ключ'),
        children: [
          Text(_error ?? 'Не удалось создать заявку',
              style: OmaType.regular(14, OmaColors.muted)),
          OmaButton(label: 'Назад', onPressed: () => omaBack(context)),
        ],
      );
    }

    final draft = _draft!;

    return OmaPage(
      header: const OmaFlowHeader(
        title: 'Ремонт под ключ',
        eyebrow: 'Заявка · предварительная оценка',
      ),
      actions: [
        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OmaButton(
                  label: 'Назад',
                  kind: OmaButtonKind.secondary,
                  onPressed: _saving
                      ? null
                      : () => setState(() => _step--),
                ),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OmaButton(
                label: _step == _totalSteps - 1
                    ? (_saving ? 'Отправка…' : 'Отправить заявку')
                    : 'Далее',
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_validateStep()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заполните обязательные поля шага'),
                            ),
                          );
                          return;
                        }
                        await _persist();
                        if (!mounted) return;
                        if (_step == _totalSteps - 1) {
                          await _persist(submit: true);
                        } else {
                          setState(() => _step++);
                        }
                      },
              ),
            ),
          ],
        ),
        OmaTextAction(
          label: 'Сохранить черновик и выйти',
          centered: true,
          onPressed: () async {
            await _persist();
            if (!context.mounted) return;
            context.go(AppRoutes.projects);
          },
        ),
      ],
      children: [
        OmaStepProgress(
          caption: _stepTitles[_step],
          stepLabel: 'Шаг ${_step + 1} из $_totalSteps',
          current: _step + 1,
          total: _totalSteps,
        ),
        ..._buildStep(draft),
      ],
    );
  }

  static const _stepTitles = [
    'Тип объекта',
    'Тип ремонта',
    'Параметры помещения',
    'Комнаты и работы',
    'Фото и план',
    'Стиль интерьера',
    'Бюджет и сроки',
    'Материалы и услуги',
    'Контакты',
    'Сводка',
  ];

  List<Widget> _buildStep(RenovationRequest draft) {
    switch (_step) {
      case 0:
        return [
          _optionCard(
            'Квартира',
            draft.propertyKind == RenovationPropertyKind.apartment,
            () => setState(
              () => _draft =
                  draft.copyWith(propertyKind: RenovationPropertyKind.apartment),
            ),
          ),
          _optionCard(
            'Частный дом',
            draft.propertyKind == RenovationPropertyKind.house,
            () => setState(
              () =>
                  _draft = draft.copyWith(propertyKind: RenovationPropertyKind.house),
            ),
          ),
          _optionCard(
            'Другое помещение',
            draft.propertyKind == RenovationPropertyKind.other,
            () => setState(
              () =>
                  _draft = draft.copyWith(propertyKind: RenovationPropertyKind.other),
            ),
          ),
        ];
      case 1:
        return [
          for (final e in [
            (RenovationScope.turnkey, 'Полный ремонт под ключ'),
            (RenovationScope.cosmetic, 'Косметический ремонт'),
            (RenovationScope.major, 'Капитальный ремонт'),
            (RenovationScope.newFinish, 'Отделка нового помещения'),
            (RenovationScope.consultation, 'Пока не знаю — нужна консультация'),
          ])
            _optionCard(
              e.$2,
              draft.scope == e.$1,
              () => setState(() => _draft = draft.copyWith(scope: e.$1)),
            ),
        ];
      case 2:
        return [
          TextField(
            controller: _area,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Общая площадь, м²',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
          TextField(
            controller: _rooms,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество комнат',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
          Text('Новостройка или вторичное', style: OmaType.medium(13, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in ['Новостройка', 'Вторичное жильё'])
                OmaChoiceChip(
                  label: v,
                  selected: draft.housingAge == v,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(housingAge: v)),
                ),
            ],
          ),
          Text('Текущее состояние', style: OmaType.medium(13, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in ['Жилое состояние', 'Требует ремонта', 'Черновая отделка'])
                OmaChoiceChip(
                  label: v,
                  selected: draft.condition == v,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(condition: v)),
                ),
            ],
          ),
          Text('Заселённость', style: OmaType.medium(13, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in ['Жилое', 'Пустующее'])
                OmaChoiceChip(
                  label: v,
                  selected: draft.occupancy == v,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(occupancy: v)),
                ),
            ],
          ),
        ];
      case 3:
        return [
          Text('Комнаты', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in RenovationRequest.roomOptions)
                OmaChoiceChip(
                  label: r,
                  selected: draft.selectedRooms.contains(r),
                  onTap: () {
                    final next = {...draft.selectedRooms};
                    if (!next.add(r)) next.remove(r);
                    setState(() => _draft = draft.copyWith(selectedRooms: next));
                  },
                ),
            ],
          ),
          Text('Категории работ', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in RenovationRequest.workOptions)
                OmaChoiceChip(
                  label: w,
                  selected: draft.workCategories.contains(w),
                  onTap: () {
                    final next = {...draft.workCategories};
                    if (!next.add(w)) next.remove(w);
                    setState(
                      () => _draft = draft.copyWith(workCategories: next),
                    );
                  },
                ),
            ],
          ),
        ];
      case 4:
        return [
          const OmaInfoNote(
            text:
                'Фото помогут подготовить предварительную оценку и рекомендации. Это не коммерческое предложение.',
          ),
          Text('Фото комнат', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in draft.photoAssets)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        a,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: OmaColors.blueSoft,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        iconSize: 18,
                        onPressed: () {
                          final next = [...draft.photoAssets]..remove(a);
                          setState(
                            () => _draft = draft.copyWith(photoAssets: next),
                          );
                        },
                        icon: const Icon(Icons.close, color: OmaColors.danger),
                      ),
                    ),
                  ],
                ),
              ActionChip(
                avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Добавить демо-фото'),
                onPressed: () {
                  final asset = draft.photoAssets.length.isEven
                      ? OmaImages.attachmentKitchen
                      : OmaImages.kitchen;
                  setState(
                    () => _draft = draft.copyWith(
                      photoAssets: [...draft.photoAssets, asset],
                    ),
                  );
                },
              ),
            ],
          ),
          Text('План помещения (опционально)', style: OmaType.bold(16, OmaColors.ink)),
          if (draft.floorPlanAsset != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(draft.floorPlanAsset!.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(
                  () => _draft = draft.copyWith(clearFloorPlan: true),
                ),
              ),
            )
          else
            OmaButton(
              label: 'Добавить демо-план',
              kind: OmaButtonKind.secondary,
              onPressed: () => setState(
                () => _draft =
                    draft.copyWith(floorPlanAsset: OmaImages.attachmentPlan),
              ),
            ),
        ];
      case 5:
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in [
                'Современный',
                'Минимализм',
                'Скандинавский',
                'Классический',
                'Лофт',
                'Другой стиль',
                'Пока не определился',
              ])
                OmaChoiceChip(
                  label: s,
                  selected: draft.style == s,
                  onTap: () => setState(() => _draft = draft.copyWith(style: s)),
                ),
            ],
          ),
          TextField(
            controller: _styleNotes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Пожелания (необязательно)',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
        ];
      case 6:
        return [
          Text('Бюджет', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in [
                'до 10 000 BYN',
                '10–25 000 BYN',
                '25–50 000 BYN',
                'от 50 000 BYN',
                'Пока не знаю',
              ])
                OmaChoiceChip(
                  label: b,
                  selected: draft.budgetRange == b,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(budgetRange: b)),
                ),
            ],
          ),
          Text('Срок начала', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in [
                'В ближайший месяц',
                'Через 1–3 месяца',
                'Через 3–6 месяцев',
              ])
                OmaChoiceChip(
                  label: t,
                  selected: draft.startDateIso == t,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(startDateIso: t)),
                ),
            ],
          ),
          Text('Желаемый срок работ', style: OmaType.bold(16, OmaColors.ink)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in ['до 1 месяца', '1–3 месяца', '3+ месяца'])
                OmaChoiceChip(
                  label: t,
                  selected: draft.timeline == t,
                  onTap: () =>
                      setState(() => _draft = draft.copyWith(timeline: t)),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Гибкий график'),
            value: draft.flexibleTimeline,
            activeThumbColor: OmaColors.blue,
            onChanged: (v) => setState(
              () => _draft = draft.copyWith(flexibleTimeline: v),
            ),
          ),
        ];
      case 7:
        return [
          for (final e in [
            (MaterialTier.standard, 'Стандарт', 'Базовые материалы OMA'),
            (MaterialTier.balanced, 'Оптимальный', 'Баланс цены и качества'),
            (MaterialTier.premium, 'Премиум', 'Расширенный ассортимент'),
          ])
            _optionCard(
              '${e.$2}\n${e.$3}',
              draft.materialTier == e.$1,
              () => setState(() => _draft = draft.copyWith(materialTier: e.$1)),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Материалы поставляет OMA'),
            value: draft.omaSuppliesMaterials,
            onChanged: (v) => setState(
              () => _draft = draft.copyWith(omaSuppliesMaterials: v),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Нужен монтаж'),
            value: draft.needInstallation,
            onChanged: (v) => setState(
              () => _draft = draft.copyWith(needInstallation: v),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Вывоз мусора'),
            value: draft.needWasteRemoval,
            onChanged: (v) => setState(
              () => _draft = draft.copyWith(needWasteRemoval: v),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Мебель'),
            value: draft.needFurniture,
            onChanged: (v) =>
                setState(() => _draft = draft.copyWith(needFurniture: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Освещение'),
            value: draft.needLighting,
            onChanged: (v) =>
                setState(() => _draft = draft.copyWith(needLighting: v)),
          ),
        ];
      case 8:
        return [
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Адрес объекта',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
          Text('Способ связи', style: OmaType.medium(13, OmaColors.ink)),
          Wrap(
            spacing: 8,
            children: [
              for (final m in ['Телефон', 'Telegram', 'Viber'])
                OmaChoiceChip(
                  label: m,
                  selected: draft.contactMethod == m,
                  onTap: () => setState(
                    () => _draft = draft.copyWith(contactMethod: m),
                  ),
                ),
            ],
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Имя',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              filled: true,
              fillColor: OmaColors.white,
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.consentPersonalData,
            onChanged: (v) => setState(
              () => _draft =
                  draft.copyWith(consentPersonalData: v ?? false),
            ),
            title: Text(
              'Согласие на обработку персональных данных',
              style: OmaType.regular(13, OmaColors.ink),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ];
      default:
        final collected = _collect(draft);
        return [
          const OmaBadge(label: 'Предварительная оценка', cream: true),
          Text(
            'Итоговая смета будет подготовлена после консультации. Цифры ниже не являются подтверждённым КП.',
            style: OmaType.regular(12, OmaColors.muted),
          ),
          OmaDataRow(
            label: 'Объект',
            value: switch (collected.propertyKind) {
              RenovationPropertyKind.apartment => 'Квартира',
              RenovationPropertyKind.house => 'Дом',
              RenovationPropertyKind.other => 'Другое',
              null => '—',
            },
          ),
          OmaDataRow(
            label: 'Площадь',
            value: collected.areaSqm == null
                ? '—'
                : '${collected.areaSqm} м²',
          ),
          OmaDataRow(
            label: 'Комнаты',
            value: collected.selectedRooms.isEmpty
                ? '—'
                : collected.selectedRooms.join(', '),
          ),
          OmaDataRow(label: 'Стиль', value: collected.style ?? '—'),
          OmaDataRow(label: 'Бюджет', value: collected.budgetRange ?? '—'),
          OmaDataRow(label: 'Адрес', value: collected.address ?? '—'),
          OmaDataRow(
            label: 'Фото',
            value: '${collected.photoAssets.length}',
          ),
          if (collected.areaSqm != null)
            OmaSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Предварительная оценка',
                    style: OmaType.semibold(14, OmaColors.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(collected.areaSqm! * 180).toStringAsFixed(0)}–${(collected.areaSqm! * 320).toStringAsFixed(0)} BYN',
                    style: OmaType.bold(20, OmaColors.ink),
                  ),
                  Text(
                    'Ориентир по площади · не подтверждённая смета',
                    style: OmaType.regular(11, OmaColors.muted),
                  ),
                ],
              ),
            ),
        ];
    }
  }

  Widget _optionCard(String label, bool selected, VoidCallback onTap) {
    return OmaSurfaceCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: selected
                  ? OmaType.semibold(14, OmaColors.blue)
                  : OmaType.medium(14, OmaColors.ink),
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? OmaColors.blue : OmaColors.hint,
          ),
        ],
      ),
    );
  }
}
