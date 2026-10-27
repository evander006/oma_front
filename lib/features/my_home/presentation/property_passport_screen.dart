import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/home_passport_repository.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/home_passport.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class PropertyPassportScreen extends StatefulWidget {
  const PropertyPassportScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  State<PropertyPassportScreen> createState() => _PropertyPassportScreenState();
}

class _PropertyPassportScreenState extends State<PropertyPassportScreen> {
  String? _roomId;
  late Future<_PassportData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_PassportData> _load() async {
    final repository = context.read<HomePassportRepository>();
    final results = await Future.wait([
      repository.equipment(widget.propertyId, roomId: _roomId),
      repository.history(widget.propertyId, roomId: _roomId),
    ]);
    return _PassportData(
      equipment: results[0] as List<HomeEquipment>,
      history: results[1] as List<HomeHistoryEvent>,
    );
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _openPdf(String path) async {
    final uri = Uri.parse(ApiConfig.absoluteUrl(path));
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) throw StateError('Скачать документ не удалось');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка скачивания PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _findProperty(context, widget.propertyId);
    if (property == null) {
      return const OmaPage(
        header: OmaFlowHeader(title: 'Паспорт жилья'),
        children: [Text('Объект не найден')],
      );
    }

    return OmaPage(
      header: OmaFlowHeader(title: property.name, eyebrow: 'Паспорт жилья'),
      actions: [
        OmaButton(
          label: 'Скачать PDF-паспорт жилья',
          onPressed: () => _openPdf(
            '/api/v1/properties/' + widget.propertyId + '/passport.pdf',
          ),
        ),
      ],
      children: [
        _PassportSummary(property: property),
        Text('Показывать', style: OmaType.medium(13, OmaColors.ink)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OmaChoiceChip(
                label: 'Весь объект',
                selected: _roomId == null,
                onTap: () {
                  _roomId = null;
                  _reload();
                },
              ),
              for (final room in property.rooms) ...[
                const SizedBox(width: 8),
                OmaChoiceChip(
                  label: room.name,
                  selected: _roomId == room.id,
                  onTap: () {
                    _roomId = room.id;
                    _reload();
                  },
                ),
              ],
            ],
          ),
        ),
        FutureBuilder<_PassportData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PassportLoading();
            }
            if (snapshot.hasError) {
              return _PassportError(error: '${snapshot.error}', onRetry: _reload);
            }
            final data = snapshot.data ?? const _PassportData();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OmaSectionHeader(
                  title: 'Оборудование',
                  action: '+ Добавить',
                  onAction: () => _showAddEquipment(property),
                ),
                const SizedBox(height: 10),
                if (data.equipment.isEmpty)
                  _EmptyEquipment(onAdd: () => _showAddEquipment(property))
                else
                  for (final item in data.equipment) ...[
                    _EquipmentCard(
                      item: item,
                      onDownload: int.tryParse(item.id) == null
                          ? null
                          : () => _openPdf(
                                '/api/v1/properties/' +
                                    widget.propertyId +
                                    '/equipment/' +
                                    item.id +
                                    '/passport.pdf',
                              ),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                Text('История работ и установок', style: OmaType.bold(18, OmaColors.ink)),
                const SizedBox(height: 10),
                if (data.history.isEmpty)
                  const DomSoftNote(
                    'История появится после покупки, установки или завершённой работы мастера.',
                  )
                else
                  for (final event in data.history) ...[
                    _HistoryCard(event: event),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddEquipment(Property property) async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final model = TextEditingController();
    final serial = TextEditingController();
    var roomId = _roomId;
    var saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OmaColors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Добавить оборудование', style: OmaType.bold(20, OmaColors.ink)),
                  const SizedBox(height: 8),
                  Text(
                    'Заполните только то, что известно. Характеристики можно дополнить позже.',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Название *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: roomId,
                    decoration: const InputDecoration(labelText: 'Комната'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Весь объект')),
                      for (final room in property.rooms)
                        DropdownMenuItem<String?>(value: room.id, child: Text(room.name)),
                    ],
                    onChanged: saving ? null : (value) => setSheetState(() => roomId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: brand,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Производитель'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: model,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Модель'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serial,
                    decoration: const InputDecoration(labelText: 'Серийный номер'),
                  ),
                  const SizedBox(height: 20),
                  OmaButton(
                    label: saving ? 'Сохраняем…' : 'Сохранить',
                    onPressed: saving
                        ? null
                        : () async {
                            if (name.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Укажите название оборудования')),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              await context.read<HomePassportRepository>().addEquipment(
                                    propertyId: property.id,
                                    roomId: roomId,
                                    name: name.text.trim(),
                                    brand: _textOrNull(brand.text),
                                    model: _textOrNull(model.text),
                                    serialNumber: _textOrNull(serial.text),
                                  );
                              if (context.mounted) Navigator.of(context).pop(true);
                            } catch (error) {
                              setSheetState(() => saving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Не удалось сохранить: $error')),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    name.dispose();
    brand.dispose();
    model.dispose();
    serial.dispose();
    if (saved == true && mounted) _reload();
  }
}

class _PassportSummary extends StatelessWidget {
  const _PassportSummary({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final type = switch (property.type) {
      PropertyType.apartment => 'Квартира',
      PropertyType.house => 'Дом',
      PropertyType.dacha => 'Дача',
    };
    final tenure = switch (property.tenure) {
      PropertyTenure.owned => 'собственное',
      PropertyTenure.rented => 'арендованное',
      null => 'статус не указан',
    };
    return DomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DomIconTile(icon: Icons.home_work_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name, style: OmaType.bold(18, OmaColors.ink)),
                    Text('$type · $tenure', style: OmaType.regular(13, OmaColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${property.rooms.length} помещений${property.areaSqm == null ? '' : ' · ${property.areaSqm!.toStringAsFixed(0)} м²'}',
            style: OmaType.medium(13, OmaColors.ink),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: property.completionPercent.clamp(0, 100) / 100,
            backgroundColor: OmaColors.line,
            color: OmaColors.blue,
          ),
          const SizedBox(height: 6),
          Text(
            property.completionPercent == 0
                ? 'Заполняйте паспорт постепенно — обязательной анкеты нет'
                : 'Паспорт заполнен на ${property.completionPercent}%',
            style: OmaType.regular(12, OmaColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item, this.onDownload});

  final HomeEquipment item;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) => DomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing_outlined, color: OmaColors.blue),
                const SizedBox(width: 10),
                Expanded(child: Text(item.name, style: OmaType.semibold(14, OmaColors.ink))),
                if (item.isDemonstration) const DomPill('Демо'),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.subtitle, style: OmaType.regular(12, OmaColors.muted)),
            if (item.specifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final entry in item.specifications.entries.take(3))
                Text('${entry.key}: ${entry.value}', style: OmaType.regular(12, OmaColors.ink)),
            ],
            if (item.contractorName != null) ...[
              const SizedBox(height: 8),
              Text('Устанавливал: ${item.contractorName}', style: OmaType.regular(12, OmaColors.blue)),
            ],
            if (onDownload != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Скачать паспорт оборудования (PDF)'),
              ),
            ],
          ],
        ),
      );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.event});

  final HomeHistoryEvent event;

  @override
  Widget build(BuildContext context) => DomCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_eventIcon(event.eventType), color: OmaColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: OmaType.semibold(14, OmaColors.ink)),
                  if (event.description != null)
                    Text(event.description!, style: OmaType.regular(12, OmaColors.muted)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (event.occurredAt != null) _formatDate(event.occurredAt!),
                      if (event.roomName != null) event.roomName!,
                      if (event.contractorName != null) event.contractorName!,
                    ].join(' · '),
                    style: OmaType.regular(11, OmaColors.muted),
                  ),
                ],
              ),
            ),
            if (event.isDemonstration) const DomPill('Демо'),
          ],
        ),
      );
}

