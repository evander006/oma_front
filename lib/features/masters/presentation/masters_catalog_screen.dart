import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/masters/presentation/widgets/master_widgets.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MastersCatalogScreen extends StatelessWidget {
  const MastersCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MastersCubit>().state;
    return OmaPage(
      header: const OmaFlowHeader(
        title: 'Мастера',
        eyebrow: 'Специалисты для вашего дома',
      ),
      children: [
        MastersContent(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Найдите исполнителя под задачу',
                        style: OmaType.bold(22, OmaColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Передайте мастеру только выбранные параметры жилья.',
                        style: OmaType.regular(13, OmaColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Мои мастера и заявки',
                  onPressed: () => context.push(AppRoutes.myMasters),
                  icon: const Icon(Icons.bookmarks_outlined),
                  color: OmaColors.blue,
                ),
              ],
            ),
            if (state.isDemo)
              const OmaInfoNote(
                text:
                    'Демонстрационный каталог. Профили, рейтинги, портфолио и отзывы не являются данными реальных партнёров ОМА.',
                cream: true,
              ),
            Text('Специализация', style: OmaType.bold(16, OmaColors.ink)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OmaChoiceChip(
                    label: 'Все',
                    selected: state.selectedSpecialty == null,
                    onTap: () =>
                        context.read<MastersCubit>().selectSpecialty(null),
                  ),
                  for (final specialty in state.specialties) ...[
                    const SizedBox(width: 8),
                    OmaChoiceChip(
                      label: specialty,
                      selected: state.selectedSpecialty == specialty,
                      onTap: () => context
                          .read<MastersCubit>()
                          .selectSpecialty(specialty),
                    ),
                  ],
                ],
              ),
            ),
            if (state.loading && state.masters.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null && state.masters.isEmpty)
              _CatalogError(message: state.error!)
            else if (state.visibleMasters.isEmpty)
              OmaSurfaceCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_outlined,
                      size: 36,
                      color: OmaColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'По этой специализации мастеров пока нет',
                      textAlign: TextAlign.center,
                      style: OmaType.semibold(14, OmaColors.ink),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 680;
                  final width = twoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final profile in state.visibleMasters)
                        SizedBox(
                          width: width,
                          child: MasterCard(
                            profile: profile,
                            onTap: () => context.push(
                              AppRoutes.masterPath(profile.id),
                            ),
                            onFavorite: () => context
                                .read<MastersCubit>()
                                .toggleFavorite(profile),
                          ),
                        ),
                    ],
                  );
                },
              ),
            OmaButton(
              label: 'Мои мастера и заявки',
              kind: OmaButtonKind.secondary,
              onPressed: () => context.push(AppRoutes.myMasters),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OmaSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Не удалось загрузить мастеров',
            style: OmaType.bold(15, OmaColors.ink),
          ),
          const SizedBox(height: 6),
          Text(message, style: OmaType.regular(12, OmaColors.muted)),
          const SizedBox(height: 12),
          OmaButton(
            label: 'Повторить',
            onPressed: () => context.read<MastersCubit>().load(),
          ),
        ],
      ),
    );
  }
}
