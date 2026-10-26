import 'package:oma/core/data/mappers/product_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/order.dart';
import 'package:oma/shared/models/product.dart';

class CartSnapshot {
  const CartSnapshot({
    required this.items,
    required this.total,
    this.currency = 'BYN',
  });

  final List<CartItem> items;
  final double total;
  final String currency;
}

abstract class CommerceRepository {
  Future<List<Product>> favorites();
  Future<void> addFavorite(String productId);
  Future<void> removeFavorite(String productId);

  Future<CartSnapshot> cart();
  Future<CartSnapshot> addToCart(String productId, {int qty = 1});
  Future<CartSnapshot> removeFromCart(String productId);

  Future<Order> placeOrder({
    bool fromCart = true,
    String? installationServiceId,
    String? notes,
  });

  Future<List<Order>> orders();
}

class RemoteCommerceRepository implements CommerceRepository {
  RemoteCommerceRepository(this._client);

  final DioClient _client;

  @override
  Future<List<Product>> favorites() async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/favorites',
    );
    return data
        .whereType<Map>()
        .map((e) {
          final product = e['product'];
          if (product is Map) {
            return ProductMapper.fromJson(Map<String, dynamic>.from(product));
          }
          return null;
        })
        .whereType<Product>()
        .toList(growable: false);
  }

  @override
  Future<void> addFavorite(String productId) async {
    await _client.post('${ApiConfig.apiPrefix}/favorites/$productId');
  }

  @override
  Future<void> removeFavorite(String productId) async {
    await _client.delete('${ApiConfig.apiPrefix}/favorites/$productId');
  }

  @override
  Future<CartSnapshot> cart() async {
    final data = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/cart',
    );
    return _parseCart(data);
  }

  @override
  Future<CartSnapshot> addToCart(String productId, {int qty = 1}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/cart/items',
      data: {'product_id': productId, 'quantity': qty},
    );
    return _parseCart(data);
  }

  @override
  Future<CartSnapshot> removeFromCart(String productId) async {
    final data = await _client.delete<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/cart/items/$productId',
    );
    return _parseCart(data);
  }

  @override
  Future<Order> placeOrder({
    bool fromCart = true,
    String? installationServiceId,
    String? notes,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/orders',
      data: {
        'from_cart': fromCart,
        'product_ids': <String>[],
        if (installationServiceId != null)
          'installation_service_id': int.tryParse(installationServiceId),
        if (notes != null) 'notes': notes,
      },
    );
    return _parseOrder(data);
  }

  @override
  Future<List<Order>> orders() async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/orders',
    );
    return data
        .whereType<Map>()
        .map((e) => _parseOrder(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  CartSnapshot _parseCart(Map<String, dynamic> data) {
    final items = <CartItem>[];
    for (final raw in data['items'] as List<dynamic>? ?? const []) {
      if (raw is! Map) continue;
      final productRaw = raw['product'];
      if (productRaw is! Map) continue;
      final product =
          ProductMapper.fromJson(Map<String, dynamic>.from(productRaw));
      items.add(
        CartItem(
          product: product,
          qty: (raw['quantity'] as num?)?.toInt() ?? 1,
        ),
      );
    }
    return CartSnapshot(
      items: items,
      total: _toDouble(data['total']) ?? 0,
      currency: '${data['currency'] ?? 'BYN'}',
    );
  }

  Order _parseOrder(Map<String, dynamic> data) {
    final items = <CartItem>[];
    for (final raw in data['items'] as List<dynamic>? ?? const []) {
      if (raw is! Map) continue;
      items.add(
        CartItem(
          product: Product(
            id: '${raw['product_id']}',
            name: 'Товар ${raw['product_id']}',
            category: '',
            description: '',
            specs: const {},
            priceByn: _toDouble(raw['unit_price']),
          ),
          qty: (raw['quantity'] as num?)?.toInt() ?? 1,
        ),
      );
    }
    return Order(
      id: '${data['id']}',
      createdAt: DateTime.now(),
      items: items,
      totalByn: _toDouble(data['total_amount']) ?? 0,
      status: OrderStatus.placed,
      note: data['notes']?.toString(),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
