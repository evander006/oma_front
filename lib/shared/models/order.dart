import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/installation_option.dart';

enum OrderStatus { draft, placed, completed }

class Order extends Equatable {
  const Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.totalByn,
    this.status = OrderStatus.placed,
    this.installation,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final double totalByn;
  final OrderStatus status;
  final InstallationOption? installation;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'items': items
            .map((e) => {
                  'productId': e.product.id,
                  'name': e.product.name,
                  'priceByn': e.product.priceByn,
                  'qty': e.qty,
                })
            .toList(),
        'totalByn': totalByn,
        'status': status.name,
        'installationId': installation?.id,
        'note': note,
      };

  @override
  List<Object?> get props => [id, createdAt, items, totalByn, status];
}
