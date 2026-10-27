import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
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
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = [
    'Главная',
    'Каталог',
    'Услуги',
    'Мои проекты',
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
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _materialIcon(int index, bool selected) {
    return switch (index) {
      0 => selected ? Icons.home_rounded : Icons.home_outlined,
      1 => selected ? Icons.grid_view_rounded : Icons.grid_view_outlined,
      2 => selected ? Icons.handyman_rounded : Icons.handyman_outlined,
      3 => selected ? Icons.folder_rounded : Icons.folder_outlined,
      _ => selected ? Icons.person_rounded : Icons.person_outline,
    };
  }

  String _icon(int index, bool selected) {
    // Prefer SVG assets where they match; material fallback via empty string.
    return switch (index) {
      0 => selected ? OmaIcons.navHome : OmaIcons.navHomeIdle,
      1 => selected ? OmaIcons.navSearchActive : OmaIcons.navSearch,
      2 => '',
      3 => '',
      _ => selected ? OmaIcons.navUserActive : OmaIcons.navUser,
    };
  }

  // Expose material icon for tabs without SVG assets.
  // ignore: unused_element
  Widget buildIcon(int index, bool selected) {
    final asset = _icon(index, selected);
    if (asset.isEmpty) {
      return Icon(
        _materialIcon(index, selected),
        size: 24,
        color: selected ? OmaColors.blue : OmaColors.muted,
      );
    }
    return OmaIcon(asset, size: 24);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? OmaColors.blue : OmaColors.muted;
    Widget iconWidget;
    if (icon.isEmpty) {
      final material = switch (label) {
        'Услуги' =>
          selected ? Icons.handyman_rounded : Icons.handyman_outlined,
        'Мои проекты' =>
          selected ? Icons.folder_rounded : Icons.folder_outlined,
        _ => Icons.circle_outlined,
      };
      iconWidget = Icon(material, size: 24, color: color);
    } else {
      iconWidget = OmaIcon(icon, size: 24);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
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
    final cartCount = context.watch<CartCubit>().state.count;

    return Material(
      color: OmaColors.white,
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.myHome),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '‹ Город',
                    style: OmaType.regular(13, OmaColors.blue),
                  ),
                ),
              ),
              const OmaLogo(),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Уведомления появятся после подключения API',
                      ),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: OmaIcon(OmaIcons.bell, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push(AppRoutes.cart),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: OmaIcon(
                    OmaIcons.cart,
                    size: 22,
                    color: OmaColors.cartRed,
                  ),
                ),
              ),
              if (cartCount > 0) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.cart),
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: OmaColors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: OmaType.bold(11, OmaColors.ink),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OmaFlowHeader extends StatelessWidget {
  const OmaFlowHeader({
    required this.title,
    this.eyebrow = 'ОМА. Дом',
    this.showCart = false,
    super.key,
  });

  final String title;
  final String eyebrow;
  final bool showCart;

  @override
  Widget build(BuildContext context) {
    final cartCount = showCart ? context.watch<CartCubit>().state.count : 0;

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
            if (showCart)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.cart),
                    icon: const OmaIcon(OmaIcons.navBag, size: 22),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: OmaColors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$cartCount',
                          textAlign: TextAlign.center,
                          style: OmaType.bold(9, OmaColors.ink),
                        ),
                      ),
                    ),
                ],
              )
            else
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
