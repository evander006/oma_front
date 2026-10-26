import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/commerce_repository.dart';
import 'package:oma/shared/models/product.dart';

class FavoritesState extends Equatable {
  const FavoritesState({this.items = const [], this.loading = false});

  final List<Product> items;
  final bool loading;

  bool contains(String id) => items.any((e) => e.id == id);

  @override
  List<Object?> get props => [items, loading];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({CommerceRepository? commerce})
      : _commerce = commerce,
        super(const FavoritesState());

  final CommerceRepository? _commerce;

  Future<void> hydrate() async {
    final commerce = _commerce;
    if (commerce == null) return;
    try {
      emit(FavoritesState(items: state.items, loading: true));
      final items = await commerce.favorites();
      emit(FavoritesState(items: items));
    } catch (_) {
      emit(FavoritesState(items: state.items));
    }
  }

  Future<void> toggle(Product product) async {
    final commerce = _commerce;
    if (commerce == null) {
      if (state.contains(product.id)) {
        emit(FavoritesState(
          items: state.items.where((e) => e.id != product.id).toList(),
        ));
      } else {
        emit(FavoritesState(items: [...state.items, product]));
      }
      return;
    }
    try {
      if (state.contains(product.id)) {
        await commerce.removeFavorite(product.id);
        emit(FavoritesState(
          items: state.items.where((e) => e.id != product.id).toList(),
        ));
      } else {
        await commerce.addFavorite(product.id);
        emit(FavoritesState(items: [...state.items, product]));
      }
    } catch (_) {
      // keep previous state
    }
  }
}
