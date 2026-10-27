import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/loyalty_repository.dart';
import 'package:oma/core/repositories/services_repository.dart';
import 'package:oma/features/catalog/cubit/catalog_cubit.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/loyalty.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
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
          p.status == RenovationProjectStatus.submitted ||
          p.status == RenovationProjectStatus.draft) {
        active = p;
        break;
      }
    }
    active ??= projects.isEmpty ? null : projects.first;

    return OmaPage(
      header: const OmaHomeHeader(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Минск, Лесная, 12 ⌄',
              style: OmaType.bold(11, OmaColors.blue).copyWith(
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Дом, в котором хорошо',
              style: OmaType.bold(28, OmaColors.ink).copyWith(height: 1.15),
            ),
            const SizedBox(height: 20),
            const _HomeSearchField(),
            const SizedBox(height: 20),
            const _HeroTurnkeyCard(),
            const SizedBox(height: 20),
            const _QuickScenarioRow(),
            const SizedBox(height: 20),
            const _SecondaryLinksCard(),
            const SizedBox(height: 20),
            Text(
              'С чего начнём?',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            const _StartChips(),
            const SizedBox(height: 20),
            Text(
              'Продолжим ваш ремонт',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            if (active != null)
              _ActiveProjectCard(project: active)
            else
              const _ActiveProjectPlaceholder(),
            const SizedBox(height: 20),
            Text(
              'Популярные услуги',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            const _PopularServicesCard(),
            const SizedBox(height: 20),
            Text(
              'Материалы для ваших идей',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            const _MaterialChips(),
            const SizedBox(height: 20),
            const _KitchenPickCard(),
            const SizedBox(height: 20),
            Text(
              'Готовые решения для комнат',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            const _RoomBundleBlock(),
            const SizedBox(height: 20),
            _LoyaltyCard(
              future: context.read<LoyaltyRepository>().account(),
            ),
            const SizedBox(height: 20),
            Text(
              'Дом готов к новому сезону',
              style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
            ),
            const SizedBox(height: 20),
            const _SeasonCard(),
            const SizedBox(height: 20),
            const _BottomCta(),
          ],
        ),
      ],
    );
  }
}

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go(AppRoutes.catalog),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const OmaIcon(OmaIcons.searchHome, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Товары, услуги и идеи для дома',
                  style: OmaType.regular(15, OmaColors.muted).copyWith(
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTurnkeyCard extends StatelessWidget {
  const _HeroTurnkeyCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: OmaColors.blueDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.asset(
                OmaImages.homeHeroRoom,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ОТ ИДЕИ ДО НОВОГО ДОМА',
                    style: OmaType.bold(11, OmaColors.orange),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ремонт под ключ',
                    style: OmaType.bold(32, OmaColors.white).copyWith(
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Расскажите о квартире, соберите заявку на ремонт, материалы и помощь с обустройством.',
                    style: OmaType.regular(15, OmaColors.white).copyWith(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _RedCartButton(),
                  const SizedBox(height: 14),
                  Text(
                    'Предварительно, условия уточняются',
                    style: OmaType.regular(13, OmaColors.white).copyWith(
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickScenarioRow extends StatelessWidget {
  const _QuickScenarioRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ScenarioCard(
            icon: OmaIcons.wrench,
            title: 'Отдельные ремонтные работы',
            action: 'Выбрать услугу',
            onTap: () => context.go(AppRoutes.services),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScenarioCard(
            icon: OmaIcons.sparkles,
            title: 'ИИ-дизайнер по фото',
            action: 'Попробовать',
            onTap: () => context.push(AppRoutes.aiDesign),
          ),
        ),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OmaColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OmaIcon(icon, size: 22),
              const SizedBox(height: 12),
              Text(
                title,
                style: OmaType.semibold(15, OmaColors.ink).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action,
                style: OmaType.regular(13, OmaColors.blue).copyWith(
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryLinksCard extends StatelessWidget {
  const _SecondaryLinksCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OmaColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinkBlock(
              title: 'Подбор материалов',
              subtitle: 'Список покупок под вашу задачу',
              onTap: () => context.go(AppRoutes.catalog),
            ),
            const SizedBox(height: 12),
            _LinkBlock(
              title: 'Вызвать замерщика',
              subtitle: 'Оставить запрос, условия уточняются',
              onTap: () => context.push(AppRoutes.measurer),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkBlock extends StatelessWidget {
  const _LinkBlock({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: OmaType.regular(15, OmaColors.ink).copyWith(height: 1.6),
          ),
          Text(
            subtitle,
            style: OmaType.regular(15, OmaColors.ink).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _StartChips extends StatefulWidget {
  const _StartChips();

  @override
  State<_StartChips> createState() => _StartChipsState();
}

class _StartChipsState extends State<_StartChips> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('✓ Ремонт всей квартиры', () => context.push(AppRoutes.turnkey)),
      ('Обновить комнату', () => context.push(AppRoutes.aiDesign)),
      ('Найти товар', () => context.go(AppRoutes.catalog)),
      ('Нужен совет', () => context.push(AppRoutes.aiDesign)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < items.length; i++)
          GestureDetector(
            onTap: () {
              setState(() => selected = i);
              items[i].$2();
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  items[i].$1,
                  style: (selected == i
                          ? OmaType.bold(13, OmaColors.blue)
                          : OmaType.medium(13, OmaColors.muted))
                      .copyWith(height: 1.0),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveProjectCard extends StatelessWidget {
  const _ActiveProjectCard({required this.project});

  final RenovationRequest project;

  @override
  Widget build(BuildContext context) {
    final step = _stepOf(project.status);
    final total = 10;
    final progress = step / total;

    return Material(
      color: OmaColors.blueSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push(AppRoutes.projectPath(project.id)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OmaColors.blueSoft,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    project.status.labelRu,
                    style: OmaType.semibold(12, OmaColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                project.displayName,
                style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                'Анкета заполнена на ${(progress * 100).round()}%. '
                'Остались сроки, материалы и контакты.',
                style: OmaType.regular(15, OmaColors.muted).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$step из $total шагов',
                style: OmaType.semibold(13, OmaColors.blue).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.08, 1.0),
                  minHeight: 5,
                  backgroundColor: OmaColors.line,
                  color: OmaColors.blue,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'Продолжить с шага ${step + 1 > total ? total : step + 1}',
                    style: OmaType.semibold(15, OmaColors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _stepOf(RenovationProjectStatus s) {
    final i = RenovationProjectStatus.values.indexOf(s);
    return ((i + 1) * 10 / RenovationProjectStatus.values.length)
        .round()
        .clamp(1, 10);
  }
}

class _ActiveProjectPlaceholder extends StatelessWidget {
  const _ActiveProjectPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.blueSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push(AppRoutes.turnkey),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OmaColors.blueSoft,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    'Черновик',
                    style: OmaType.semibold(12, OmaColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Квартира на Лесной',
                style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                'Анкета заполнена на 60%. Остались сроки, материалы и контакты.',
                style: OmaType.regular(15, OmaColors.muted).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '6 из 10 шагов',
                style: OmaType.semibold(13, OmaColors.blue).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 5,
                  backgroundColor: OmaColors.line,
                  color: OmaColors.blue,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'Продолжить с шага 7',
                    style: OmaType.semibold(15, OmaColors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularServicesCard extends StatelessWidget {
  const _PopularServicesCard();

  static const _fallback = [
    ('Сантехника', 'Замена смесителя и другие работы'),
    ('Электрика', 'Розетки, проводка, освещение'),
    ('Покраска и поклейка обоев', 'Обновление стен'),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<ServicesRepository>().all(),
      builder: (context, snap) {
        final services = snap.data ?? const [];
        final rows = services.isEmpty
            ? _fallback
            : services
                .take(3)
                .map(
                  (s) => (
                    s.title,
                    (s.description == null || s.description!.isEmpty)
                        ? s.priceLabel
                        : s.description!,
                  ),
                )
                .toList();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: OmaColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OmaColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (services.length > i) {
                        context.push(
                          AppRoutes.serviceBookPath(services[i].id),
                        );
                      } else {
                        context.go(AppRoutes.services);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$1,
                          style: OmaType.regular(15, OmaColors.ink)
                              .copyWith(height: 1.6),
                        ),
                        Text(
                          rows[i].$2,
                          style: OmaType.regular(15, OmaColors.ink)
                              .copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.go(AppRoutes.services),
                  child: Text(
                    'Все услуги',
                    style: OmaType.regular(15, OmaColors.ink).copyWith(
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MaterialChips extends StatelessWidget {
  const _MaterialChips();

  static const _defaults = [
    'Интерьер и отделка',
    'Напольные покрытия',
    'Лакокрасочные материалы',
    'Плитка',
    'Обои',
    'Сантехника',
  ];

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CatalogCubit>().state.categories;
    final labels = cats.isEmpty
        ? _defaults
        : cats.take(6).map((c) => c.name).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () {
              if (cats.length > i) {
                context.read<CatalogCubit>().setCategory(cats[i].id);
              }
              context.go(AppRoutes.catalog);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[i],
                  style: OmaType.medium(13, OmaColors.muted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _KitchenPickCard extends StatelessWidget {
  const _KitchenPickCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OmaColors.line),
      ),
      child: InkWell(
        onTap: () => context.go(AppRoutes.catalog),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Для кухни Анны',
                style: OmaType.regular(15, OmaColors.ink).copyWith(height: 1.6),
              ),
              Text(
                'Графитовая сантехника, свет и хранение',
                style: OmaType.regular(15, OmaColors.ink).copyWith(height: 1.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Подбор категорий, цены и наличие уточняются',
                style: OmaType.regular(13, OmaColors.muted).copyWith(
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomBundleBlock extends StatelessWidget {
  const _RoomBundleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 360 / 190,
            child: Image.asset(
              OmaImages.homeRoomBundle,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: OmaColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OmaColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Кухня в тёплых тонах',
                  style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
                ),
                const SizedBox(height: 12),
                Text(
                  'Сантехника + свет + хранение. Состав можно изменить под вашу комнату.',
                  style: OmaType.regular(15, OmaColors.muted).copyWith(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.catalog),
                      child: Text(
                        'Посмотреть комплект',
                        style: OmaType.semibold(15, OmaColors.blue),
                      ),
                    ),
                  ),
                ),
                Text(
                  'Концепция, не готовый товарный комплект',
                  style: OmaType.regular(13, OmaColors.muted).copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.future});

  final Future<LoyaltyAccount> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltyAccount>(
      future: future,
      builder: (context, snap) {
        final account = snap.data;
        final balance = account?.balance ?? 240;
        final demo = account?.demo ?? true;

        return Material(
          color: OmaColors.blueSoft,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => context.push(AppRoutes.loyalty),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: OmaColors.blueSoft,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        demo ? 'БАЛАНС, демо' : 'БАЛАНС',
                        style: OmaType.semibold(12, OmaColors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$balance баллов',
                    style: OmaType.bold(32, OmaColors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Идеи и предложения для вашего дома. Условия участия в официальной программе.',
                    style: OmaType.regular(15, OmaColors.muted).copyWith(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Моя программа лояльности',
                    style: OmaType.regular(15, OmaColors.ink).copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OmaColors.line),
      ),
      child: InkWell(
        onTap: () => context.go(AppRoutes.catalog),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OmaIcon(OmaIcons.lamp, size: 22),
              const SizedBox(height: 12),
              Text(
                'Больше света и уюта',
                style: OmaType.bold(20, OmaColors.ink).copyWith(height: 1.25),
              ),
              const SizedBox(height: 12),
              Text(
                'Подберите освещение, текстиль и товары для хранения к холодному сезону.',
                style: OmaType.regular(15, OmaColors.muted).copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Смотреть сезонную подборку',
                style: OmaType.regular(15, OmaColors.ink).copyWith(height: 1.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Иллюстративная подборка, без заявленных скидок',
                style: OmaType.regular(13, OmaColors.muted).copyWith(
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta();

  @override
  Widget build(BuildContext context) {
    return const _RedCartButton();
  }
}

class _RedCartButton extends StatelessWidget {
  const _RedCartButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.cart),
          borderRadius: BorderRadius.circular(28),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: OmaIcon(
              OmaIcons.cart,
              size: 28,
              color: OmaColors.cartRed,
            ),
          ),
        ),
      ),
    );
  }
}
