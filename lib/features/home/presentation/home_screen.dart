import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/loyalty_repository.dart';
import 'package:oma/features/catalog/cubit/catalog_cubit.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/loyalty.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:oma/shared/widgets/product_card.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';
import 'package:oma/widgets/oma_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsCubit>().state.items;
    RenovationRequest? active;
    for (final p in projects) {
      if (p.status == RenovationProjectStatus.inProgress ||
          p.status == RenovationProjectStatus.scheduled ||
          p.status == RenovationProjectStatus.submitted) {
        active = p;
        break;
      }
    }
    active ??= projects.isEmpty ? null : projects.first;
    final catalog = context.watch<CatalogCubit>().state;
    final products = catalog.products.take(4).toList();

    return OmaPage(
      header: const OmaHomeHeader(),
      children: [
        OmaSearchBar(onTap: () => context.go(AppRoutes.catalog)),
        const _HeroTurnkeyCard(),
        const _SecondaryServicesGrid(),
        const _StartHereSection(),
        if (active != null) _ActiveProjectCard(project: active),
        _LoyaltyStrip(
          future: context.read<LoyaltyRepository>().account(),
        ),
        OmaSectionHeader(
          title: 'Популярные услуги',
          action: 'Все',
          onAction: () => context.go(AppRoutes.services),
        ),
        const _PopularServices(),
        OmaSectionHeader(
          title: 'Категории и материалы',
          action: 'Каталог',
          onAction: () => context.go(AppRoutes.catalog),
        ),
        const _CategoryRow(),
        if (products.isNotEmpty) ...[
          OmaSectionHeader(
            title: 'Рекомендуемые материалы',
            action: 'Ещё',
            onAction: () => context.go(AppRoutes.catalog),
          ),
          for (final p in products)
            ProductCard(
              product: p,
              onTap: () => context.push(AppRoutes.productPath(p.id)),
            ),
        ],
        const _RoomBundles(),
        OmaSectionHeader(
          title: 'Акции и сезонные предложения',
          action: null,
        ),
        const _PromoBanners(),
      ],
    );
  }
}

