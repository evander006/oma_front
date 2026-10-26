import 'package:oma/core/network/api_config.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/product.dart';

abstract final class ProductMapper {
  static Product fromJson(Map<String, dynamic> json) {
    final specsList = json['specifications'] as List<dynamic>? ?? const [];
    final specs = <String, String>{};
    for (final s in specsList) {
      if (s is! Map) continue;
      final name = '${s['name'] ?? ''}';
      final value = '${s['value'] ?? ''}';
      final unit = s['unit'];
      if (name.isEmpty) continue;
      specs[name] = unit == null || '$unit'.isEmpty ? value : '$value $unit';
    }

    final model = json['model_3d'];
    String? modelUrl;
    if (model is Map && model['url'] != null) {
      modelUrl = ApiConfig.absoluteUrl('${model['url']}');
    }

    final primary = json['primary_image_url'] as String?;
    final imageUrl = ApiConfig.absoluteUrl(primary);

    return Product(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      category: '${json['category_id'] ?? json['subcategory'] ?? ''}',
      description: '${json['description'] ?? ''}',
      specs: specs,
      priceByn: _num(json['price']),
      imageAsset: 'assets/images/img_icon.png',
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      model3dUrl: modelUrl,
      sku: json['sku']?.toString(),
      brand: json['brand']?.toString(),
      currency: '${json['currency'] ?? 'BYN'}',
      has3dModel: json['has_3d_model'] == true,
      installHint: 'Платная услуга · Стоимость уточняется',
    );
  }

  static InstallationOption installationFromJson(Map<String, dynamic> json) {
    return InstallationOption(
      id: '${json['id']}',
      title: '${json['name'] ?? ''}',
      subtitle: json['description']?.toString(),
      priceFromByn: _num(json['price']) ?? 0,
    );
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
