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
          child: Image.asset(
            photo,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              color: OmaColors.blueSoft,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, color: OmaColors.blue),
            ),
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
                  'Заказ № 261020-014 · 20.10.2026',
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
                              'Установка смесителя',
                              style: OmaType.medium(14, OmaColors.ink),
                            ),
                            Text(
                              'Отдельная услуга · на согласовании',
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
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _length.dispose();
    _width.dispose();
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
                    room.copyWith(name: _name.text.trim()),
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
        Text(
          'Размеры вводятся вручную и не считаются проверенными замерами.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            photo,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 160, color: OmaColors.blueSoft),
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
