import 'package:equatable/equatable.dart';

class RoomItem extends Equatable {
  const RoomItem({
    required this.id,
    required this.productId,
    required this.name,
    this.qty = 1,
    this.note,
  });

  final String id;
  final String productId;
  final String name;
  final int qty;
  final String? note;

  RoomItem copyWith({int? qty, String? note}) {
    return RoomItem(
      id: id,
      productId: productId,
      name: name,
      qty: qty ?? this.qty,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'qty': qty,
        'note': note,
      };

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    return RoomItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      qty: json['qty'] as int? ?? 1,
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, productId, name, qty, note];
}
