import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';
import 'package:oma/widgets/oma_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasHome = context.watch<PropertiesCubit>().state.hasProperty;

    return OmaPage(
      header: const OmaHomeHeader(),
      children: [
        OmaSearchBar(onTap: () => context.go(AppRoutes.catalog)),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final label in [
                'Шуруповерты',
                'Смесители',
                'Стройматериалы',
              ]) ...[
                _Chip(
                  label: label,
                  onTap: () => context.go(AppRoutes.catalog),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const _BannerImage(asset: OmaImages.homeStories, aspectRatio: 543 / 205),
        Text(
          'Акции и предложения',
          style: OmaType.regular(11, OmaColors.muted),
        ),
        const _BannerImage(asset: OmaImages.homeHalva, aspectRatio: 543 / 214),
        Material(
          color: OmaColors.white,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () {
              if (hasHome) {
                context.push(AppRoutes.myHome);
              } else {
                context.push(AppRoutes.onboarding);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: OmaColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: OmaColors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const OmaIcon(OmaIcons.house, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ОМА ДОМ / Мой дом',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmaType.bold(15, OmaColors.blue),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasHome
                                ? 'Техника, задачи и паспорт дома'
                                : 'Создайте объект и начните подбор',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: OmaType.regular(13, OmaColors.ink),
                          ),
                        ],
                      ),
                    ),
                    const OmaIcon(OmaIcons.chevronRight, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
        const _BannerImage(asset: OmaImages.homePosuda, aspectRatio: 543 / 221),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: OmaColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(label, style: OmaType.bold(12, OmaColors.black)),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.asset, required this.aspectRatio});

  final String asset;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return ColoredBox(
              color: OmaColors.blueSoft,
              child: Center(
                child: Text(
                  'Баннер',
                  style: OmaType.regular(13, OmaColors.muted),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
