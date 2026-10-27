import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final pair = _resolve(context, propertyId, roomId);
    if (pair == null) {
      return const OmaPage(
        header: OmaDomHeader(title: 'Комната'),
        children: [Text('Не найдена')],
      );
    }
    final property = pair.$1;
    final room = pair.$2;
    final productFuture = room.items.isEmpty
        ? Future<Product?>.value(null)
        : context
            .read<CatalogRepository>()
            .byId(room.items.first.productId);
    final photo = room.photoPaths.isNotEmpty
        ? room.photoPaths.first
        : OmaImages.kitchen;

    return OmaPage(
      header: OmaDomHeader(title: room.name),
      children: [
        DomBreadcrumb('${property.name} / ${room.name}'),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _roomImage(
            photo,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Text(
          'Иллюстрация кухни · личные фото пока не добавлены',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        OmaButton(
          label: 'Редактировать / добавить фото',
          kind: OmaButtonKind.secondary,
          onPressed: () =>
              context.push(AppRoutes.roomEditPath(propertyId, roomId)),
        ),
        if (_roomFacts(room).isNotEmpty)
          DomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Характеристики помещения', style: OmaType.bold(15, OmaColors.ink)),
                const SizedBox(height: 8),
                for (final fact in _roomFacts(room))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(fact.$1, style: OmaType.regular(12, OmaColors.muted))),
                        Text(fact.$2, style: OmaType.medium(12, OmaColors.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OmaButton(
                label: 'ИИ-подбор',
                onPressed: () =>
                    context.push(AppRoutes.roomAiPath(propertyId, roomId)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmaButton(
                label: 'Посмотреть помещение',
                kind: OmaButtonKind.secondary,
                onPressed: () =>
                    context.push(AppRoutes.room3dPath(propertyId, roomId)),
              ),
            ),
          ],
        ),
        Text(
          'В комнате · ${room.items.length} покупка',
          style: OmaType.bold(16, OmaColors.black),
        ),
        FutureBuilder<Product?>(
          future: productFuture,
          builder: (context, snap) {
            final product = snap.data;
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (product == null) {
              return Text(
                room.items.isEmpty
                    ? 'Пока нет добавленных товаров'
                    : 'Товар из комнаты не найден в каталоге API',
                style: OmaType.regular(13, OmaColors.muted),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DomProductRow(
                        imageAsset: product.imageUrl ?? product.imageAsset,
                        title: product.name,
                        price: product.priceLabel,
                        status:
                            'Куплен · ${room.items.first.qty} шт. · ${product.currency}',
                      ),
                      DomInstallBlock(
                        actionLabel: 'Что входит в услугу?',
                        linkStyle: true,
                        onAction: () =>
                            context.push(AppRoutes.installPath(product.id)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Товар привязан к комнате. Данные заказа появятся после подтверждённой покупки.',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
                const SizedBox(height: 8),
                DomCard(
                  onTap: () =>
                      context.push(AppRoutes.installPath(product.id)),
                  child: Row(
                    children: [
                      const Icon(Icons.build_outlined, color: OmaColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Услуги установки',
                              style: OmaType.medium(14, OmaColors.ink),
                            ),
                            Text(
                              'Посмотреть состав услуги и оставить заявку',
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
          },
        ),
        Text('Планы для кухни', style: OmaType.bold(16, OmaColors.black)),
        DomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Покупки комнаты',
                  style: OmaType.medium(14, OmaColors.ink),
                ),
                subtitle: Text(
                  '${room.items.length} товар · установка отдельно',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right, color: OmaColors.muted),
                onTap: () => context.push(
                  AppRoutes.roomPurchasesPath(propertyId, roomId),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  'Недостающие предметы',
                  style: OmaType.medium(14, OmaColors.ink),
                ),
                subtitle: Text(
                  'Свет и хранение — запланированы',
                  style: OmaType.regular(12, OmaColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right, color: OmaColors.muted),
                onTap: () => context.push(
                  AppRoutes.roomMissingPath(propertyId, roomId),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Смеситель уже куплен. Повторно добавлять его в корзину не нужно.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        OmaButton(
          label: 'Предложения по заполнению',
          onPressed: () =>
              context.push(AppRoutes.roomSuggestionsPath(propertyId, roomId)),
        ),
      ],
    );
  }
}

class RoomEditScreen extends StatefulWidget {
  const RoomEditScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<RoomEditScreen> createState() => _RoomEditScreenState();
}

class _RoomEditScreenState extends State<RoomEditScreen> {
  final _name = TextEditingController(text: 'Кухня');
  final _type = TextEditingController(text: 'Кухня · вспомогательное');
  final _length = TextEditingController(text: 'Не указана');
  final _width = TextEditingController(text: 'Не указана');
  final _height = TextEditingController(text: 'Не указана');
  final _wall = TextEditingController();
  final _floor = TextEditingController();
  final _ceiling = TextEditingController();
  Room? _room;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    Room? found;
    for (final p in context.read<PropertiesCubit>().state.properties) {
      if (p.id != widget.propertyId) continue;
      for (final r in p.rooms) {
        if (r.id == widget.roomId) found = r;
      }
    }
    _room = found;
    if (found != null) {
      _name.text = found.name;
      _type.text = found.kind == 'kitchen'
          ? 'Кухня · вспомогательное'
          : found.name;
      _length.text = found.lengthM?.toString() ?? 'Не указана';
      _width.text = found.widthM?.toString() ?? 'Не указана';
      _height.text = found.heightM?.toString() ?? 'Не указана';
      _wall.text = found.wallMaterial ?? '';
      _floor.text = found.floorMaterial ?? '';
      _ceiling.text = found.ceilingMaterial ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _length.dispose();
    _width.dispose();
    _height.dispose();
    _wall.dispose();
    _floor.dispose();
    _ceiling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _room?.photoPaths.isNotEmpty == true
        ? _room!.photoPaths.first
        : OmaImages.kitchen;

    return OmaPage(
      header: const OmaDomHeader(title: 'Помещение'),
      actions: [
        OmaButton(
          label: 'Сохранить изменения',
          onPressed: () async {
            final room = _room;
            if (room != null) {
              await context.read<PropertiesCubit>().updateRoom(
                    widget.propertyId,
                    room.copyWith(
                      name: _name.text.trim(),
                      lengthM: _optionalNumber(_length.text),
                      widthM: _optionalNumber(_width.text),
                      heightM: _optionalNumber(_height.text),
                      wallMaterial: _optionalText(_wall.text),
                      floorMaterial: _optionalText(_floor.text),
                      ceilingMaterial: _optionalText(_ceiling.text),
                    ),
                  );
            }
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
        Text('Настройка помещения', style: OmaType.bold(22, OmaColors.black)),
        DomLabeledField(
          label: 'Название',
          child: DomTextBox(controller: _name),
        ),
        DomLabeledField(
          label: 'Тип помещения',
          child: DomTextBox(
            controller: _type,
            readOnly: true,
            suffix: const Icon(Icons.expand_more, color: OmaColors.muted),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: DomLabeledField(
                label: 'Длина, м · необязательно',
                child: DomTextBox(controller: _length),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DomLabeledField(
                label: 'Ширина, м · необязательно',
                child: DomTextBox(controller: _width),
              ),
            ),
          ],
        ),
        DomLabeledField(
          label: 'Высота, м · необязательно',
          child: DomTextBox(controller: _height, keyboard: TextInputType.number),
        ),
        Text(
          'Размеры вводятся вручную и не считаются проверенными замерами.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        Text('Материалы · если известны', style: OmaType.bold(16, OmaColors.ink)),
        DomLabeledField(
          label: 'Стены',
          child: DomTextBox(controller: _wall),
        ),
        DomLabeledField(
          label: 'Пол',
          child: DomTextBox(controller: _floor),
        ),
        DomLabeledField(
          label: 'Потолок',
          child: DomTextBox(controller: _ceiling),
        ),
        const DomSoftNote(
          'Не знаете материал — оставьте поле пустым. Эти данные помогут мастеру подготовиться к работе.',
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _roomImage(
            photo,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Text(
          'Пример фотографии · иллюстрация, не фото пользователя',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        Row(
          children: [
            Expanded(
              child: OmaButton(
                label: '+ Добавить фото',
                kind: OmaButtonKind.secondary,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmaButton(
                label: 'Заменить фото',
                kind: OmaButtonKind.secondary,
                onPressed: () {},
              ),
            ),
          ],
        ),
        OmaButton(
          label: 'Заменить файл планировки',
          kind: OmaButtonKind.secondary,
          onPressed: () {},
        ),
        const DomSoftNote(
          'Новое помещение добавляется через эту же форму. Купленные товары остаются привязаны к комнате при переименовании.',
        ),
      ],
    );
  }
}

double? _optionalNumber(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

String? _optionalText(String raw) {
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

List<(String, String)> _roomFacts(Room room) => [
      if (room.lengthM != null && room.widthM != null)
        ('Размер', '${room.lengthM} × ${room.widthM} м'),
      if (room.heightM != null) ('Высота', '${room.heightM} м'),
      if (room.wallMaterial != null) ('Стены', room.wallMaterial!),
      if (room.floorMaterial != null) ('Пол', room.floorMaterial!),
      if (room.ceilingMaterial != null) ('Потолок', room.ceilingMaterial!),
    ];

Widget _roomImage(
  String source, {
  required double height,
  required double width,
  required BoxFit fit,
}) {
  Widget error(BuildContext _, Object __, StackTrace? ___) => Container(
        height: height,
        width: width,
        color: OmaColors.blueSoft,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: OmaColors.blue),
      );
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return Image.network(
      source,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: error,
    );
  }
  return Image.asset(
    source,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: error,
  );
}

(Property, Room)? _resolve(
  BuildContext context,
  String propertyId,
  String roomId,
) {
  final props = context.watch<PropertiesCubit>().state.properties;
  for (final p in props) {
    if (p.id != propertyId) continue;
    for (final r in p.rooms) {
      if (r.id == roomId) return (p, r);
    }
  }
  return null;
}
