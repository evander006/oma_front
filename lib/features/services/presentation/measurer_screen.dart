import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MeasurerScreen extends StatefulWidget {
  const MeasurerScreen({super.key});

  @override
  State<MeasurerScreen> createState() => _MeasurerScreenState();
}

class _MeasurerScreenState extends State<MeasurerScreen> {
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String? _slot;
  String? _requestId;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_requestId != null) {
      return OmaPage(
        header: const OmaFlowHeader(title: 'Замерщик'),
        actions: [
          OmaButton(
            label: 'К проектам',
            onPressed: () => context.go(AppRoutes.projects),
          ),
        ],
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: OmaColors.green),
          Text(
            'Заявка на замер отправлена',
            style: OmaType.bold(20, OmaColors.ink),
            textAlign: TextAlign.center,
          ),
          Text(
            'Номер: $_requestId\nЭто локальная заявка — удалённый endpoint замера пока не подключён.',
            style: OmaType.regular(13, OmaColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return OmaPage(
      header: const OmaFlowHeader(title: 'Вызвать замерщика'),
      actions: [
        OmaButton(
          label: 'Отправить заявку',
          onPressed: () {
            if (_address.text.trim().isEmpty || _phone.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Укажите адрес и телефон')),
              );
              return;
            }
            setState(() => _requestId = 'MSR-${DateTime.now().millisecondsSinceEpoch % 100000}');
          },
        ),
      ],
      children: [
        Text(
          'Замерщик приедет для предварительной оценки объёма работ. Стоимость выезда уточняется.',
          style: OmaType.regular(13, OmaColors.muted),
        ),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: 'Адрес объекта',
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
        Text('Предпочтительное время', style: OmaType.medium(13, OmaColors.ink)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [
              'Завтра, 10:00–14:00',
              'Послезавтра, 14:00–18:00',
              'Гибкий график',
            ])
              OmaChoiceChip(
                label: s,
                selected: _slot == s,
                onTap: () => setState(() => _slot = s),
              ),
          ],
        ),
        const OmaInfoNote(
          text:
              'Демо-слоты не гарантируют реальную доступность бригады. После подключения API расписание будет синхронизировано.',
          cream: true,
        ),
      ],
    );
  }
}
