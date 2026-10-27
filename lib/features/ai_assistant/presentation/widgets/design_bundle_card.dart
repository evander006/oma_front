import 'package:flutter/material.dart';
import 'package:oma/features/ai_assistant/domain/ai_design_models.dart';
import 'package:oma/shared/widgets/product_image.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_controls.dart';

class DesignBundleCard extends StatelessWidget {
  const DesignBundleCard({
    required this.bundle,
    required this.selected,
    required this.onSelect,
    required this.onOpenProduct,
    super.key,
  });

  final DesignBundle bundle;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<String> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${bundle.title}, ${bundle.total.toStringAsFixed(2)} BYN',
      child: OmaSurfaceCard(
        selected: selected,
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bundle.title,
                        style: OmaType.bold(17, OmaColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bundle.subtitle,
                        style: OmaType.regular(12, OmaColors.muted),
                      ),
                    ],
                  ),
                ),
                if (selected) const OmaBadge(label: 'Выбрано'),
              ],
            ),
            const SizedBox(height: 14),
            for (final product in bundle.products) ...[
              _BundleProductRow(
                productName: product.name,
                priceLabel: product.priceLabel,
                image: ProductImage(
                  product: product,
                  width: 54,
                  height: 54,
                ),
                onTap: () => onOpenProduct(product.id),
              ),
              const SizedBox(height: 10),
            ],
            const Divider(color: OmaColors.line),
            OmaDataRow(
              label: 'Товары',
              value: '${bundle.productsTotal.toStringAsFixed(2)} BYN',
            ),
            if (bundle.serviceEstimateByn > 0)
              OmaDataRow(
                label: bundle.serviceLabel ?? 'Дополнительная услуга · демо',
                value: 'от ${bundle.serviceEstimateByn.toStringAsFixed(2)} BYN',
              ),
            OmaDataRow(
              label: 'Итого',
              value: '${bundle.total.toStringAsFixed(2)} BYN',
              valueStyle: OmaType.bold(15, OmaColors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              bundle.selectionNote,
              style: OmaType.regular(11, OmaColors.muted),
            ),
            const SizedBox(height: 12),
            OmaButton(
              label: selected ? 'Комплект выбран' : 'Выбрать комплект',
              kind: selected ? OmaButtonKind.primary : OmaButtonKind.secondary,
              onPressed: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleProductRow extends StatelessWidget {
  const _BundleProductRow({
    required this.productName,
    required this.priceLabel,
    required this.image,
    required this.onTap,
  });

  final String productName;
  final String priceLabel;
  final Widget image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OmaType.medium(13, OmaColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      priceLabel,
                      style: OmaType.semibold(12, OmaColors.blue),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: OmaColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
