import 'package:flutter/material.dart';
import 'package:oma/shared/models/master.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_controls.dart';

class MastersContent extends StatelessWidget {
  const MastersContent({
    required this.children,
    this.maxWidth = 820,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 16),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class MasterAvatar extends StatelessWidget {
  const MasterAvatar({required this.name, this.size = 48, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'М' : name.trim().characters.first;
    return Semantics(
      label: 'Профиль мастера $name',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: OmaColors.blueSoft,
          shape: BoxShape.circle,
        ),
        child: Text(initial, style: OmaType.bold(size * 0.38, OmaColors.blue)),
      ),
    );
  }
}

class MasterCard extends StatelessWidget {
  const MasterCard({
    required this.profile,
    required this.onTap,
    required this.onFavorite,
    super.key,
  });

  final MasterProfile profile;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Открыть профиль: ${profile.displayName}',
      child: OmaSurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MasterAvatar(name: profile.displayName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OmaType.bold(16, OmaColors.ink),
                      ),
                      Text(
                        profile.city,
                        style: OmaType.regular(12, OmaColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: profile.isFavorite
                      ? 'Убрать из моих мастеров'
                      : 'Сохранить в мои мастера',
                  onPressed: onFavorite,
                  icon: Icon(
                    profile.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        profile.isFavorite ? OmaColors.orange : OmaColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final specialty in profile.specialties.take(3))
                  OmaBadge(label: specialty),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              profile.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: OmaType.regular(13, OmaColors.muted),
            ),
            const SizedBox(height: 10),
            Text(
              [
                '${profile.experienceYears} лет опыта',
                if (profile.rating != null)
                  '${profile.rating!.toStringAsFixed(1)} · ${profile.reviewCount} отзывов',
              ].join(' · '),
              style: OmaType.semibold(12, OmaColors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkRequestCard extends StatelessWidget {
  const WorkRequestCard({
    required this.request,
    this.actions = const [],
    this.showMaster = true,
    this.onOpenProduct,
    super.key,
  });

  final MasterWorkRequest request;
  final List<Widget> actions;
  final bool showMaster;
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return OmaSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: OmaType.bold(15, OmaColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              OmaBadge(
                label: request.status.labelRu,
                cream: request.status == MasterRequestStatus.materialsProposed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showMaster)
            Text(
              request.masterName,
              style: OmaType.semibold(13, OmaColors.blue),
            ),
          Text(
            [
              ?request.propertyName,
              ?request.roomName,
              _dateLabel(request.createdAt),
            ].join(' · '),
            style: OmaType.regular(12, OmaColors.muted),
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: OmaType.regular(13, OmaColors.ink),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            request.sharedFields.isEmpty
                ? 'Данные жилья не переданы'
                : 'Открыто мастеру: ${request.sharedFields.map((field) => field.labelRu).join(', ')}',
            style: OmaType.regular(11, OmaColors.muted),
          ),
          if (request.materialProposal.isNotEmpty) ...[
            const SizedBox(height: 12),
            MaterialProposalBlock(
              request: request,
              onOpenProduct: onOpenProduct,
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              actions[index],
            ],
          ],
        ],
      ),
    );
  }
}

class MaterialProposalBlock extends StatelessWidget {
  const MaterialProposalBlock({
    required this.request,
    this.onOpenProduct,
    super.key,
  });

  final MasterWorkRequest request;
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(OmaRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Предложение материалов ОМА',
              style: OmaType.semibold(13, OmaColors.ink),
            ),
            const SizedBox(height: 8),
            for (final item in request.materialProposal) ...[
              InkWell(
                onTap: item.productId.isEmpty || onOpenProduct == null
                    ? null
                    : () => onOpenProduct!(item.productId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} × ${item.quantity}',
                          style: OmaType.regular(12, OmaColors.ink),
                        ),
                      ),
                      Text(
                        item.unitPriceByn == null
                            ? 'Цена уточняется'
                            : '${item.lineTotal.toStringAsFixed(2)} BYN',
                        style: OmaType.semibold(12, OmaColors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (request.materialProposal.any(
              (item) => item.unitPriceByn != null,
            )) ...[
              const Divider(color: OmaColors.line),
              Text(
                'Итого: ${request.proposalTotal.toStringAsFixed(2)} BYN',
                textAlign: TextAlign.right,
                style: OmaType.bold(13, OmaColors.ink),
              ),
            ],
            if (request.isDemo) ...[
              const SizedBox(height: 6),
              Text(
                'Демонстрационное предложение — не является сметой.',
                style: OmaType.regular(10, OmaColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}
