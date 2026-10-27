import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/commerce_repository.dart';
import 'package:oma/core/repositories/orders_repository.dart';
import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/order.dart';

class OrdersState extends Equatable {
  const OrdersState({this.orders = const [], this.loading = false, this.error});

  final List<Order> orders;
  final bool loading;
  final String? error;

  @override
  List<Object?> get props => [orders, loading, error];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo, {CommerceRepository? commerce})
      : _commerce = commerce,
        super(const OrdersState()) {
    reload();
  }

  final OrdersRepository _repo;
  final CommerceRepository? _commerce;

  Future<void> reload() async {
    final commerce = _commerce;
    if (commerce == null) {
      emit(OrdersState(orders: _repo.load()));
      return;
    }
    emit(OrdersState(orders: state.orders, loading: true));
    try {
      final remote = await commerce.orders();
      emit(OrdersState(orders: remote));
    } catch (e) {
      emit(OrdersState(orders: _repo.load(), error: '$e'));
    }
  }

  Future<Order> place({
    required List<CartItem> items,
    required double totalByn,
    InstallationOption? installation,
    String? note,
  }) async {
    final commerce = _commerce;
    if (commerce != null) {
      final order = await commerce.placeOrder(
        fromCart: true,
        installationServiceId: installation?.id,
        notes: note,
      );
      await reload();
      return order;
    }
    final order = await _repo.place(
      items: items,
      totalByn: totalByn,
      installation: installation,
      note: note,
    );
    emit(OrdersState(
      orders: [order, ...state.orders.where((o) => o.id != order.id)],
    ));
    return order;
  }
}
