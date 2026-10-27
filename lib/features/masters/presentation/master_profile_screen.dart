import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/masters_repository.dart';
import 'package:oma/features/masters/cubit/masters_cubit.dart';
import 'package:oma/features/masters/presentation/widgets/master_widgets.dart';
import 'package:oma/shared/models/master.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class MasterProfileScreen extends StatefulWidget {
  const MasterProfileScreen({required this.masterId, super.key});

  final String masterId;

  @override
  State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

class _MasterProfileScreenState extends State<MasterProfileScreen> {
  late Future<MasterProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<MastersRepository>().byId(widget.masterId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MasterProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final cached = context.watch<MastersCubit>().state.byId(widget.masterId);
        final loaded = snapshot.data ?? cached;
        if (loaded == null && snapshot.connectionState != ConnectionState.done) {
          return const OmaPage(
            header: OmaFlowHeader(title: 'Профиль мастера'),
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        if (loaded == null) {
          return OmaPage(
            header: const OmaFlowHeader(title: 'Профиль мастера'),
            children: [
              MastersContent(
                children: [
                  Text(
                    'Профиль не найден',
                    style: OmaType.bold(18, OmaColors.ink),
                  ),
                  OmaButton(
                    label: 'К каталогу мастеров',
                    onPressed: () => context.go(AppRoutes.masters),
                  ),
                ],
              ),
            ],
          );
        }
        final profile = loaded.copyWith(
          isFavorite: cached?.isFavorite ?? loaded.isFavorite,
        );
        return _ProfileBody(profile: profile);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final MasterProfile profile;

  @override
  Widget build(BuildContext context) {
    return OmaPage(
      header: OmaFlowHeader(
        title: profile.displayName,
        eyebrow: 'Профиль мастера',
      ),
      actions: [
        OmaButton(
          label: 'Оставить заявку',
          onPressed: () => context.push(
            AppRoutes.masterRequestPath(profile.id),
          ),
        ),
      ],
      children: [
        MastersContent(
          children: [
            if (profile.isDemo)
              const OmaInfoNote(
                text:
                    'Демонстрационный профиль. Имя, рейтинг, отзывы и портфолио не описывают реального партнёра ОМА.',
                cream: true,
              ),
            OmaSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MasterAvatar(name: profile.displayName, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: OmaType.bold(20, OmaColors.ink),
                            ),
                            Text(
                              profile.city,
                              style: OmaType.regular(13, OmaColors.muted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${profile.experienceYears} лет опыта',
                              style: OmaType.semibold(13, OmaColors.blue),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: profile.isFavorite
                            ? 'Убрать из моих мастеров'
                            : 'Сохранить в мои мастера',
                        onPressed: () => context
                            .read<MastersCubit>()
                            .toggleFavorite(profile),
                        icon: Icon(
                          profile.isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: profile.isFavorite
                              ? OmaColors.orange
                              : OmaColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final specialty in profile.specialties)
                        OmaBadge(label: specialty),
                      if (profile.verified)
                        const OmaBadge(label: 'Профиль подтверждён'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.bio,
                    style: OmaType.regular(14, OmaColors.ink),
                  ),
                  if (profile.rating != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${profile.isDemo ? 'Демо-рейтинг' : 'Рейтинг'}: ${profile.rating!.toStringAsFixed(1)} · ${profile.reviewCount} отзывов',
                      style: OmaType.semibold(13, OmaColors.blue),
                    ),
                  ],
                ],
              ),
            ),
            Text('Портфолио', style: OmaType.bold(18, OmaColors.ink)),
            if (profile.portfolio.isEmpty)
              Text(
                'Работы пока не добавлены.',
                style: OmaType.regular(13, OmaColors.muted),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 680 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in profile.portfolio)
                        SizedBox(
                          width: width,
                          child: _PortfolioCard(item: item),
                        ),
                    ],
                  );
                },
              ),
            Text('Отзывы', style: OmaType.bold(18, OmaColors.ink)),
            if (profile.reviews.isEmpty)
              Text(
                'Подтверждённых отзывов пока нет.',
                style: OmaType.regular(13, OmaColors.muted),
              )
            else
              for (final review in profile.reviews)
                OmaSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.author,
                              style: OmaType.semibold(14, OmaColors.ink),
                            ),
                          ),
                          Text(
                            '${review.rating.toStringAsFixed(1)} ★',
                            style: OmaType.semibold(12, OmaColors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review.text,
                        style: OmaType.regular(13, OmaColors.muted),
                      ),
                    ],
                  ),
                ),
            OmaButton(
              label: profile.isFavorite
                  ? 'Убрать из моих мастеров'
                  : 'Сохранить мастера',
              kind: OmaButtonKind.secondary,
              onPressed: () =>
                  context.read<MastersCubit>().toggleFavorite(profile),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item});

  final MasterPortfolioItem item;

  @override
  Widget build(BuildContext context) {
    return OmaSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? const ColoredBox(
                    color: OmaColors.blueSoft,
                    child: Icon(
                      Icons.home_repair_service_outlined,
                      color: OmaColors.blue,
                    ),
                  )
                : Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: OmaColors.blueSoft,
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OmaType.semibold(13, OmaColors.ink),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: OmaType.regular(11, OmaColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
