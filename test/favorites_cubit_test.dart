import 'package:flutter_test/flutter_test.dart';
import 'package:oma/features/favorites/cubit/favorites_cubit.dart';
import 'package:oma/shared/models/product.dart';

void main() {
  test('FavoritesCubit toggle', () async {
    final cubit = FavoritesCubit();
    const product = Product(
      id: 'p1',
      name: 'Test',
      category: 'A',
      description: '',
      specs: {},
      priceByn: 10,
    );
    await cubit.toggle(product);
    expect(cubit.state.contains('p1'), isTrue);
    await cubit.toggle(product);
    expect(cubit.state.contains('p1'), isFalse);
  });
}
