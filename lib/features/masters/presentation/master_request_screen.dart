import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/masters/presentation/widgets/master_widgets.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/shared/models/master.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MasterRequestScreen extends StatefulWidget {
  const MasterRequestScreen({required this.masterId, super.key});

  final String masterId;

  @override
  State<MasterRequestScreen> createState() => _MasterRequestScreenState();
}

class _MasterRequestScreenState extends State<MasterRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  final _sharedFields = <SharedHomeField>{
    SharedHomeField.roomDimensions,
    SharedHomeField.installedEquipment,
  };
  String? _propertyId;
  String? _roomId;
  bool _consent = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final property = context.read<PropertiesCubit>().state.selected;
    _propertyId = property?.id;
    _roomId = property?.rooms.isEmpty == false ? property!.rooms.first.id : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masters = context.watch<MastersCubit>().state;
    final master = masters.byId(widget.masterId);
    final propertiesState = context.watch<PropertiesCubit>().state;
    final properties = propertiesState.properties;
    final selectedProperty = _propertyById(properties, _propertyId);
    final rooms = selectedProperty?.rooms ?? const <Room>[];

    if (master == null && masters.loading) {
      return const OmaPage(
        header: OmaFlowHeader(title: 'Заявка мастеру'),
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (master == null) {
      return OmaPage(
        header: const OmaFlowHeader(title: 'Заявка мастеру'),
        children: [
          MastersContent(
            children: [
              Text(
                'Мастер не найден',
                style: OmaType.bold(18, OmaColors.ink),
              ),
              OmaButton(
                label: 'Открыть каталог',
                onPressed: () => context.go(AppRoutes.masters),
              ),
            ],
          ),
        ],
      );
    }

    return OmaPage(
      header: OmaFlowHeader(
        title: 'Заявка мастеру',
        eyebrow: master.displayName,
      ),
      actions: [
        OmaButton(
          label: masters.saving ? 'Отправляем…' : 'Отправить заявку',
          onPressed: masters.saving || properties.isEmpty
              ? null
              : () => _submit(master, selectedProperty),
        ),
      ],
      children: [
        MastersContent(
          children: [
            if (master.isDemo)
              const OmaInfoNote(
                text:
                    'Демо-режим: заявка сохранится локально и появится в демонстрационном кабинете подрядчика.',
                cream: true,
              ),
            OmaSurfaceCard(
              child: Row(
                children: [
                  MasterAvatar(name: master.displayName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          master.displayName,
                          style: OmaType.bold(16, OmaColors.ink),
                        ),
                        Text(
                          master.specialties.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: OmaType.regular(12, OmaColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (properties.isEmpty)
              _NoPropertyCard()
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Задача', style: OmaType.bold(18, OmaColors.ink)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        label: 'Краткое название',
                        hint: 'Например, установить смеситель',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Опишите задачу коротко'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _decoration(
                        label: 'Подробности',
                        hint: 'Что нужно сделать и какой результат ожидаете',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Добавьте детали для мастера'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budget,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _decoration(
                        label: 'Ориентир бюджета, BYN · необязательно',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return double.tryParse(value.replaceAll(',', '.')) == null
                            ? 'Введите сумму числом'
                            : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Жильё и комната',
                      style: OmaType.bold(18, OmaColors.ink),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _propertyId,
                      isExpanded: true,
                      decoration: _decoration(label: 'Объект жилья'),
                      items: [
                        for (final property in properties)
                          DropdownMenuItem(
                            value: property.id,
                            child: Text(
                              property.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        final property = _propertyById(properties, value);
                        setState(() {
                          _propertyId = value;
                          _roomId = property?.rooms.isEmpty == false
                              ? property!.rooms.first.id
                              : null;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Выберите объект, данные которого можно передать'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: rooms.any((room) => room.id == _roomId)
                          ? _roomId
                          : null,
                      isExpanded: true,
                      decoration: _decoration(
                        label: rooms.isEmpty
                            ? 'В объекте пока нет комнат'
                            : 'Комната',
                      ),
                      items: [
                        for (final room in rooms)
                          DropdownMenuItem(
                            value: room.id,
                            child: Text(
                              room.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: rooms.isEmpty
                          ? null
                          : (value) => setState(() => _roomId = value),
                      validator: (value) => rooms.isNotEmpty && value == null
                          ? 'Выберите комнату'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Что увидит мастер',
                      style: OmaType.bold(18, OmaColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Отметьте только сведения, необходимые для этой работы.',
                      style: OmaType.regular(13, OmaColors.muted),
                    ),
                    const SizedBox(height: 8),
                    OmaSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          for (final field in SharedHomeField.values)
                            CheckboxListTile(
                              value: _sharedFields.contains(field),
                              activeColor: OmaColors.blue,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                field.labelRu,
                                style: OmaType.regular(13, OmaColors.ink),
                              ),
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _sharedFields.add(field);
                                } else {
                                  _sharedFields.remove(field);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OmaSurfaceCard(
                      selected: _consent,
                      padding: const EdgeInsets.all(8),
                      child: CheckboxListTile(
                        value: _consent,
                        activeColor: OmaColors.blue,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Разрешаю передать этому мастеру только отмеченные сведения об объекте и комнате.',
                          style: OmaType.semibold(13, OmaColors.ink),
                        ),
                        subtitle: Text(
                          'Согласие относится только к этой заявке. Контактные и остальные данные жилья не открываются.',
                          style: OmaType.regular(11, OmaColors.muted),
                        ),
                        onChanged: (checked) =>
                            setState(() => _consent = checked == true),
                      ),
                    ),
                    if (masters.error != null) ...[
                      const SizedBox(height: 12),
                      OmaInfoNote(
                        text: 'Не удалось отправить заявку: ${masters.error}',
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit(
    MasterProfile master,
    Property? selectedProperty,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (selectedProperty == null) {
      _showMessage('Выберите объект жилья.');
      return;
    }
    if (_sharedFields.isEmpty) {
      _showMessage('Выберите хотя бы один вид данных для передачи мастеру.');
      return;
    }
    if (!_consent) {
      _showMessage('Подтвердите согласие на передачу выбранных сведений.');
      return;
    }
    final room = _roomById(selectedProperty.rooms, _roomId);
    final created = await context.read<MastersCubit>().submitRequest(
          MasterRequestDraft(
            masterId: master.id,
            masterName: master.displayName,
            title: _title.text.trim(),
            description: _description.text.trim(),
            propertyId: selectedProperty.id,
            propertyName: selectedProperty.name,
            roomId: room?.id,
            roomName: room?.name,
            budgetByn: double.tryParse(_budget.text.replaceAll(',', '.')),
            sharedFields: Set.unmodifiable(_sharedFields),
            consentGranted: _consent,
          ),
        );
    if (!mounted || created == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Заявка отправлена'),
        content: Text(
          created.isDemo
              ? 'Демо-заявка сохранена локально. Её можно обработать в кабинете подрядчика.'
              : 'Мастер получил структурированную задачу и выбранные вами сведения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Открыть историю'),
          ),
        ],
      ),
    );
    if (mounted) context.go(AppRoutes.myMasters);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _NoPropertyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OmaSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Сначала добавьте жильё',
            style: OmaType.bold(16, OmaColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Объект нужен, чтобы мастер получил структурированную задачу, а не только контакт.',
            style: OmaType.regular(13, OmaColors.muted),
          ),
          const SizedBox(height: 12),
          OmaButton(
            label: 'Добавить жильё',
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoration({required String label, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: OmaColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OmaRadius.sm),
      borderSide: const BorderSide(color: OmaColors.line),
    ),
  );
}

Property? _propertyById(List<Property> properties, String? id) {
  for (final property in properties) {
    if (property.id == id) return property;
  }
  return null;
}

Room? _roomById(List<Room> rooms, String? id) {
  for (final room in rooms) {
    if (room.id == id) return room;
  }
  return null;
}
