import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/loyalty_repository.dart';
import 'package:oma/shared/models/loyalty.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltyAccount>(
      future: context.read<LoyaltyRepository>().account(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const OmaPage(
            header: OmaFlowHeader(title: 'Лояльность'),
            children: [Center(child: CircularProgressIndicator())],
          );
        }
        final account = snap.data!;
        return OmaPage(
          header: const OmaFlowHeader(title: 'Бонусная программа'),
          children: [
            if (account.demo)
              const OmaInfoNote(
                text:
                    'Демо-данные. Официальные правила начисления и списания будут подключены из документации/API OMA.',
                cream: true,
              ),
            OmaSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Баланс', style: OmaType.regular(13, OmaColors.muted)),
                  Text(
                    '${account.balance} баллов',
                    style: OmaType.bold(28, OmaColors.ink),
                  ),
                  const SizedBox(height: 4),
                  OmaBadge(label: 'Уровень: ${account.tier}'),
                ],
              ),
            ),
            Text('Как это работает', style: OmaType.bold(18, OmaColors.ink)),
            Text(
              'Баллы начисляются за покупки и услуги (демо). Списание — на скидки и сервисы. Точные коэффициенты уточняются.',
              style: OmaType.regular(13, OmaColors.muted),
            ),
            Text('Доступные награды', style: OmaType.bold(18, OmaColors.ink)),
            for (final r in account.rewards)
              OmaSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: OmaType.semibold(15, OmaColors.ink)),
                    if (r.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(r.subtitle!, style: OmaType.regular(12, OmaColors.muted)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${r.costPoints} баллов',
                      style: OmaType.bold(14, OmaColors.blue),
                    ),
                  ],
                ),
              ),
            Text('История', style: OmaType.bold(18, OmaColors.ink)),
            for (final e in account.history)
              OmaDataRow(
                label: e.title,
                value: e.points > 0 ? '+${e.points}' : '${e.points}',
                valueStyle: OmaType.semibold(
                  13,
                  e.points >= 0 ? OmaColors.green : OmaColors.danger,
                ),
              ),
          ],
        );
      },
    );
  }
}
