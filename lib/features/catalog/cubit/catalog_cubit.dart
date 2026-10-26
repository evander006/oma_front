import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/network/api_exception.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/shared/models/product.dart';

enum CatalogStatus { initial, loading, ready, failure }

class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.initial,
    this.categories = const [],
    this.products = const [],
    this.categoryId = 'Все',
    this.query = '',
    this.sort = 'name',
    this.error,
  });

  final CatalogStatus status;
  final List<CatalogCategory> categories;
  final List<Product> products;
  final String categoryId;
  final String query;
  final String sort;
  final String? error;

  CatalogState copyWith({
    CatalogStatus? status,
    List<CatalogCategory>? categories,
    List<Product>? products,
    String? categoryId,
    String? query,
    String? sort,
    String? error,
  }) {
    return CatalogState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      categoryId: categoryId ?? this.categoryId,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, categories, products, categoryId, query, sort, error];
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repo) : super(const CatalogState());

  final CatalogRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: CatalogStatus.loading, error: null));
    try {
      final categories = await _repo.categories();
      final products = await _repo.products(
        categoryId: state.categoryId == 'Все' ? null : state.categoryId,
        query: state.query,
        sort: state.sort,
      );
      emit(
        state.copyWith(
          status: CatalogStatus.ready,
          categories: categories,
          products: products,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: CatalogStatus.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: CatalogStatus.failure, error: '$e'));
    }
  }

  Future<void> setCategory(String id) async {
    emit(state.copyWith(categoryId: id));
    await load();
  }

  Future<void> setQuery(String q) async {
    emit(state.copyWith(query: q));
    await load();
  }

  Future<void> setSort(String sort) async {
    emit(state.copyWith(sort: sort));
    await load();
  }
}
