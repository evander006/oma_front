import 'package:flutter/material.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/theme/oma_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Product product;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: OmaColors.blueSoft,
      child: SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.image_outlined, color: OmaColors.blue),
        ),
      ),
    );

    if (product.hasNetworkImage) {
      return Image.network(
        product.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          product.imageAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    return Image.asset(
      product.imageAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
