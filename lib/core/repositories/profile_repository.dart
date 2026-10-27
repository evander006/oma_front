import 'package:equatable/equatable.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isDemo,
    this.preferredStyle,
    this.budgetLimit,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isDemo;
  final String? preferredStyle;
  final double? budgetLimit;

  @override
  List<Object?> get props => [id, email, displayName, isDemo];
}

abstract class ProfileRepository {
  Future<UserProfile> me();
}

class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this._client);

  final DioClient _client;

  @override
  Future<UserProfile> me() async {
    final data = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/me',
    );
    return UserProfile(
      id: '${data['id']}',
      email: '${data['email'] ?? ''}',
      displayName: '${data['display_name'] ?? 'Пользователь'}',
      isDemo: data['is_demo'] == true,
      preferredStyle: data['preferred_style']?.toString(),
      budgetLimit: data['budget_limit'] == null
          ? null
          : double.tryParse('${data['budget_limit']}'),
    );
  }
}

class DemoProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> me() async {
    return const UserProfile(
      id: 'demo',
      email: 'anna@oma.local',
      displayName: 'Анна Ковалёва',
      isDemo: true,
      preferredStyle: 'современный',
    );
  }
}
