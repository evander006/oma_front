import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/features/onboarding/domain/onboarding_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class OnboardingDraft {
  const OnboardingDraft({
    required this.type,
    required this.name,
    this.area,
    this.rooms,
    this.tenure,
    this.skipped = false,
    this.photos = const [],
  });

  final PropertyType type;
  final String name;
  final double? area;
  final int? rooms;
  final PropertyTenure? tenure;
  final bool skipped;
  final List<OnboardingPhoto> photos;

  OnboardingDraft copyWith({
    PropertyType? type,
    String? name,
    double? area,
    int? rooms,
    PropertyTenure? tenure,
    bool? skipped,
    List<OnboardingPhoto>? photos,
  }) {
    return OnboardingDraft(
      type: type ?? this.type,
      name: name ?? this.name,
      area: area ?? this.area,
      rooms: rooms ?? this.rooms,
      tenure: tenure ?? this.tenure,
      skipped: skipped ?? this.skipped,
      photos: photos ?? this.photos,
    );
  }
}

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  String _selected = 'Кухня';

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'ОМА. Дом'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      actions: [
        OmaButton(
          label: 'Начать',
          onPressed: () => context.push(AppRoutes.onboardingHousing),
        ),
        OmaTextAction(
          label: 'Пропустить, заполнить позже',
          centered: true,
          onPressed: () => context.go(AppRoutes.profile),
        ),
      ],
      children: [
        Center(
          child: DomIconTile(icon: Icons.home_outlined, size: 64),
        ),
        Text(
          'Ваш дом — в одном месте',
          textAlign: TextAlign.center,
          style: OmaType.bold(22, OmaColors.black),
        ),
        Text(
          'Сохраните комнаты, подбирайте товары ОМА и планируйте изменения без лишних списков.',
          textAlign: TextAlign.center,
          style: OmaType.regular(14, OmaColors.muted),
        ),
        DomRoomGrid(
          rooms: const [
            'Гостиная',
            'Спальня',
            'Кухня',
            'Санузел',
            'Прихожая',
            'Коридор',
          ],
          selected: _selected,
          onSelect: (v) => setState(() => _selected = v),
        ),
        DomCard(
          child: Column(
            children: const [
              _Benefit(
                icon: Icons.grid_view_outlined,
                text: 'Планировка, фото и покупки по комнатам',
              ),
              SizedBox(height: 14),
              _Benefit(
                icon: Icons.forum_outlined,
                text: 'ИИ-подбор и примерка предметов',
              ),
              SizedBox(height: 14),
              _Benefit(
                icon: Icons.build_outlined,
                text: 'Услуги установки — отдельной заявкой',
              ),
            ],
          ),
        ),
        Text(
          'Расскажите о жилье за 3 шага. Любой шаг можно пропустить и заполнить позже в профиле.',
          textAlign: TextAlign.center,
          style: OmaType.regular(12, OmaColors.muted),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: OmaColors.blue),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: OmaType.regular(14, OmaColors.ink))),
      ],
    );
  }
}

class OnboardingHousingScreen extends StatefulWidget {
  const OnboardingHousingScreen({super.key});

  @override
  State<OnboardingHousingScreen> createState() =>
      _OnboardingHousingScreenState();
}

