import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';
import 'package:uuid/uuid.dart';

class MyHomeListScreen extends StatelessWidget {
  const MyHomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertiesCubit>().state.properties;

    return OmaPage(
      header: const OmaDomHeader(title: 'Мои объекты'),
      children: [
        Text('Ваши объекты', style: OmaType.bold(22, OmaColors.black)),
        Text(
          'Выберите жильё, чтобы открыть комнаты, покупки и паспорт дома.',
          style: OmaType.regular(14, OmaColors.muted),
        ),
        if (props.isEmpty)
          OmaButton(
            label: '+ Добавить объект',
            onPressed: () => context.push(AppRoutes.onboarding),
          )
        else
          for (final p in props) ...[
            _PropertyCard(property: p),
          ],
        if (props.isNotEmpty)
          OmaButton(
            label: '+ Добавить объект',
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
        const DomSoftNote(
          'Покупки и задачи сохраняются отдельно для каждого объекта.',
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final isDraft = property.isDraft;
    return DomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DomIconTile(
                icon: property.type == PropertyType.house
                    ? Icons.home_outlined
                    : Icons.apartment_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name, style: OmaType.bold(16, OmaColors.black)),
                    const SizedBox(height: 6),
                    DomPill(
                      isDraft
                          ? 'Черновик'
                          : property.selected
                              ? 'Выбранный объект'
                              : 'Объект',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDraft
                          ? 'Адрес и сведения ещё не указаны'
                          : (property.address ?? 'Адрес не указан'),
                      style: OmaType.regular(13, OmaColors.ink),
                    ),
                    if (!isDraft &&
                        (property.areaSqm != null ||
                            property.livingRooms != null))
                      Text(
                        [
                          if (property.areaSqm != null)
                            '${property.areaSqm!.toStringAsFixed(0)} м²',
                          if (property.livingRooms != null)
                            '${property.livingRooms} жилые комнаты',
                        ].join(' · '),
                        style: OmaType.regular(12, OmaColors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isDraft)
            OmaButton(
              label: 'Продолжить заполнение',
              kind: OmaButtonKind.secondary,
              onPressed: () =>
                  context.push(AppRoutes.propertyEditPath(property.id)),
            )
          else ...[
            OmaButton(
              label: 'Выбрать объект',
              onPressed: () async {
                await context.read<PropertiesCubit>().select(property.id);
                if (!context.mounted) return;
                context.push(AppRoutes.propertyPath(property.id));
              },
            ),
            const SizedBox(height: 10),
            OmaButton(
              label: 'Редактировать объект',
              kind: OmaButtonKind.secondary,
              onPressed: () =>
                  context.push(AppRoutes.propertyEditPath(property.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final property = _find(context, propertyId);
    if (property == null) {
      return OmaPage(
        header: const OmaDomHeader(title: 'Объект'),
        children: [
          Text('Не найден', style: OmaType.regular(14, OmaColors.muted)),
        ],
      );
    }

    Room? kitchen;
    for (final r in property.rooms) {
      if (r.kind == 'kitchen') kitchen = r;
    }
    kitchen ??= property.rooms.isEmpty ? null : property.rooms.first;

    return OmaPage(
      header: const OmaDomHeader(title: 'Паспорт дома'),
      children: [
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_outlined, color: OmaColors.blue),
                  const SizedBox(width: 8),
                  Text('Паспорт дома', style: OmaType.bold(16, OmaColors.black)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  property.name,
                  if (property.address != null)
                    property.address!.split(',').first.trim(),
                  if (property.areaSqm != null)
                    '${property.areaSqm!.toStringAsFixed(0)} м²',
                ].join(' · '),
                style: OmaType.regular(13, OmaColors.muted),
              ),
              const SizedBox(height: 12),
              OmaButton(
                label: 'Открыть паспорт дома',
                kind: OmaButtonKind.secondary,
                onPressed: () =>
                    context.push(AppRoutes.propertyLayoutPath(property.id)),
              ),
            ],
          ),
        ),
        _SectionTitle('Задачи и проекты'),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkRow(
                title: 'Установить смеситель на кухне',
                subtitle: 'План: 24.10 · бюджет 250 р.',
                onTap: () {
                  if (kitchen != null) {
                    context.push(AppRoutes.roomPath(property.id, kitchen.id));
                  }
                },
              ),
              const SizedBox(height: 12),
              OmaButton(
                label: '+ Добавить задачу / проект',
                kind: OmaButtonKind.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
        _SectionTitle('Оборудование'),
        DomCard(
          child: Column(
            children: [
              _LinkRow(
                title: 'Смеситель Ledeme L4399U-12',
                subtitle: 'Кухня · установка запланирована',
                onTap: () => context.push(AppRoutes.productPath('p1')),
              ),
              const SizedBox(height: 12),
              OmaButton(
                label: '+ Добавить оборудование',
                kind: OmaButtonKind.secondary,
                onPressed: () => context.go(AppRoutes.catalog),
              ),
            ],
          ),
        ),
        _SectionTitle('Напоминания'),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Проверить документы на смеситель',
                style: OmaType.medium(14, OmaColors.ink),
              ),
              Text(
                '22.10, 15:00 · без уведомления',
                style: OmaType.regular(12, OmaColors.muted),
              ),
              const SizedBox(height: 8),
              OmaTextAction(label: 'Изменить напоминания', onPressed: () {}),
            ],
          ),
        ),
        _SectionTitle('Планировка и комнаты'),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Планировка', style: OmaType.bold(15, OmaColors.black)),
                  ),
                  OmaTextAction(
                    label: 'Редактировать',
                    onPressed: () =>
                        context.push(AppRoutes.propertyLayoutPath(property.id)),
                  ),
                ],
              ),
              if (property.address != null)
                Text(property.address!, style: OmaType.regular(12, OmaColors.muted)),
              const SizedBox(height: 10),
              DomRoomGrid(
                rooms: property.rooms.map((r) => r.name).toList(),
                selected: kitchen?.name ??
                    (property.rooms.isNotEmpty ? property.rooms.first.name : ''),
              ),
              const SizedBox(height: 8),
              Text(
                'Упрощённая схема помещений. Размеры не подтверждены.',
                style: OmaType.regular(11, OmaColors.muted),
              ),
            ],
          ),
        ),
        DomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < property.rooms.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: OmaColors.line),
                _RoomListTile(
                  room: property.rooms[i],
                  onTap: () => context.push(
                    AppRoutes.roomPath(property.id, property.rooms[i].id),
                  ),
                ),
              ],
            ],
          ),
        ),
        OmaTextAction(
          label: '+ Добавить комнату',
          onPressed: () =>
              context.push(AppRoutes.propertyLayoutPath(property.id)),
        ),
        if (kitchen case final kitchenRoom?) ...[
          _SectionTitle('ИИ-подбор для комнаты'),
          DomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Кухня', style: OmaType.bold(15, OmaColors.black)),
                    const SizedBox(width: 8),
                    const DomPill('ИИ'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Подскажем освещение и хранение с учётом добавленного смесителя.',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
                const SizedBox(height: 12),
                OmaButton(
                  label: 'Открыть ИИ-подбор',
                  onPressed: () => context.push(
                    AppRoutes.roomAiPath(property.id, kitchenRoom.id),
                  ),
                ),
              ],
            ),
          ),
          _SectionTitle('Покупки и недостающее'),
          DomCard(
            child: Column(
              children: [
                _LinkRow(
                  title: 'Смеситель Ledeme L4399U-12',
                  subtitle: 'Заказ № 261020-014',
                  onTap: () => context.push(
                    AppRoutes.roomPurchasesPath(property.id, kitchenRoom.id),
                  ),
                ),
                const Divider(height: 20),
                _LinkRow(
                  title: 'Установка смесителя',
                  subtitle: 'На согласовании',
                  onTap: () => context.push(AppRoutes.installPath('p1')),
                ),
              ],
            ),
          ),
          DomCard(
            child: Column(
              children: [
                _LinkRow(
                  title: 'Освещение для кухни',
                  subtitle: 'Рекомендуется выбрать вместе со смесителем',
                  onTap: () => context.push(
                    AppRoutes.roomMissingPath(property.id, kitchenRoom.id),
                  ),
                ),
                const Divider(height: 20),
                _LinkRow(
                  title: 'Фото кухни после установки',
                  subtitle: 'Не добавлено',
                  onTap: () => context.push(
                    AppRoutes.roomEditPath(property.id, kitchenRoom.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PropertyLayoutScreen extends StatelessWidget {
  const PropertyLayoutScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final property = _find(context, propertyId);
    if (property == null) {
      return const OmaPage(
        header: OmaDomHeader(title: 'Планировка и комнаты'),
        children: [Text('Не найден')],
      );
    }
    final living = property.rooms
        .where((r) => r.kind == 'living' || r.kind == 'bedroom')
        .toList();
    final aux = property.rooms
        .where((r) => r.kind != 'living' && r.kind != 'bedroom')
        .toList();
    final kitchen = property.rooms.where((r) => r.kind == 'kitchen').firstOrNull;

    return OmaPage(
      header: const OmaDomHeader(title: 'Планировка и комнаты'),
      actions: [
        OmaButton(
          label: '+ Добавить комнату',
          onPressed: () async {
            final id = const Uuid().v4();
            await context.read<PropertiesCubit>().addRoom(
                  propertyId,
                  Room(id: id, name: 'Новая комната', kind: 'other'),
                );
            if (!context.mounted) return;
            context.push(AppRoutes.roomEditPath(propertyId, id));
          },
        ),
        OmaButton(
          label: '+ Добавить фото помещения',
          kind: OmaButtonKind.secondary,
          onPressed: () {
            if (kitchen != null) {
              context.push(AppRoutes.roomEditPath(propertyId, kitchen.id));
            }
          },
        ),
      ],
      children: [
        Text(property.name, style: OmaType.bold(22, OmaColors.black)),
        Text(
          [
            if (property.areaSqm != null)
              '${property.areaSqm!.toStringAsFixed(0)} м²',
            if (property.livingRooms != null)
              '${property.livingRooms} жилые комнаты',
          ].join(' · '),
          style: OmaType.regular(14, OmaColors.muted),
        ),
        DomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DomRoomGrid(
                rooms: property.rooms.map((r) => r.name).toList(),
                selected: kitchen?.name ?? '',
                onSelect: (name) {
                  final room = property.rooms.firstWhere((r) => r.name == name);
                  context.push(AppRoutes.roomPath(propertyId, room.id));
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Условная схема, не обмерный план. Размеры помещений не подтверждены.',
                style: OmaType.regular(11, OmaColors.muted),
              ),
              const SizedBox(height: 12),
              OmaButton(
                label: 'Редактировать планировку',
                kind: OmaButtonKind.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
        if (living.isNotEmpty) ...[
          _SectionTitle('Жилые комнаты'),
          DomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < living.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _LayoutRoomRow(
                    room: living[i],
                    icon: living[i].kind == 'bedroom'
                        ? Icons.bed_outlined
                        : Icons.weekend_outlined,
                    onTap: () =>
                        context.push(AppRoutes.roomPath(propertyId, living[i].id)),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (aux.isNotEmpty) ...[
          _SectionTitle('Вспомогательные помещения'),
          DomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < aux.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _LayoutRoomRow(
                    room: aux[i],
                    icon: _auxIcon(aux[i].kind),
                    onTap: () =>
                        context.push(AppRoutes.roomPath(propertyId, aux[i].id)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _auxIcon(String kind) {
    return switch (kind) {
      'kitchen' => Icons.soup_kitchen_outlined,
      'bathroom' => Icons.bathtub_outlined,
      'entry' => Icons.door_front_door_outlined,
      _ => Icons.swap_horiz,
    };
  }
}

class PropertyEditScreen extends StatefulWidget {
  const PropertyEditScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  State<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends State<PropertyEditScreen> {
  final _name = TextEditingController(text: 'Дом за городом');
  final _rooms = TextEditingController(text: 'Указать количество');
  final _area = TextEditingController(text: 'Не указана');
  final _address = TextEditingController(text: 'Добавить позже');
  PropertyType _type = PropertyType.house;
  Property? _original;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    Property? p;
    for (final item in context.read<PropertiesCubit>().state.properties) {
      if (item.id == widget.propertyId) p = item;
    }
    _original = p;
    if (p != null) {
      _name.text = p.name;
      _rooms.text = p.livingRooms?.toString() ?? 'Указать количество';
      _area.text = p.areaSqm?.toStringAsFixed(0) ?? 'Не указана';
      _address.text = p.address ?? 'Добавить позже';
      _type = p.type;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _rooms.dispose();
    _area.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: const OmaDomHeader(title: 'Объект жилья'),
      actions: [
        OmaButton(
          label: 'Сохранить объект',
          onPressed: () async {
            final base = _original;
            final updated = (base ??
                    Property(
                      id: widget.propertyId,
                      name: _name.text,
                      type: _type,
                      rooms: const [],
                    ))
                .copyWith(
              name: _name.text.trim().isEmpty ? 'Объект' : _name.text.trim(),
              type: _type,
              livingRooms: int.tryParse(_rooms.text),
              areaSqm: double.tryParse(_area.text.replaceAll(',', '.')),
              address: _address.text == 'Добавить позже'
                  ? null
                  : _address.text.trim(),
              isDraft: false,
            );
            await context.read<PropertiesCubit>().upsert(updated);
            if (!context.mounted) return;
            context.pop();
          },
        ),
        OmaButton(
          label: 'Отмена',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        Text('Сведения об объекте', style: OmaType.bold(22, OmaColors.black)),
        DomLabeledField(
          label: 'Название объекта',
          child: DomTextBox(controller: _name),
        ),
        Row(
          children: [
            Expanded(
              child: _TypeToggle(
                label: 'Квартира',
                selected: _type == PropertyType.apartment,
                onTap: () => setState(() => _type = PropertyType.apartment),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeToggle(
                label: 'Дом',
                selected: _type == PropertyType.house,
                onTap: () => setState(() => _type = PropertyType.house),
              ),
            ),
          ],
        ),
        DomLabeledField(
          label: 'Жилые комнаты · необязательно',
          child: DomTextBox(controller: _rooms, keyboard: TextInputType.number),
        ),
        DomLabeledField(
          label: 'Площадь, м² · необязательно',
          child: DomTextBox(controller: _area, keyboard: TextInputType.number),
        ),
        DomLabeledField(
          label: 'Адрес · необязательно',
          child: DomTextBox(controller: _address),
        ),
        DomDashedUpload(
          title: 'Добавить фото или планировку',
          onTap: () {},
        ),
        Text(
          'Пока нет вложений. Планировку и фотографии можно добавить после сохранения.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        const DomSoftNote(
          'Сохраняется только введённая информация. Для редактирования существующего объекта поля заполняются его данными.',
        ),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DomCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? OmaColors.blue : OmaColors.muted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: OmaType.medium(
              14,
              selected ? OmaColors.blue : OmaColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: OmaType.bold(16, OmaColors.black));
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
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

class _RoomListTile extends StatelessWidget {
  const _RoomListTile({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final purchases = room.items.length;
    return ListTile(
      onTap: onTap,
      title: Text(room.name, style: OmaType.medium(14, OmaColors.ink)),
      subtitle: Text(
        purchases > 0
            ? 'Фото: ${room.photoPaths.length} · покупки: $purchases'
                '${room.kind == 'kitchen' ? ' · смеситель' : ''}'
            : 'Фото: ${room.photoPaths.length} · покупки: 0',
        style: OmaType.regular(12, OmaColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right, color: OmaColors.muted),
    );
  }
}

class _LayoutRoomRow extends StatelessWidget {
  const _LayoutRoomRow({
    required this.room,
    required this.icon,
    required this.onTap,
  });

  final Room room;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = room.items.isNotEmpty
        ? '${room.items.length} покупка · смеситель'
        : 'Фото не добавлены';
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: OmaColors.blue),
      title: Text(room.name, style: OmaType.medium(14, OmaColors.ink)),
      subtitle: Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
      trailing: const Icon(Icons.chevron_right, color: OmaColors.muted),
    );
  }
}

Property? _find(BuildContext context, String id) {
  for (final p in context.watch<PropertiesCubit>().state.properties) {
    if (p.id == id) return p;
  }
  return null;
}
