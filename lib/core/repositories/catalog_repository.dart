import 'package:oma/core/data/mock_catalog.dart';
import 'package:oma/core/data/mappers/product_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/product.dart';

abstract class CatalogRepository {
  Future<List<CatalogCategory>> categories();

  Future<List<Product>> products({
    String? categoryId,
    String? query,
    String sort = 'name',
    int page = 1,
    int pageSize = 40,
  });

  Future<Product?> byId(String id);

  Future<List<InstallationOption>> installations();

  /// Sync helper for screens that still call with a product filter.
  List<InstallationOption> installationsFor(Product product) {
    if (product.category.contains('plumbing') ||
        product.category == 'Сантехника') {
      return mockInstallations;
    }
    return const [];
  }
}

class MockCatalogRepository implements CatalogRepository {
  @override
  Future<List<CatalogCategory>> categories() async {
    return mockCategories
        .map((c) => CatalogCategory(id: c, name: c))
        .toList(growable: false);
  }

  @override
  Future<List<Product>> products({
    String? categoryId,
    String? query,
    String sort = 'name',
    int page = 1,
    int pageSize = 40,
  }) async {
    var list = mockProducts;
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'Все') {
      list = list.where((p) => p.category == categoryId).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                (p.sku?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (sort == 'price') {
      list = [...list]
        ..sort((a, b) => (a.priceByn ?? 0).compareTo(b.priceByn ?? 0));
    } else {
      list = [...list]..sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Future<Product?> byId(String id) async {
    try {
      return mockProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<InstallationOption>> installations() async =>
      List.unmodifiable(mockInstallations);

  @override
  List<InstallationOption> installationsFor(Product product) {
    if (product.category != 'Сантехника') return const [];
    return List.unmodifiable(mockInstallations);
  }
}

class RemoteCatalogRepository implements CatalogRepository {
  RemoteCatalogRepository(this._client);

  final DioClient _client;
  final _cache = <String, Product>{};
  List<InstallationOption> _installCache = const [];

  @override
  Future<List<CatalogCategory>> categories() async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/categories',
    );
    return data
        .whereType<Map>()
        .map(
          (e) => CatalogCategory(
            id: '${e['id']}',
            name: '${e['name'] ?? e['id']}',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Product>> products({
    String? categoryId,
    String? query,
    String sort = 'name',
    int page = 1,
    int pageSize = 40,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/products',
      query: {
        'sort': sort,
        'page': page,
        'page_size': pageSize,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null &&
            categoryId.isNotEmpty &&
            categoryId != 'Все')
          'category_id': categoryId,
      },
    );
    final items = data['items'] as List<dynamic>? ?? const [];
    final products = items
        .whereType<Map>()
        .map((e) => ProductMapper.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    for (final p in products) {
      _cache[p.id] = p;
    }
    return products;
  }

  @override
  Future<Product?> byId(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    try {
      final data = await _client.get<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/products/$id',
      );
      final product = ProductMapper.fromJson(data);
      _cache[id] = product;
      return product;
    } catch (_) {
      return _cache[id];
    }
  }

  @override
  Future<List<InstallationOption>> installations() async {
    if (_installCache.isNotEmpty) return _installCache;
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/installation-services',
    );
    _installCache = data
        .whereType<Map>()
        .map(
          (e) => ProductMapper.installationFromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);
    return _installCache;
  }

  @override
  List<InstallationOption> installationsFor(Product product) {
    if (_installCache.isNotEmpty) return _installCache;
    return mockInstallations;
  }
}
