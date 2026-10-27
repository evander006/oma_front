import 'dart:math' as math;

import 'package:oma/features/ai_assistant/domain/ai_design_models.dart';
import 'package:oma/shared/models/product.dart';

abstract final class DesignBundleBuilder {
  static List<DesignBundle> build({
    required List<Product> products,
    required bool imageWasAnalyzed,
    double? budgetByn,
    double serviceEstimateByn = 0,
    String? serviceLabel,
  }) {
    final pool = _uniquePriced(products);
    if (pool.isEmpty) return const [];

    final ascending = [...pool]
      ..sort((a, b) => a.priceByn!.compareTo(b.priceByn!));
    final descending = ascending.reversed.toList(growable: false);
    final targetCount = math.min(4, pool.length);

    final budget = _selectDiverse(
      ascending,
      maxItems: math.min(3, targetCount),
      budgetByn: budgetByn,
    );

    final targetPrice = budgetByn == null
        ? ascending[ascending.length ~/ 2].priceByn!
        : budgetByn / math.max(1, targetCount);
    final balancedOrder = [...pool]
      ..sort(
        (a, b) => (a.priceByn! - targetPrice)
            .abs()
            .compareTo((b.priceByn! - targetPrice).abs()),
      );
    final optimal = _selectDiverse(
      balancedOrder,
      maxItems: targetCount,
      budgetByn: budgetByn,
    );

    final closestOrder = imageWasAnalyzed ? pool : descending;
    final closest = _selectDiverse(
      closestOrder,
      maxItems: targetCount,
    );

    return [
      DesignBundle(
        id: 'budget',
        title: 'Бюджетный вариант',
        subtitle: 'Минимальная стоимость без выдуманных товаров',
        products: budget,
        selectionNote: budgetByn == null
            ? 'Собран из самых доступных позиций каталога.'
            : 'Собран из доступных позиций с учётом указанного бюджета.',
        serviceEstimateByn: serviceEstimateByn,
        serviceLabel: serviceLabel,
      ),
      DesignBundle(
        id: 'optimal',
        title: 'Оптимальный вариант',
        subtitle: 'Баланс наполнения и общей стоимости',
        products: optimal,
        selectionNote:
            'Позиции распределены по категориям и цене; совместимость требует проверки перед заказом.',
        serviceEstimateByn: serviceEstimateByn,
        serviceLabel: serviceLabel,
      ),
      DesignBundle(
        id: 'closest',
        title: 'Максимально похожий вариант',
        subtitle: imageWasAnalyzed
            ? 'Приоритет рекомендациям vision-анализа'
            : 'Демо-комплект: сходство с фото не оценивалось',
        products: closest,
        selectionNote: imageWasAnalyzed
            ? 'Порядок основан на каталожно-обоснованных рекомендациях AI.'
            : 'Без доступного vision AI показан более полный набор из каталога.',
        serviceEstimateByn: serviceEstimateByn,
        serviceLabel: serviceLabel,
      ),
    ];
  }

  static List<Product> _uniquePriced(List<Product> products) {
    final seen = <String>{};
    return products
        .where(
          (product) =>
              seen.add(product.id) &&
              product.priceByn != null &&
              product.priceByn! > 0,
        )
        .toList(growable: false);
  }

  static List<Product> _selectDiverse(
    List<Product> ordered, {
    required int maxItems,
    double? budgetByn,
  }) {
    final selected = <Product>[];
    final selectedIds = <String>{};
    final categories = <String>{};
    var total = 0.0;

    bool canAdd(Product product) {
      if (selectedIds.contains(product.id)) return false;
      final next = total + product.priceByn!;
      return budgetByn == null || next <= budgetByn || selected.isEmpty;
    }

    for (final product in ordered) {
      if (selected.length >= maxItems) break;
      if (categories.contains(product.category) || !canAdd(product)) continue;
      selected.add(product);
      selectedIds.add(product.id);
      categories.add(product.category);
      total += product.priceByn!;
    }
    for (final product in ordered) {
      if (selected.length >= maxItems) break;
      if (!canAdd(product)) continue;
      selected.add(product);
      selectedIds.add(product.id);
      total += product.priceByn!;
    }
    return List.unmodifiable(selected);
  }
}
