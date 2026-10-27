import 'package:equatable/equatable.dart';

class LoyaltyAccount extends Equatable {
  const LoyaltyAccount({
    required this.balance,
    required this.tier,
    required this.demo,
    this.history = const [],
    this.rewards = const [],
  });

  final int balance;
  final String tier;
  final bool demo;
  final List<LoyaltyEvent> history;
  final List<LoyaltyReward> rewards;

  @override
  List<Object?> get props => [balance, tier, demo, history, rewards];
}

class LoyaltyEvent extends Equatable {
  const LoyaltyEvent({
    required this.id,
    required this.title,
    required this.points,
    required this.at,
    this.kind = LoyaltyEventKind.earn,
  });

  final String id;
  final String title;
  final int points;
  final DateTime at;
  final LoyaltyEventKind kind;

  @override
  List<Object?> get props => [id, title, points, at, kind];
}

enum LoyaltyEventKind { earn, redeem }

class LoyaltyReward extends Equatable {
  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.costPoints,
    this.subtitle,
  });

  final String id;
  final String title;
  final int costPoints;
  final String? subtitle;

  @override
  List<Object?> get props => [id, title, costPoints];
}
