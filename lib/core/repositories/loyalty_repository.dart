import 'package:oma/shared/models/loyalty.dart';

/// Loyalty program data. Demo values until official API/rules are available.
abstract class LoyaltyRepository {
  Future<LoyaltyAccount> account();
}

class DemoLoyaltyRepository implements LoyaltyRepository {
  @override
  Future<LoyaltyAccount> account() async {
    final now = DateTime.now();
    return LoyaltyAccount(
      balance: 1240,
      tier: 'Серебряный',
      demo: true,
      history: [
        LoyaltyEvent(
          id: 'le1',
          title: 'Покупка в каталоге',
          points: 180,
          at: now.subtract(const Duration(days: 3)),
        ),
        LoyaltyEvent(
          id: 'le2',
          title: 'Демо: бонус за регистрацию',
          points: 500,
          at: now.subtract(const Duration(days: 20)),
        ),
        LoyaltyEvent(
          id: 'le3',
          title: 'Списание на скидку',
          points: -200,
          at: now.subtract(const Duration(days: 40)),
          kind: LoyaltyEventKind.redeem,
        ),
      ],
      rewards: const [
        LoyaltyReward(
          id: 'rw1',
          title: 'Скидка 10 BYN',
          costPoints: 500,
          subtitle: 'Демо-награда · правила уточняются',
        ),
        LoyaltyReward(
          id: 'rw2',
          title: 'Бесплатная доставка',
          costPoints: 800,
          subtitle: 'Демо-награда · при заказе от 100 BYN',
        ),
        LoyaltyReward(
          id: 'rw3',
          title: 'Консультация дизайнера',
          costPoints: 1500,
          subtitle: 'Демо · 30 минут онлайн',
        ),
      ],
    );
  }
}
