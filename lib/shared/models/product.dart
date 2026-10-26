import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.specs,
    required this.priceByn,
    this.imageAsset = 'assets/images/img_icon.png',
    this.imageUrl,
    this.model3dAsset,
    this.model3dUrl,
    this.sku,
    this.brand,
    this.currency = 'BYN',
    this.has3dModel = false,
    this.installHint,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final Map<String, String> specs;
  final double? priceByn;
  final String imageAsset;
  final String? imageUrl;
  final String? model3dAsset;
  final String? model3dUrl;
  final String? sku;
  final String? brand;
  final String currency;
  final bool has3dModel;
  final String? installHint;

  String get priceLabel {
    if (priceByn == null) return 'Цена не показана';
    return '${priceByn!.toStringAsFixed(2)} р. / шт';
  }

  bool get hasNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  List<Object?> get props => [id, name, category, priceByn, imageUrl];
}

class CatalogCategory extends Equatable {
  const CatalogCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
