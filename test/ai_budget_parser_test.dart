import 'package:flutter_test/flutter_test.dart';
import 'package:oma/features/ai_assistant/domain/budget_parser.dart';

void main() {
  group('maxBudgetBynFromLabel', () {
    test('uses the upper bound for capped budgets', () {
      expect(maxBudgetBynFromLabel('до 1 000 BYN'), 1000);
      expect(maxBudgetBynFromLabel('1–3 000 BYN'), 3000);
      expect(maxBudgetBynFromLabel('3–7 000 BYN'), 7000);
    });

    test('does not invert a minimum budget into a maximum', () {
      expect(maxBudgetBynFromLabel('от 7 000 BYN'), isNull);
      expect(maxBudgetBynFromLabel(' ОТ 7 000 BYN '), isNull);
    });

    test('handles missing or malformed labels', () {
      expect(maxBudgetBynFromLabel(null), isNull);
      expect(maxBudgetBynFromLabel(''), isNull);
      expect(maxBudgetBynFromLabel('не выбран'), isNull);
    });
  });
}
