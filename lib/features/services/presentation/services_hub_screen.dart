import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/services_repository.dart';
import 'package:oma/shared/models/home_service.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class ServicesHubScreen extends StatelessWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeService>>(
      future: context.read<ServicesRepository>().all(),
      builder: (context, snap) {
        final services = snap.data ?? const <HomeService>[];
        return OmaPage(
          header: const OmaFlowHeader(
            title: 'Услуги',
            eyebrow: 'Ремонт и монтаж',
            showCart: true,
          ),
          children: [
            OmaSurfaceCard(
              onTap: () => context.push(AppRoutes.turnkey),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ремонт под ключ',
                    style: OmaType.bold(18, OmaColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Пошаговая заявка с фото, бюджетом и материалами OMA.',
                    style: OmaType.regular(13, OmaColors.muted),
                  ),
                  const SizedBox(height: 12),
                  OmaButton(
                    label: 'Рассчитать стоимость',
                    kind: OmaButtonKind.orange,
                    onPressed: () => context.push(AppRoutes.turnkey),
                  ),
                ],
              ),
            ),
            OmaSurfaceCard(
              onTap: () => context.push(AppRoutes.measurer),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вызвать замерщика',
                          style: OmaType.semibold(15, OmaColors.ink),
                        ),
                        Text(
                          'Бесплатный выезд для предварительной оценки',
                          style: OmaType.regular(12, OmaColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: OmaColors.muted),
                ],
              ),
            ),
            Text(
              'Отдельные работы',
              style: OmaType.bold(18, OmaColors.ink),
            ),
            if (snap.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else
              for (final s in services)
                OmaSurfaceCard(
                  onTap: () => context.push(AppRoutes.serviceBookPath(s.id)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: OmaType.semibold(14, OmaColors.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.priceLabel,
                              style: OmaType.regular(
                                12,
                                s.hasVerifiedPrice
                                    ? OmaColors.green
                                    : OmaColors.muted,
                              ),
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
      },
    );
  }
}