class _OnboardingHousingScreenState extends State<OnboardingHousingScreen> {
  PropertyType _type = PropertyType.apartment;
  PropertyTenure? _tenure;
  int _rooms = 2;
  final _area = TextEditingController(text: '56');

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  OnboardingDraft _draft() => OnboardingDraft(
        type: _type,
        name: switch (_type) {
          PropertyType.apartment => 'Моя квартира',
          PropertyType.house => 'Мой дом',
          PropertyType.dacha => 'Моя дача',
        },
        area: double.tryParse(_area.text.replaceAll(',', '.')),
        rooms: _rooms,
        tenure: _tenure,
      );

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'Настройка дома'),
      actions: [
        OmaButton(
          label: 'Далее: фото и планировка',
          onPressed: () =>
              context.push(AppRoutes.onboardingPhotos, extra: _draft()),
        ),
        OmaButton(
          label: 'Пропустить, заполнить позже',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.push(
            AppRoutes.onboardingPhotos,
            extra: _draft().copyWith(skipped: true),
          ),
        ),
      ],
      children: [
        const DomStepBar(step: 1, total: 3),
        Text('Какое у вас жильё?', style: OmaType.bold(20, OmaColors.black)),
        _HousingTypeCard(
          selected: _type == PropertyType.apartment,
          icon: Icons.apartment_outlined,
          title: 'Квартира',
          subtitle: 'Отдельная квартира в доме',
          onTap: () => setState(() => _type = PropertyType.apartment),
        ),
        _HousingTypeCard(
          selected: _type == PropertyType.house,
          icon: Icons.home_outlined,
          title: 'Дом',
          subtitle: 'Частный или загородный дом',
          onTap: () => setState(() => _type = PropertyType.house),
        ),
        _HousingTypeCard(
          selected: _type == PropertyType.dacha,
          icon: Icons.cottage_outlined,
          title: 'Дача',
          subtitle: 'Сезонное или загородное жильё',
          onTap: () => setState(() => _type = PropertyType.dacha),
        ),
        Text('Это жильё…', style: OmaType.medium(14, OmaColors.ink)),
        Row(
          children: [
            Expanded(
              child: OmaChoiceChip(
                label: 'Моё',
                selected: _tenure == PropertyTenure.owned,
                onTap: () => setState(() => _tenure = PropertyTenure.owned),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OmaChoiceChip(
                label: 'Арендую',
                selected: _tenure == PropertyTenure.rented,
                onTap: () => setState(() => _tenure = PropertyTenure.rented),
              ),
            ),
          ],
        ),
        DomLabeledField(
          label: 'Количество жилых комнат',
          child: OmaQuantity(
            label: '$_rooms',
            onMinus: () => setState(() => _rooms = (_rooms - 1).clamp(1, 10)),
            onPlus: () => setState(() => _rooms = (_rooms + 1).clamp(1, 10)),
          ),
        ),
        Text(
          'Считаем гостиную и спальни. Кухня, санузел и коридор — вспомогательные помещения.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        DomLabeledField(
          label: 'Площадь, м² · необязательно',
          child: DomTextBox(controller: _area, keyboard: TextInputType.number),
        ),
        const DomSoftNote(
          'Сведения можно изменить позже. Планировка не заменяет точные замеры.',
        ),
      ],
    );
  }
}

class _HousingTypeCard extends StatelessWidget {
  const _HousingTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DomCard(
      selected: selected,
      onTap: onTap,
      borderColor: selected ? OmaColors.blue : OmaColors.line,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? OmaColors.blue : OmaColors.muted,
          ),
          const SizedBox(width: 12),
          Icon(icon, color: OmaColors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OmaType.bold(15, OmaColors.black)),
                Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPhotosScreen extends StatefulWidget {
  const OnboardingPhotosScreen({super.key});

  @override
  State<OnboardingPhotosScreen> createState() => _OnboardingPhotosScreenState();
}

class _OnboardingPhotosScreenState extends State<OnboardingPhotosScreen> {
  final _picker = ImagePicker();
  final List<OnboardingPhoto> _photos = [];
  bool _initialized = false;
  bool _dragging = false;
  bool _reading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final draft = GoRouterState.of(context).extra as OnboardingDraft?;
    _photos.addAll(draft?.photos ?? const []);
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _choosePhotos() async {
    try {
      final files = await _picker.pickMultiImage();
      await _addPhotos(files);
    } catch (error) {
      _notify('Не удалось открыть выбор фотографий: $error');
    }
  }

  Future<void> _addPhotos(List<XFile> files) async {
    if (files.isEmpty || _reading) return;
    setState(() => _reading = true);
    final accepted = [..._photos];
    final errors = <String>[];
    for (final file in files) {
      if (accepted.length >= 5) {
        errors.add('Можно добавить не более 5 фотографий.');
        break;
      }
      try {
        final photo = await OnboardingPhoto.fromFile(file);
        if (accepted.any((item) => item.name == photo.name &&
            item.bytes.length == photo.bytes.length)) {
          continue;
        }
        accepted.add(photo);
      } on FormatException catch (error) {
        errors.add(error.message);
      } catch (error) {
        errors.add('Не удалось прочитать файл ${file.name}: $error');
      }
    }
    if (!mounted) return;
    setState(() {
      _photos
        ..clear()
        ..addAll(accepted);
      _reading = false;
      _dragging = false;
    });
    if (errors.isNotEmpty) _notify(errors.join(' '));
  }

