import 'package:flutter_test/flutter_test.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/shared/models/product.dart';

void main() {
  test('CartCubit add, setQty, remove, clear', () async {
    final cubit = CartCubit();
    const product = Product(
      id: 'p1',
      name: 'Test',
      category: 'A',
      description: '',
      specs: {},
      priceByn: 10,
    );

    await cubit.add(product);
    expect(cubit.state.count, 1);
    await cubit.add(product);
    expect(cubit.state.count, 2);
    await cubit.setQty('p1', 5);
    expect(cubit.state.count, 5);
    expect(cubit.state.total, 50);
    await cubit.remove('p1');
    expect(cubit.state.items, isEmpty);
    await cubit.add(product);
    await cubit.clear();
    expect(cubit.state.items, isEmpty);
  });
}
