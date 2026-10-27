import 'package:dio/dio.dart';
import 'package:oma/core/data/mappers/product_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/ai_assistant/domain/ai_design_models.dart';
import 'package:oma/shared/models/product.dart';

class AiDesignUnavailable implements Exception {
  const AiDesignUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiDesignRepository {
  AiDesignRepository(this._client, this._catalog);

  final DioClient _client;
  final CatalogRepository _catalog;

  Future<AiDesignCapabilities> capabilities() async {
    final data = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/capabilities',
    );
    final vision = _map(data['vision_language']);
    return AiDesignCapabilities(
      supportsImageInput: vision['supports_image_input'] == true,
      provider: '${vision['provider'] ?? 'не настроен'}',
      model: '${vision['model'] ?? 'не указан'}',
      privacyNotice: data['privacy']?.toString(),
    );
  }

  Future<AiDesignSourceResult> analyzeRoom({
    required String roomId,
    required InteriorImageSelection image,
    required String prompt,
    required List<String> categoryIds,
    String? roomType,
    String? style,
    double? budgetByn,
  }) async {
    final numericRoomId = int.tryParse(roomId);
    if (numericRoomId == null) {
      throw const AiDesignUnavailable(
        'Комната хранится локально и пока не может принять фото на backend.',
      );
    }

    final caps = await capabilities();
    if (!caps.supportsImageInput) {
      throw const AiDesignUnavailable(
        'Backend сообщил, что vision-анализ изображений недоступен.',
      );
    }

    final upload = await _client.dio.post<dynamic>(
      '${ApiConfig.apiPrefix}/rooms/$numericRoomId/photos',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          image.bytes,
          filename: image.name,
          contentType: DioMediaType.parse(image.mimeType),
        ),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    final uploaded = _map(upload.data);
    final photoId = _int(uploaded['id']);
    if (photoId == null) {
      throw const AiDesignUnavailable('Backend не вернул id загруженного фото.');
    }

    final analysis = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/analyze-room',
      data: {
        'room_id': numericRoomId,
        'photo_ids': [photoId],
        'prompt': prompt,
        'category_ids': categoryIds,
        if (roomType != null) 'room_type': roomType,
        if (style != null) 'style': style,
        if (budgetByn != null) 'budget': budgetByn,
      },
    );
    final recommendations = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/recommendations/from-room',
      data: {
        'room_id': numericRoomId,
        'photo_ids': [photoId],
        'prompt': prompt,
        'category_ids': categoryIds,
        'limit': 12,
        if (style != null) 'preferred_style': style,
        if (budgetByn != null) 'max_budget': budgetByn,
      },
    );

    final products = await _productsFromRecommendations(recommendations);
    if (products.isEmpty) {
      throw const AiDesignUnavailable(
        'Vision-анализ выполнен, но не нашёл подходящих товаров в каталоге.',
      );
    }

    final provider = '${analysis['provider'] ?? caps.provider}';
    final model = '${analysis['model_id'] ?? caps.model}';
    return AiDesignSourceResult(
      mode: AiDesignSelectionMode.vision,
      products: products,
      summary: '${analysis['summary'] ?? 'Фото комнаты проанализировано.'}',
      notice:
          'Фото обработано провайдером $provider ($model). Результат носит рекомендательный характер; размеры и совместимость проверьте перед покупкой.',
      provider: '$provider · $model',
      photoId: photoId,
    );
  }

  Future<AiDesignSourceResult> catalogFallback({
    required List<String> categoryIds,
    String? reason,
  }) async {
    final batches = <List<Product>>[];
    for (final categoryId in categoryIds.take(5)) {
      try {
        batches.add(
          await _catalog.products(
            categoryId: categoryId,
            sort: 'price',
            pageSize: 20,
          ),
        );
      } catch (_) {
        // A category may be empty in the small snapshot; general catalog follows.
      }
    }
    if (batches.isEmpty || batches.every((items) => items.isEmpty)) {
      batches.add(await _catalog.products(sort: 'price', pageSize: 60));
    }
    final products = <Product>[];
    final seen = <String>{};
    for (final batch in batches) {
      for (final product in batch) {
        if (seen.add(product.id)) products.add(product);
      }
    }
    return AiDesignSourceResult(
      mode: AiDesignSelectionMode.catalogFallback,
      products: products,
      summary:
          'Показан детерминированный подбор из доступных товаров каталога ОМА.',
      notice:
          'Демонстрационный режим: содержимое фото не анализировалось${reason == null || reason.isEmpty ? '' : '. Причина: $reason'}.',
    );
  }

  Future<int?> createDesignSession({
    required String roomId,
    required String title,
    String? style,
    double? budgetByn,
  }) async {
    final numericRoomId = int.tryParse(roomId);
    if (numericRoomId == null) return null;
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/design-sessions',
      data: {
        'room_id': numericRoomId,
        'title': title,
        if (style != null) 'style': style,
        if (budgetByn != null) 'budget': budgetByn,
      },
    );
    return _int(data['id']);
  }

  Future<List<Product>> _productsFromRecommendations(
    Map<String, dynamic> data,
  ) async {
    final rows = <dynamic>[
      ...(data['recommendations'] as List<dynamic>? ?? const []),
      ...(data['alternatives'] as List<dynamic>? ?? const []),
    ];
    final products = <Product>[];
    final seen = <String>{};
    for (final row in rows.whereType<Map>()) {
      final productRaw = row['product'];
      Product? product;
      if (productRaw is Map) {
        product = ProductMapper.fromJson(Map<String, dynamic>.from(productRaw));
      } else {
        final id = row['product_id']?.toString();
        if (id != null && id.isNotEmpty) product = await _catalog.byId(id);
      }
      if (product != null && seen.add(product.id)) products.add(product);
    }
    return products;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}