  void _next({required bool skip}) {
    final draft = GoRouterState.of(context).extra as OnboardingDraft?;
    context.push(
      AppRoutes.onboardingNeeds,
      extra: draft?.copyWith(
        photos: skip ? const [] : List.unmodifiable(_photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'Настройка дома'),
      actions: [
        OmaButton(
          label: 'Далее: потребности',
          onPressed: _reading ? null : () => _next(skip: false),
        ),
        OmaButton(
          label: 'Пропустить этот шаг',
          kind: OmaButtonKind.secondary,
          onPressed: _reading ? null : () => _next(skip: true),
        ),
      ],
      children: [
        const DomStepBar(step: 2, total: 3),
        Text('Добавьте фотографии кухни',
            style: OmaType.bold(20, OmaColors.black)),
        Text(
          'Выберите реальные фотографии. Они появятся в паспорте кухни '
          'после завершения настройки жилья.',
          style: OmaType.regular(14, OmaColors.muted),
        ),
        for (var index = 0; index < _photos.length; index++)
          DomCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.memory(
                    _photos[index].bytes,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 155,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_photos[index].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OmaType.medium(14, OmaColors.ink)),
                            Text('Выбрано · будет сохранено после настройки',
                                style: OmaType.regular(12, OmaColors.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Удалить фотографию',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _photos.removeAt(index)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (details) {
            _addPhotos(details.files);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _dragging ? OmaColors.blueSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DomDashedUpload(
              title: _reading
                  ? 'Читаем файлы…'
                  : _dragging
                      ? 'Отпустите фотографии здесь'
                      : '+ Добавить фотографии',
              subtitle: 'Нажмите или перетащите JPG, PNG, WEBP · до 8 МБ · максимум 5',
              onTap: _reading ? null : _choosePhotos,
            ),
          ),
        ),
        if (_photos.isEmpty)
          const DomSoftNote(
            'Фотографий ещё нет. Можно пропустить этот шаг; '
            'пример кухни больше не выдаётся за загруженный файл.',
          ),
        const DomSoftNote(
          'PDF-планировка пока не поддерживается сервером. '
          'Сейчас загружаются только фотографии; комнаты можно '
          'настроить вручную.',
        ),
      ],
    );
  }
}

class OnboardingNeedsScreen extends StatefulWidget {
  const OnboardingNeedsScreen({super.key});

  @override
  State<OnboardingNeedsScreen> createState() => _OnboardingNeedsScreenState();
}

class _OnboardingNeedsScreenState extends State<OnboardingNeedsScreen> {
  final _selected = <String>{'Обновить кухню', 'Организовать хранение'};
  final _budget = TextEditingController(text: 'До 1 000 р.');
  String _priority = 'Практичность и простой уход';

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool draftOnly}) async {
    final draft = GoRouterState.of(context).extra as OnboardingDraft?;
    final cubit = context.read<PropertiesCubit>();
    if (draftOnly || draft?.skipped == true) {
      await cubit.addDraft(
        name: draft?.name ?? 'Дом за городом',
        type: draft?.type ?? PropertyType.house,
        tenure: draft?.tenure,
      );
      if (!mounted) return;
      context.go(AppRoutes.onboardingDraft);
      return;
    }
    // Create the real property/rooms first; the room photo API needs a room ID.
    final property = await cubit.addFromOnboarding(
      name: draft?.name ?? 'Моя квартира',
      type: draft?.type ?? PropertyType.apartment,
      areaSqm: draft?.area,
      livingRooms: draft?.rooms,
      budgetByn: 1000,
      goal: _selected.join(', '),
      tenure: draft?.tenure,
    );
    if (!mounted) return;

    String? photoWarning;
    final photos = draft?.photos ?? const <OnboardingPhoto>[];
    if (photos.isNotEmpty) {
      if (ApiConfig.useMock) {
        photoWarning = 'В автономном демо-режиме фото доступны только '
            'для предпросмотра; загрузка на сервер отключена.';
      } else {
        try {
          final kitchen = property.rooms.where((room) => room.kind == 'kitchen');
          if (kitchen.isEmpty) {
            throw StateError('Не найдена комната «Кухня»');
          }
          final roomId = kitchen.first.id;
          final dio = context.read<DioClient>().dio;
          for (final photo in photos) {
            await dio.post<dynamic>(
              '${ApiConfig.apiPrefix}/rooms/$roomId/photos',
              data: FormData.fromMap({
                'file': MultipartFile.fromBytes(
                  photo.bytes,
                  filename: photo.name,
                  contentType: DioMediaType.parse(photo.mimeType),
                ),
              }),
              options: Options(contentType: 'multipart/form-data'),
            );
          }
          await cubit.load();
        } catch (error) {
          photoWarning = 'Жильё создано, но не все фотографии '
              'загрузились на сервер: $error';
        }
      }
    }
    if (!mounted) return;
    if (photoWarning != null) {
      // Show the warning before navigating: this widget is then disposed.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(photoWarning)),
      );
    }
    context.go(AppRoutes.myHome);
  }

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Обновить кухню', 'Сантехника, освещение и хранение'),
      ('Организовать хранение', 'Полки, системы и органайзеры'),
      ('Обустроить другие комнаты', 'Гостиная, спальня и вспомогательные'),
    ];

    return OmaPage(
      header: const OmaDomHeader(title: 'Настройка дома'),
      actions: [
        OmaButton(
          label: 'Завершить настройку',
          onPressed: () => _finish(draftOnly: false),
        ),
        OmaButton(
          label: 'Заполнить позже',
          kind: OmaButtonKind.secondary,
          onPressed: () => _finish(draftOnly: true),
        ),
      ],
      children: [
        const DomStepBar(step: 3, total: 3),
        Text('Что хотите изменить?', style: OmaType.bold(20, OmaColors.black)),
        Text(
          'Можно выбрать несколько задач',
          style: OmaType.regular(14, OmaColors.muted),
        ),
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: DomCard(
              selected: _selected.contains(o.$1),
              onTap: () => setState(() {
                if (_selected.contains(o.$1)) {
                  _selected.remove(o.$1);
                } else {
                  _selected.add(o.$1);
                }
              }),
              child: Row(
                children: [
                  Icon(
                    _selected.contains(o.$1)
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _selected.contains(o.$1)
                        ? OmaColors.blue
                        : OmaColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$1, style: OmaType.bold(15, OmaColors.black)),
                        Text(o.$2, style: OmaType.regular(12, OmaColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        DomLabeledField(
          label: 'Приоритет',
          child: DomTextBox(
            controller: TextEditingController(text: _priority),
            readOnly: true,
            suffix: const Icon(Icons.expand_more, color: OmaColors.muted),
            onTap: () async {
              final v = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in [
                        'Практичность и простой уход',
                        'Дизайн и стиль',
                        'Бюджет',
                      ])
                        ListTile(
                          title: Text(p),
                          onTap: () => Navigator.pop(ctx, p),
                        ),
                    ],
                  ),
                ),
              );
              if (v != null) setState(() => _priority = v);
            },
          ),
        ),
        DomLabeledField(
          label: 'Личный план расходов, BYN · необязательно',
          child: DomTextBox(controller: _budget),
        ),
        const DomSoftNote(
          'Это ориентир для подбора, не смета услуг. Цены и наличие уточняются отдельно.',
        ),
      ],
    );
  }
}

