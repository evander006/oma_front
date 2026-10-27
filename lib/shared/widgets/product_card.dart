import 'package:flutter/material.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/shared/widgets/product_image.dart';
import 'package:oma/theme/oma_theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    this.onAdd,
    this.compact = false,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OmaColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImage(
                    product: product,
                    width: compact ? 64 : 85,
                    height: compact ? 64 : 110,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: OmaType.medium(14, OmaColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.priceLabel,
                        style: OmaType.bold(16, OmaColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Цена из каталога · ${product.currency}',
                        style: OmaType.regular(11, OmaColors.muted),
                      ),
                      if (onAdd != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onAdd,
                            style: TextButton.styleFrom(
                              foregroundColor: OmaColors.blue,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'В корзину',
                              style: OmaType.semibold(13, OmaColors.blue),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
