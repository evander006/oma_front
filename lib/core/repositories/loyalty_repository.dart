import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/loyalty.dart';

/// Loyalty program data from oma_be or demo fallback.
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

class RemoteLoyaltyRepository implements LoyaltyRepository {
  RemoteLoyaltyRepository(this._client);

  final DioClient _client;

  @override
  Future<LoyaltyAccount> account() async {
    late final Map<String, dynamic> account;
    late final List<dynamic> rewardsRaw;
    late final List<dynamic> txRaw;
    try {
      account = await _client.get<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/loyalty/account',
      );
      rewardsRaw = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/loyalty/rewards',
      );
      txRaw = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/loyalty/transactions',
      );
    } catch (_) {
      return await DemoLoyaltyRepository().account();
    }

    final rewards = rewardsRaw
        .whereType<Map>()
        .map(
          (e) => LoyaltyReward(
            id: '${e['id']}',
            title: '${e['title'] ?? ''}',
            costPoints: (e['points_cost'] as num?)?.toInt() ?? 0,
            subtitle: e['description']?.toString() ??
                e['program_label']?.toString(),
          ),
        )
        .toList(growable: false);

    final history = txRaw
        .whereType<Map>()
        .map(
          (e) {
            final points = (e['points'] as num?)?.toInt() ?? 0;
            final kind = '${e['kind']}' == 'redeem'
                ? LoyaltyEventKind.redeem
                : LoyaltyEventKind.earn;
            return LoyaltyEvent(
              id: '${e['id']}',
              title: '${e['reason'] ?? kind.name}',
              points: kind == LoyaltyEventKind.redeem ? -points.abs() : points,
              at: e['created_at'] == null
                  ? DateTime.now()
                  : DateTime.tryParse('${e['created_at']}') ?? DateTime.now(),
              kind: kind,
            );
          },
        )
        .toList(growable: false);

    final isDev = account['is_development_config'] == true;
    return LoyaltyAccount(
      balance: (account['balance'] as num?)?.toInt() ?? 0,
      tier: '${account['tier'] ?? 'standard'}',
      demo: isDev,
      history: history,
      rewards: rewards,
    );
  }
}