class _HeroTurnkeyCard extends StatelessWidget {
  const _HeroTurnkeyCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.blue,
      borderRadius: BorderRadius.circular(OmaRadius.lg),
      child: InkWell(
        onTap: () => context.push(AppRoutes.turnkey),
        borderRadius: BorderRadius.circular(OmaRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(OmaSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: OmaColors.orange,
                  borderRadius: BorderRadius.circular(OmaRadius.pill),
                ),
                child: Text(
                  'Главный сценарий',
                  style: OmaType.semibold(11, OmaColors.ink),
                ),
              ),
              const SizedBox(height: OmaSpace.sm),
              Text(
                'Ремонт под ключ',
                style: OmaType.bold(22, OmaColors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'От замера до сдачи: материалы OMA, мастера и сопровождение проекта.',
                style: OmaType.regular(13, OmaColors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: OmaSpace.md),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: OmaColors.orange,
                  borderRadius: BorderRadius.circular(OmaRadius.sm),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.turnkey),
                    borderRadius: BorderRadius.circular(OmaRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Рассчитать стоимость',
                        textAlign: TextAlign.center,
                        style: OmaType.bold(15, OmaColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Предварительная оценка · не является коммерческим предложением',
                style: OmaType.regular(11, OmaColors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryServicesGrid extends StatelessWidget {
  const _SecondaryServicesGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Отдельные ремонтные работы',
        Icons.handyman_outlined,
        () => context.go(AppRoutes.services),
      ),
      (
        'ИИ-дизайнер по фото',
        Icons.auto_awesome_outlined,
        () => context.push(AppRoutes.aiDesign),
      ),
      (
        'Подбор материалов',
        Icons.grid_view_outlined,
        () => context.go(AppRoutes.catalog),
      ),
      (
        'Вызвать замерщика',
        Icons.straighten_outlined,
        () => context.push(AppRoutes.measurer),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final item in items)
          OmaSurfaceCard(
            padding: const EdgeInsets.all(12),
            onTap: item.$3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$2, color: OmaColors.blue, size: 22),
                const Spacer(),
                Text(
                  item.$1,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: OmaType.semibold(13, OmaColors.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StartHereSection extends StatelessWidget {
  const _StartHereSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('С чего начнём?', style: OmaType.bold(18, OmaColors.ink)),
        const SizedBox(height: 10),
        OmaSurfaceCard(
          child: Column(
            children: [
              _StartRow(
                title: 'Нужен полный ремонт',
                subtitle: 'Мастер-заявка под ключ',
                onTap: () => context.push(AppRoutes.turnkey),
              ),
              const Divider(height: 20),
              _StartRow(
                title: 'Хочу обновить одну комнату',
                subtitle: 'ИИ-дизайн + товары из каталога',
                onTap: () => context.push(AppRoutes.aiDesign),
              ),
              const Divider(height: 20),
              _StartRow(
                title: 'Нужна только установка',
                subtitle: 'Отдельные услуги мастеров',
                onTap: () => context.go(AppRoutes.services),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartRow extends StatelessWidget {
  const _StartRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OmaType.semibold(14, OmaColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ),
          ),
          const OmaIcon(OmaIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}

class _ActiveProjectCard extends StatelessWidget {
  const _ActiveProjectCard({required this.project});

  final RenovationRequest project;

  @override
  Widget build(BuildContext context) {
    return OmaSurfaceCard(
      onTap: () => context.push(AppRoutes.projectPath(project.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Активный проект',
                  style: OmaType.semibold(12, OmaColors.blue),
                ),
              ),
              OmaBadge(label: project.status.labelRu),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.displayName, style: OmaType.bold(16, OmaColors.ink)),
          if (project.address != null) ...[
            const SizedBox(height: 4),
            Text(project.address!, style: OmaType.regular(13, OmaColors.muted)),
          ],
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress(project.status),
            backgroundColor: OmaColors.line,
            color: OmaColors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  double _progress(RenovationProjectStatus s) {
    final i = RenovationProjectStatus.values.indexOf(s);
    return ((i + 1) / RenovationProjectStatus.values.length).clamp(0.1, 1.0);
  }
}

class _LoyaltyStrip extends StatelessWidget {
  const _LoyaltyStrip({required this.future});

  final Future<LoyaltyAccount> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltyAccount>(
      future: future,
      builder: (context, snap) {
        final account = snap.data;
        return OmaSurfaceCard(
          onTap: () => context.push(AppRoutes.loyalty),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: OmaColors.cream,
                  borderRadius: BorderRadius.circular(OmaRadius.sm),
                ),
                child: const Icon(Icons.stars_rounded, color: OmaColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account == null
                          ? 'Бонусная программа'
                          : '${account.balance} баллов · ${account.tier}',
                      style: OmaType.semibold(14, OmaColors.ink),
                    ),
                    Text(
                      account?.demo == true
                          ? 'Демо-баланс · правила уточняются'
                          : 'Персональные предложения',
                      style: OmaType.regular(12, OmaColors.muted),
                    ),
                  ],
                ),
              ),
              const OmaIcon(OmaIcons.chevronRight, size: 20),
            ],
          ),
        );
      },
    );
  }
}

class _PopularServices extends StatelessWidget {
  const _PopularServices();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Сантехника', 'svc_plumbing'),
      ('Электромонтаж', 'svc_electro'),
      ('Укладка плитки', 'svc_tile'),
      ('Сборка мебели', 'svc_furniture'),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return OmaChoiceChip(
            label: item.$1,
            selected: false,
            onTap: () => context.push(AppRoutes.serviceBookPath(item.$2)),
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CatalogCubit>().state.categories.take(6).toList();
    if (cats.isEmpty) {
      return Text(
        'Категории загрузятся из каталога',
        style: OmaType.regular(13, OmaColors.muted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in cats)
          OmaChoiceChip(
            label: c.name,
            selected: false,
            onTap: () {
              context.read<CatalogCubit>().setCategory(c.id);
              context.go(AppRoutes.catalog);
            },
          ),
      ],
    );
  }
}

class _RoomBundles extends StatelessWidget {
  const _RoomBundles();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Готовые комплекты комнат', style: OmaType.bold(18, OmaColors.ink)),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final b in [
                ('Кухня старт', 'Смеситель + мойка + свет'),
                ('Санузел комфорт', 'Плитка + сантехника'),
                ('Гостиная свет', 'Освещение + розетки'),
              ]) ...[
                SizedBox(
                  width: 220,
                  child: OmaSurfaceCard(
                    onTap: () => context.go(AppRoutes.catalog),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.$1, style: OmaType.bold(15, OmaColors.ink)),
                        const SizedBox(height: 6),
                        Text(b.$2, style: OmaType.regular(12, OmaColors.muted)),
                        const Spacer(),
                        Text(
                          'Цены из каталога · BYN',
                          style: OmaType.semibold(12, OmaColors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoBanners extends StatelessWidget {
  const _PromoBanners();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(OmaRadius.sm),
          child: AspectRatio(
            aspectRatio: 543 / 214,
            child: Image.asset(
              OmaImages.homeHalva,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: OmaColors.blueSoft,
                child: Center(
                  child: Text(
                    'Акция',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(OmaRadius.sm),
          child: AspectRatio(
            aspectRatio: 543 / 221,
            child: Image.asset(
              OmaImages.homePosuda,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: OmaColors.cream,
                child: Center(
                  child: Text(
                    'Сезонное предложение',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
