import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/commerce_repository.dart';
import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/product.dart';

class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.installation,
    this.loading = false,
    this.error,
  });

  final List<CartItem> items;
  final InstallationOption? installation;
  final bool loading;
  final String? error;

  int get count => items.fold(0, (s, e) => s + e.qty);

  double get productsTotal => items.fold(0, (s, e) => s + e.lineTotal);

  double get total => productsTotal + (installation?.priceFromByn ?? 0);

  @override
  List<Object?> get props => [items, installation, loading, error];
}

class CartCubit extends Cubit<CartState> {
  CartCubit({CommerceRepository? commerce})
      : _commerce = commerce,
        super(const CartState());

  final CommerceRepository? _commerce;

  Future<void> hydrate() async {
    final commerce = _commerce;
    if (commerce == null) return;
    try {
      emit(CartState(
        items: state.items,
        installation: state.installation,
        loading: true,
      ));
      final snap = await commerce.cart();
      emit(CartState(items: snap.items, installation: state.installation));
    } catch (e) {
      emit(CartState(
        items: state.items,
        installation: state.installation,
        error: '$e',
      ));
    }
  }

  Future<void> add(Product product, {int qty = 1}) async {
    final commerce = _commerce;
    if (commerce == null) {
      final list = [...state.items];
      final i = list.indexWhere((e) => e.product.id == product.id);
      if (i >= 0) {
        list[i] = list[i].copyWith(qty: list[i].qty + qty);
      } else {
        list.add(CartItem(product: product, qty: qty));
      }
      emit(CartState(items: list, installation: state.installation));
      return;
    }
    try {
      final snap = await commerce.addToCart(product.id, qty: qty);
      emit(CartState(items: snap.items, installation: state.installation));
    } catch (e) {
      emit(CartState(
        items: state.items,
        installation: state.installation,
        error: '$e',
      ));
    }
  }

  Future<void> setQty(String productId, int qty) async {
    if (qty <= 0) {
      await remove(productId);
      return;
    }
    final commerce = _commerce;
    if (commerce == null) {
      final list = state.items
          .map((e) => e.product.id == productId ? e.copyWith(qty: qty) : e)
          .toList();
      emit(CartState(items: list, installation: state.installation));
      return;
    }
    try {
      // API only supports incremental add / delete — rebuild quantity.
      await commerce.removeFromCart(productId);
      final snap = await commerce.addToCart(productId, qty: qty);
      emit(CartState(items: snap.items, installation: state.installation));
    } catch (e) {
      emit(CartState(
        items: state.items,
        installation: state.installation,
        error: '$e',
      ));
    }
  }

  Future<void> remove(String productId) async {
    final commerce = _commerce;
    if (commerce == null) {
      emit(CartState(
        items: state.items.where((e) => e.product.id != productId).toList(),
        installation: state.installation,
      ));
      return;
    }
    try {
      final snap = await commerce.removeFromCart(productId);
      emit(CartState(items: snap.items, installation: state.installation));
    } catch (e) {
      emit(CartState(
        items: state.items,
        installation: state.installation,
        error: '$e',
      ));
    }
  }

  void setInstallation(InstallationOption? option) {
    emit(CartState(items: state.items, installation: option));
  }

  Future<void> clear() async {
    final commerce = _commerce;
    if (commerce == null) {
      emit(const CartState());
      return;
    }
    for (final item in [...state.items]) {
      await commerce.removeFromCart(item.product.id);
    }
    emit(CartState(installation: state.installation));
  }
}
