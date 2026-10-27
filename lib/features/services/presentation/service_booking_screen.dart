import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/services_repository.dart';
import 'package:oma/shared/models/home_service.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';
import 'package:oma/widgets/oma_icon.dart';

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  int _step = 0;
  HomeService? _service;
  String? _room;
  final _volume = TextEditingController();
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _date;
  final _photos = <String>[];
  String? _requestId;
  var _submitting = false;

  static const _rooms = [
    'Кухня',
    'Гостиная',
    'Спальня',
    'Санузел',
    'Прихожая',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s =
        await context.read<ServicesRepository>().byId(widget.serviceId);
    if (!mounted) return;
    setState(() => _service = s);
  }

  @override
  void dispose() {
    _volume.dispose();
    _address.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final service = _service;
    if (service == null) return;
    setState(() => _submitting = true);
    try {
      final id = await context.read<ServicesRepository>().submitBooking(
            ServiceBookingDraft(
              serviceId: service.id,
              roomLabel: _room,
              volumeHint: _volume.text.trim(),
              photoAssets: _photos,
              address: _address.text.trim(),
              preferredDate: _date,
              contactName: _name.text.trim(),
              contactPhone: _phone.text.trim(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _requestId = id;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) {
      return const OmaPage(
        header: OmaFlowHeader(title: 'Услуга'),
        children: [Center(child: CircularProgressIndicator())],
      );
    }

    if (_requestId != null) {
      return OmaPage(
        header: OmaFlowHeader(title: service.title),
        actions: [
          OmaButton(
            label: 'К услугам',
            onPressed: () => context.go(AppRoutes.services),
          ),
        ],
        children: [
          const Icon(Icons.check_circle_outline, size: 56, color: OmaColors.green),
          Text(
            'Заявка принята',
            textAlign: TextAlign.center,
            style: OmaType.bold(20, OmaColors.ink),
          ),
          Text(
            'Номер $_requestId\n${service.hasVerifiedPrice ? service.priceLabel : 'Стоимость уточняется'}',
            textAlign: TextAlign.center,
            style: OmaType.regular(13, OmaColors.muted),
          ),
        ],
      );
    }

    return OmaPage(
      header: OmaFlowHeader(title: service.title),
      actions: [
        if (_step > 0)
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: () => setState(() => _step--),
          ),
        OmaButton(
          label: _step == 3
              ? (_submitting ? 'Отправка…' : 'Отправить заявку')
              : 'Далее',
          onPressed: _submitting
              ? null
              : () {
                  if (_step == 0 && _room == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите комнату')),
                    );
                    return;
                  }
                  if (_step == 2 &&
                      (_address.text.trim().isEmpty ||
                          _phone.text.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Укажите адрес и телефон'),
                      ),
                    );
                    return;
                  }
                  if (_step == 3) {
                    _submit();
                  } else {
                    setState(() => _step++);
                  }
                },
        ),
      ],
      children: [
        OmaStepProgress(
          caption: 'Заявка на услугу',
          stepLabel: 'Шаг ${_step + 1} из 4',
          current: _step + 1,
          total: 4,
        ),
        Text(service.priceLabel, style: OmaType.semibold(14, OmaColors.blue)),
        if (service.description != null)
          Text(service.description!, style: OmaType.regular(13, OmaColors.muted)),
        ...switch (_step) {
          0 => [
              Text('Комната', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _rooms)
                    OmaChoiceChip(
                      label: r,
                      selected: _room == r,
                      onTap: () => setState(() => _room = r),
                    ),
                ],
              ),
              TextField(
                controller: _volume,
                decoration: InputDecoration(
                  labelText: 'Объём работ',
                  hintText: service.unitHint ?? 'Опишите объём',
                  filled: true,
                  fillColor: OmaColors.white,
                ),
              ),
            ],
          1 => [
              Text('Фото помещения', style: OmaType.bold(16, OmaColors.ink)),
              const OmaInfoNote(
                text:
                    'Фото используются для предварительной оценки. Реальная загрузка на сервер подключится с API.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _photos)
                    Chip(
                      label: Text(a.split('/').last),
                      onDeleted: () => setState(() => _photos.remove(a)),
                    ),
                  ActionChip(
                    avatar: const OmaIcon(OmaIcons.paperclip, size: 16),
                    label: const Text('Добавить демо-фото'),
                    onPressed: () {
                      setState(() {
                        _photos.add(
                          _photos.length.isEven
                              ? OmaImages.attachmentKitchen
                              : OmaImages.kitchen,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          2 => [
              Text('Адрес и контакты', style: OmaType.bold(16, OmaColors.ink)),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  filled: true,
                  fillColor: OmaColors.white,
                ),
              ),
              Text('Дата', style: OmaType.medium(13, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in [
                    'Ближайшие 3 дня',
                    'На этой неделе',
                    'Гибко',
                  ])
                    OmaChoiceChip(
                      label: d,
                      selected: _date == d,
                      onTap: () => setState(() => _date = d),
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
            ],
          _ => [
              Text('Сводка', style: OmaType.bold(16, OmaColors.ink)),
              OmaDataRow(label: 'Услуга', value: service.title),
              OmaDataRow(label: 'Комната', value: _room ?? '—'),
              OmaDataRow(
                label: 'Объём',
                value: _volume.text.trim().isEmpty ? '—' : _volume.text,
              ),
              OmaDataRow(label: 'Фото', value: '${_photos.length}'),
              OmaDataRow(label: 'Адрес', value: _address.text),
              OmaDataRow(label: 'Дата', value: _date ?? '—'),
              OmaDataRow(
                label: 'Стоимость',
                value: service.hasVerifiedPrice
                    ? service.priceLabel
                    : 'Стоимость уточняется',
              ),
              if (service.relatedCategoryIds.isNotEmpty)
                OmaButton(
                  label: 'Смотреть материалы в каталоге',
                  kind: OmaButtonKind.secondary,
                  onPressed: () => context.go(AppRoutes.catalog),
                ),
            ],
        },
      ],
    );
  }
}
