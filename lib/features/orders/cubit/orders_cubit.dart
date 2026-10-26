import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/orders_repository.dart';
import 'package:oma/shared/models/cart_item.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/order.dart';

class OrdersState extends Equatable {
  const OrdersState({this.orders = const []});

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo) : super(const OrdersState()) {
    emit(OrdersState(orders: _repo.load()));
  }

  final OrdersRepository _repo;

  Future<Order> place({
    required List<CartItem> items,
    required double totalByn,
    InstallationOption? installation,
    String? note,
  }) async {
    final order = await _repo.place(
      items: items,
      totalByn: totalByn,
      installation: installation,
      note: note,
    );
    emit(OrdersState(orders: [order, ...state.orders.where((o) => o.id != order.id)]));
    return order;
  }

  void reload() => emit(OrdersState(orders: _repo.load()));
}
