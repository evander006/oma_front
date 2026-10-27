import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/masters/presentation/widgets/master_widgets.dart';
import 'package:oma/shared/models/master.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState
    extends State<ContractorDashboardScreen> {
  String _filter = 'Все';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MastersCubit>().state;
    final requests = state.contractorRequests.where(_matchesFilter).toList();
    return OmaPage(
      header: const OmaFlowHeader(
        title: 'Кабинет подрядчика',
        eyebrow: 'Заявки и материалы',
      ),
      children: [
        MastersContent(
          children: [
            if (state.isDemo)
              const OmaInfoNote(
                text:
                    'Демонстрационный кабинет. Переключение роли доступно без авторизации только для показа MVP; данные и предложения помечены как демо.',
                cream: true,
              ),
            OmaSurfaceCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: OmaColors.blueSoft,
                    child: Icon(
                      Icons.handyman_outlined,
                      color: OmaColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Рабочая очередь',
                          style: OmaType.bold(16, OmaColors.ink),
                        ),
                        Text(
                          'Входящих заявок: ${state.contractorRequests.where((request) => request.status == MasterRequestStatus.submitted).length}',
                          style: OmaType.regular(12, OmaColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Обновить заявки',
                    onPressed: state.saving
                        ? null
                        : () => context
                            .read<MastersCubit>()
                            .refreshDashboard(),
                    icon: const Icon(Icons.refresh),
                    color: OmaColors.blue,
                  ),
                ],
              ),
            ),
            const OmaInfoNote(
              text:
                  'В карточке видны только объект, комната и поля, на передачу которых клиент дал согласие. Остальные сведения паспорта жилья скрыты.',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in const [
                    'Все',
                    'Новые',
                    'В работе',
                    'Завершённые',
                  ]) ...[
                    if (filter != 'Все') const SizedBox(width: 8),
                    OmaChoiceChip(
                      label: filter,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ],
                ],
              ),
            ),
            if (state.loading && state.contractorRequests.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (requests.isEmpty)
              OmaSurfaceCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: OmaColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'В этой группе заявок нет',
                      style: OmaType.semibold(14, OmaColors.ink),
                    ),
                  ],
                ),
              )
            else
              for (final request in requests)
                WorkRequestCard(
                  request: request,
                  showMaster: false,
                  onOpenProduct: (productId) =>
                      context.push(AppRoutes.productPath(productId)),
                  actions: _actions(context, request, state.saving),
                ),
            if (state.error != null)
              OmaInfoNote(text: 'Ошибка: ${state.error}'),
          ],
        ),
      ],
    );
  }

  bool _matchesFilter(MasterWorkRequest request) {
    return switch (_filter) {
      'Новые' => request.status == MasterRequestStatus.submitted,
      'В работе' => request.status == MasterRequestStatus.accepted ||
          request.status == MasterRequestStatus.materialsProposed ||
          request.status == MasterRequestStatus.scheduled ||
          request.status == MasterRequestStatus.inProgress,
      'Завершённые' => request.status == MasterRequestStatus.completed ||
          request.status == MasterRequestStatus.declined,
      _ => true,
    };
  }

  List<Widget> _actions(
    BuildContext context,
    MasterWorkRequest request,
    bool saving,
  ) {
    void update(MasterRequestStatus status) {
      context.read<MastersCubit>().updateStatus(request.id, status);
    }

    return switch (request.status) {
      MasterRequestStatus.submitted => [
          OmaButton(
            label: 'Принять заявку',
            onPressed:
                saving ? null : () => update(MasterRequestStatus.accepted),
          ),
          OmaButton(
            label: 'Отклонить',
            kind: OmaButtonKind.secondary,
            onPressed:
                saving ? null : () => update(MasterRequestStatus.declined),
          ),
        ],
      MasterRequestStatus.accepted ||
      MasterRequestStatus.materialsProposed => [
          OmaButton(
            label: 'Запланировать работы',
            onPressed:
                saving ? null : () => update(MasterRequestStatus.scheduled),
          ),
        ],
      MasterRequestStatus.scheduled => [
          OmaButton(
            label: 'Начать работу',
            onPressed:
                saving ? null : () => update(MasterRequestStatus.inProgress),
          ),
        ],
      MasterRequestStatus.inProgress => [
          OmaButton(
            label: 'Отметить завершённой',
            onPressed:
                saving ? null : () => update(MasterRequestStatus.completed),
          ),
        ],
      _ => const [],
    };
  }
}