class _EmptyEquipment extends StatelessWidget {
  const _EmptyEquipment({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => DomCard(
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 36, color: OmaColors.muted),
            const SizedBox(height: 8),
            Text('Оборудование пока не добавлено', style: OmaType.semibold(14, OmaColors.ink)),
            const SizedBox(height: 4),
            Text(
              'После завершения установки через ОМА товар появится здесь автоматически.',
              textAlign: TextAlign.center,
              style: OmaType.regular(12, OmaColors.muted),
            ),
            const SizedBox(height: 12),
            OmaButton(label: 'Добавить вручную', onPressed: onAdd),
          ],
        ),
      );
}

class _PassportLoading extends StatelessWidget {
  const _PassportLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _PassportError extends StatelessWidget {
  const _PassportError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => DomCard(
        child: Column(
          children: [
            Text('Не удалось загрузить паспорт', style: OmaType.semibold(14, OmaColors.ink)),
            const SizedBox(height: 4),
            Text(error, textAlign: TextAlign.center, style: OmaType.regular(12, OmaColors.muted)),
            const SizedBox(height: 12),
            OmaButton(label: 'Повторить', onPressed: onRetry),
          ],
        ),
      );
}

class _PassportData {
  const _PassportData({this.equipment = const [], this.history = const []});

  final List<HomeEquipment> equipment;
  final List<HomeHistoryEvent> history;
}

Property? _findProperty(BuildContext context, String id) {
  for (final property in context.watch<PropertiesCubit>().state.properties) {
    if (property.id == id) return property;
  }
  return null;
}

String? _textOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

IconData _eventIcon(String type) => switch (type) {
      'purchase' => Icons.shopping_bag_outlined,
      'installation' => Icons.build_outlined,
      'repair' => Icons.home_repair_service_outlined,
      'replacement' => Icons.swap_horiz,
      _ => Icons.history,
    };
