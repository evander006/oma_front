import 'dart:convert';

import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/order.dart';
import 'package:oma/shared/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OrdersRepository {
  OrdersRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'oma_orders_v1';
  static const _uuid = Uuid();

  List<Order> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final items = (m['items'] as List<dynamic>).map((rawItem) {
          final i = rawItem as Map<String, dynamic>;
          return CartItem(
            product: Product(
              id: i['productId'] as String,
              name: i['name'] as String,
              category: '',
              description: '',
              specs: const {},
              priceByn: (i['priceByn'] as num?)?.toDouble(),
            ),
            qty: i['qty'] as int? ?? 1,
          );
        }).toList();
        return Order(
          id: m['id'] as String,
          createdAt: DateTime.parse(m['createdAt'] as String),
          items: items,
          totalByn: (m['totalByn'] as num).toDouble(),
          status: OrderStatus.values.byName(m['status'] as String),
          note: m['note'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Order> place({
    required List<CartItem> items,
    required double totalByn,
    InstallationOption? installation,
    String? note,
  }) async {
    final order = Order(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      items: List.unmodifiable(items),
      totalByn: totalByn,
      installation: installation,
      note: note,
    );
    final all = [order, ...load()];
    await _prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
    return order;
  }
}
