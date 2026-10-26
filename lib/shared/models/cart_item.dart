import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/product.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.product,
    this.qty = 1,
  });

  final Product product;
  final int qty;

  double get lineTotal => (product.priceByn ?? 0) * qty;

  CartItem copyWith({int? qty}) => CartItem(product: product, qty: qty ?? this.qty);

  @override
  List<Object?> get props => [product, qty];
}
