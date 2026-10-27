import 'package:oma/core/data/mappers/product_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/chat_message.dart';
import 'package:oma/shared/models/product.dart';
import 'package:uuid/uuid.dart';

class AiChatResult {
  const AiChatResult({
    required this.reply,
    required this.sessionId,
    this.products = const [],
  });

  final ChatMessage reply;
  final int? sessionId;
  final List<Product> products;
}

abstract class AiChatRepository {
  ChatMessage userMessage(String text);
  ChatMessage assistantMessage(String text);

  Future<AiChatResult> chat({
    required String message,
    int? sessionId,
    int? roomId,
    double? budget,
    String? style,
  });

  /// Catalog-grounded recommendations (`POST /ai/recommendations`).
  Future<AiChatResult> recommend({
    required String prompt,
    double? maxBudget,
    String? preferredStyle,
    List<String> categoryIds = const [],
    int limit = 6,
  });
}

class MockAiChatRepository implements AiChatRepository {
  static const _uuid = Uuid();

  @override
  ChatMessage userMessage(String text) {
    return ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: text.trim(),
      at: DateTime.now(),
    );
  }

  @override
  ChatMessage assistantMessage(String text) {
    return ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      text: text.trim(),
      at: DateTime.now(),
    );
  }

  @override
  Future<AiChatResult> chat({
    required String message,
    int? sessionId,
    int? roomId,
    double? budget,
    String? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final lower = message.toLowerCase();
    final String answer;
    if (lower.contains('смесит') || lower.contains('кран')) {
      answer =
          'Для кухни подойдёт смеситель с гибким изливом. Откройте карточку и добавьте установку отдельно.';
    } else if (lower.contains('свет') || lower.contains('освещ')) {
      answer =
          'Для кухни можно подобрать подсветку рабочей зоны. Смотрите категорию освещения в каталоге.';
    } else {
      answer =
          'Я подскажу по выбору товаров для дома. Опишите задачу или бюджет — подберу варианты из каталога.';
    }
    return AiChatResult(
      reply: assistantMessage(answer),
      sessionId: sessionId,
    );
  }

  @override
  Future<AiChatResult> recommend({
    required String prompt,
    double? maxBudget,
    String? preferredStyle,
    List<String> categoryIds = const [],
    int limit = 6,
  }) {
    return chat(message: prompt, budget: maxBudget, style: preferredStyle);
  }
}

class RemoteAiChatRepository implements AiChatRepository {
  RemoteAiChatRepository(this._client, {this.catalogByIds});

  final DioClient _client;
  final Future<List<Product>> Function(List<String> ids)? catalogByIds;
  static const _uuid = Uuid();

  @override
  ChatMessage userMessage(String text) {
    return ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: text.trim(),
      at: DateTime.now(),
    );
  }

  @override
  ChatMessage assistantMessage(String text) {
    return ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      text: text.trim(),
      at: DateTime.now(),
    );
  }

  @override
  Future<AiChatResult> chat({
    required String message,
    int? sessionId,
    int? roomId,
    double? budget,
    String? style,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/chat',
      data: {
        'message': message,
        'session_id': sessionId,
        'room_id': roomId,
        'photo_ids': <int>[],
        if (budget != null) 'budget': budget,
        if (style != null) 'style': style,
      },
    );
    final ids = (data['product_ids'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toList();
    var products = <Product>[];
    if (ids.isNotEmpty && catalogByIds != null) {
      products = await catalogByIds!(ids);
    }
    return AiChatResult(
      reply: assistantMessage('${data['reply'] ?? ''}'),
      sessionId: (data['session_id'] as num?)?.toInt(),
      products: products,
    );
  }

  @override
  Future<AiChatResult> recommend({
    required String prompt,
    double? maxBudget,
    String? preferredStyle,
    List<String> categoryIds = const [],
    int limit = 6,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/ai/recommendations',
      data: {
        'prompt': prompt,
        'budget': maxBudget,
        'style': preferredStyle,
        'category_ids': categoryIds,
        'limit': limit,
      },
    );
    var products = productsFromRecommendationPayload(data);
    if (products.isEmpty) {
      final ids = (data['product_ids'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList();
      if (ids.isNotEmpty && catalogByIds != null) {
        products = await catalogByIds!(ids);
      }
    }
    final summary = data['summary'] ?? data['reply'] ?? 'Подборка из каталога OMA.';
    return AiChatResult(
      reply: assistantMessage('$summary'),
      sessionId: (data['session_id'] as num?)?.toInt(),
      products: products,
    );
  }
}

/// Optional helper when product payloads come embedded in recommendations.
List<Product> productsFromRecommendationPayload(Map<String, dynamic> data) {
  final list = data['recommendations'] as List<dynamic>? ?? const [];
  return list
      .whereType<Map>()
      .map((e) {
        final p = e['product'];
        if (p is Map) {
          return ProductMapper.fromJson(Map<String, dynamic>.from(p));
        }
        return null;
      })
      .whereType<Product>()
      .toList(growable: false);
}
