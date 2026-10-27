import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsCubit>().state;
    final properties = context.watch<PropertiesCubit>().state.properties;

    return OmaPage(
      header: const OmaFlowHeader(
        title: 'Мои проекты',
        eyebrow: 'Ремонт · объекты · дизайны',
        showCart: true,
      ),
      children: [
        OmaButton(
          label: 'Новый ремонт под ключ',
          kind: OmaButtonKind.orange,
          onPressed: () => context.push(AppRoutes.turnkey),
        ),
        OmaButton(
          label: 'ИИ-дизайн комнаты',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.push(AppRoutes.aiDesign),
        ),
        Text('Заявки на ремонт', style: OmaType.bold(18, OmaColors.ink)),
        if (projects.loading)
          const Center(child: CircularProgressIndicator())
        else if (projects.items.isEmpty)
          OmaSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Пока нет проектов',
                  style: OmaType.bold(16, OmaColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Создайте заявку на ремонт или сохраните ИИ-дизайн — всё появится здесь.',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
                const SizedBox(height: 12),
                OmaButton(
                  label: 'Создать первый проект',
                  onPressed: () => context.push(AppRoutes.turnkey),
                ),
              ],
            ),
          )
        else
          for (final p in projects.items)
            OmaSurfaceCard(
              onTap: () => context.push(AppRoutes.projectPath(p.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: OmaType.semibold(15, OmaColors.ink),
                        ),
                      ),
                      OmaBadge(label: p.status.labelRu),
                    ],
                  ),
                  if (p.address != null) ...[
                    const SizedBox(height: 6),
                    Text(p.address!, style: OmaType.regular(12, OmaColors.muted)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    p.status == RenovationProjectStatus.draft
                        ? 'Черновик можно продолжить'
                        : 'Откройте карточку проекта',
                    style: OmaType.regular(12, OmaColors.blue),
                  ),
                ],
              ),
            ),
        Text('Объекты «Мой дом»', style: OmaType.bold(18, OmaColors.ink)),
        OmaSurfaceCard(
          onTap: () {
            if (properties.isEmpty) {
              context.push(AppRoutes.onboarding);
            } else {
              context.push(AppRoutes.myHome);
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      properties.isEmpty
                          ? 'Добавить объект'
                          : 'Объектов: ${properties.length}',
                      style: OmaType.semibold(14, OmaColors.ink),
                    ),
                    Text(
                      'Комнаты, фото, ИИ-подбор и 3D',
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
  }
}

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ProjectsCubit>().state.items;
    RenovationRequest? project;
    for (final p in items) {
      if (p.id == requestId) {
        project = p;
        break;
      }
    }

    if (project == null) {
      return OmaPage(
        header: const OmaFlowHeader(title: 'Проект'),
        children: [
          Text('Проект не найден', style: OmaType.regular(14, OmaColors.muted)),
          OmaButton(
            label: 'К списку',
            onPressed: () => context.go(AppRoutes.projects),
          ),
        ],
      );
    }

    final p = project;
    return OmaPage(
      header: OmaFlowHeader(title: p.displayName),
      actions: [
        if (p.status == RenovationProjectStatus.draft)
          OmaButton(
            label: 'Продолжить заявку',
            onPressed: () => context.push(AppRoutes.turnkeyPath(p.id)),
          ),
        OmaButton(
          label: 'Открыть каталог материалов',
          kind: OmaButtonKind.secondary,
          onPressed: () => context.go(AppRoutes.catalog),
        ),
      ],
      children: [
        OmaBadge(label: p.status.labelRu),
        OmaDataRow(label: 'Адрес', value: p.address ?? '—'),
        OmaDataRow(label: 'Бюджет', value: p.budgetRange ?? '—'),
        OmaDataRow(label: 'Стиль', value: p.style ?? '—'),
        OmaDataRow(
          label: 'Комнаты',
          value: p.selectedRooms.isEmpty ? '—' : p.selectedRooms.join(', '),
        ),
        OmaDataRow(
          label: 'Фото',
          value: '${p.photoAssets.length}',
        ),
        if (p.photoAssets.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.photoAssets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    p.photoAssets[i],
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 96,
                      color: OmaColors.blueSoft,
                    ),
                  ),
                );
              },
            ),
          ),
        const OmaInfoNote(
          text:
              'Статусы локальные/демо, пока нет операционного backend для ремонта. Предварительная оценка не является сметой.',
          cream: true,
        ),
        OmaButton(
          label: 'Удалить проект',
          kind: OmaButtonKind.secondary,
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Удалить проект?'),
                content: const Text('Действие нельзя отменить.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await context.read<ProjectsCubit>().delete(p.id);
              if (context.mounted) context.go(AppRoutes.projects);
            }
          },
        ),
      ],
    );
  }
}