class OnboardingDraftDoneScreen extends StatelessWidget {
  const OnboardingDraftDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'ОМА. Дом'),
      actions: [
        OmaButton(
          label: 'Продолжить настройку',
          onPressed: () => context.push(AppRoutes.onboardingHousing),
        ),
        OmaButton(
          label: 'Перейти к моим объектам',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.go(AppRoutes.myHome),
        ),
        OmaTextAction(
          label: 'Вернуться в профиль',
          centered: true,
          onPressed: () => context.go(AppRoutes.profile),
        ),
      ],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: OmaColors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ),
        Text(
          'Можно продолжить позже',
          style: OmaType.bold(22, OmaColors.black),
        ),
        Text(
          'Создали черновик объекта. Он будет доступен в разделе «Мой дом» в профиле.',
          style: OmaType.regular(14, OmaColors.muted),
        ),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DomPill('Черновик'),
              const SizedBox(height: 10),
              Text('Дом за городом', style: OmaType.bold(16, OmaColors.black)),
              Text(
                'Рабочее название · можно изменить',
                style: OmaType.regular(12, OmaColors.muted),
              ),
              const Divider(height: 24),
              _DraftRow(
                title: 'Сведения о жилье',
                subtitle: 'Тип, площадь и комнаты не указаны',
                onTap: () => context.push(AppRoutes.onboardingHousing),
              ),
              const Divider(height: 24),
              _DraftRow(
                title: 'Фото и планировка',
                subtitle: 'Не добавлены',
                onTap: () => context.push(AppRoutes.onboardingPhotos),
              ),
              const Divider(height: 24),
              _DraftRow(
                title: 'Потребности и бюджет',
                subtitle: 'Не заполнены',
                onTap: () => context.push(AppRoutes.onboardingNeeds),
              ),
            ],
          ),
        ),
        const DomSoftNote(
          'В черновике нет проверенных сведений о жилье. Добавляйте данные, когда будет удобно.',
        ),
      ],
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
                Text(title, style: OmaType.medium(14, OmaColors.ink)),
                Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: OmaColors.muted),
        ],
      ),
    );
  }
}
