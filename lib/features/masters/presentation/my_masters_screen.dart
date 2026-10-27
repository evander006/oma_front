import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/masters/presentation/widgets/master_widgets.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MyMastersScreen extends StatelessWidget {
  const MyMastersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MastersCubit>().state;
    return OmaPage(
      header: const OmaFlowHeader(
        title: 'Мои мастера',
        eyebrow: 'Сохранённые специалисты и заявки',
      ),
      children: [
        MastersContent(
          children: [
            if (state.isDemo)
              const OmaInfoNote(
                text:
                    'В разделе есть демонстрационные профили и заявки. Они явно помечены и хранятся локально при недоступном API.',
                cream: true,
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Сохранённые мастера',
                    style: OmaType.bold(18, OmaColors.ink),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.masters),
                  child: const Text('Найти мастера'),
                ),
              ],
            ),
            if (state.favorites.isEmpty)
              OmaSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Вы ещё не сохранили мастеров',
                      style: OmaType.semibold(15, OmaColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Сохранённому специалисту проще отправить повторную заявку из истории жилья.',
                      style: OmaType.regular(13, OmaColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OmaButton(
                      label: 'Открыть каталог',
                      onPressed: () => context.push(AppRoutes.masters),
                    ),
                  ],
                ),
              )
            else
              for (final profile in state.favorites)
                MasterCard(
                  profile: profile,
                  onTap: () =>
                      context.push(AppRoutes.masterPath(profile.id)),
                  onFavorite: () => context
                      .read<MastersCubit>()
                      .toggleFavorite(profile),
                ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'История заявок',
                    style: OmaType.bold(18, OmaColors.ink),
                  ),
                ),
                IconButton(
                  tooltip: 'Обновить историю',
                  onPressed: () =>
                      context.read<MastersCubit>().refreshHistory(),
                  icon: const Icon(Icons.refresh),
                  color: OmaColors.blue,
                ),
              ],
            ),
            if (state.loading && state.clientRequests.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (state.clientRequests.isEmpty)
              OmaSurfaceCard(
                child: Text(
                  'Заявок пока нет. Выберите мастера и передайте ему структурированную задачу.',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
              )
            else
              for (final request in state.clientRequests)
                WorkRequestCard(
                  request: request,
                  actions: [
                    OmaButton(
                      label: 'Обратиться повторно',
                      kind: OmaButtonKind.secondary,
                      onPressed: () => context.push(
                        AppRoutes.masterRequestPath(request.masterId),
                      ),
                    ),
                  ],
                ),
            if (state.error != null)
              OmaInfoNote(text: 'Ошибка обновления: ${state.error}'),
            OmaButton(
              label: 'Кабинет подрядчика',
              kind: OmaButtonKind.secondary,
              onPressed: () => context.push(AppRoutes.contractorDashboard),
            ),
          ],
        ),
      ],
    );
  }
}
