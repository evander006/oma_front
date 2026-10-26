import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/favorites/cubit/favorites_cubit.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_icon.dart';

void omaBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

class OmaShell extends StatelessWidget {
  const OmaShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartCubit>().state.count;
    final favCount = context.watch<FavoritesCubit>().state.items.length;

    return ColoredBox(
      color: OmaColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: OmaColors.background,
            body: navigationShell,
            bottomNavigationBar: OmaBottomNav(
              currentIndex: navigationShell.currentIndex,
              cartCount: cartCount,
              favoritesCount: favCount,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OmaBottomNav extends StatelessWidget {
  const OmaBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.favoritesCount = 0,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final int favoritesCount;

  static const _labels = [
    'Главная',
    'Каталог',
    'Корзина',
    'Избранное',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: OmaColors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: OmaColors.line)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 8 + bottom),
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: _Tab(
                    label: _labels[i],
                    icon: _icon(i, i == currentIndex),
                    selected: i == currentIndex,
                    badge: i == 2
                        ? cartCount
                        : i == 3
                            ? favoritesCount
                            : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _icon(int index, bool selected) {
    return switch (index) {
      0 => selected ? OmaIcons.navHome : OmaIcons.navHomeIdle,
      1 => selected ? OmaIcons.navSearchActive : OmaIcons.navSearch,
      2 => selected ? OmaIcons.navBagActive : OmaIcons.navBag,
      3 => OmaIcons.navHeart,
      _ => selected ? OmaIcons.navUserActive : OmaIcons.navUser,
    };
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                OmaIcon(icon, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: OmaColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: OmaType.bold(9, OmaColors.ink),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: selected
                  ? OmaType.semibold(10, OmaColors.orange)
                  : OmaType.regular(10, OmaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class OmaHomeHeader extends StatelessWidget {
  const OmaHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: OmaColors.line)),
        ),
        child: Row(
          children: [
            const OmaLogo(),
            const Spacer(),
            Text('Минск ›', style: OmaType.bold(16, OmaColors.ink)),
          ],
        ),
      ),
    );
  }
}

class OmaFlowHeader extends StatelessWidget {
  const OmaFlowHeader({
    required this.title,
    this.eyebrow = 'ОМА. Событие · демо',
    super.key,
  });

  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: OmaColors.line)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => omaBack(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: OmaIcon(OmaIcons.chevronLeft, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmaType.regular(10, OmaColors.muted),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmaType.bold(16, OmaColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const OmaIcon(OmaIcons.ellipsis, size: 20),
          ],
        ),
      ),
    );
  }
}

class OmaPage extends StatelessWidget {
  const OmaPage({
    required this.children,
    this.header,
    this.actions = const [],
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget? header;
  final List<Widget> children;
  final List<Widget> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmaColors.background,
      body: SafeArea(
        bottom: actions.isEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Expanded(
              child: ListView(
                padding: padding,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    children[i],
                  ],
                ],
              ),
            ),
            if (actions.isNotEmpty)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: OmaColors.white,
                  border: Border(top: BorderSide(color: OmaColors.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
