import 'dart:convert';

import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/master.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class MastersRepository {
  Future<List<MasterProfile>> masters({String? specialty});

  Future<MasterProfile?> byId(String id);

  Future<void> setFavorite(String id, {required bool favorite});

  Future<List<MasterProfile>> favoriteMasters();

  Future<MasterWorkRequest> createRequest(MasterRequestDraft draft);

  Future<List<MasterWorkRequest>> myRequests();

  Future<List<MasterWorkRequest>> contractorRequests();

  Future<MasterWorkRequest> updateStatus(
    String requestId,
    MasterRequestStatus status,
  );
}

/// Persistent, explicitly labelled demo flow used in offline/test mode and
/// when the optional contractor API is not available yet.
class DemoMastersRepository implements MastersRepository {
  DemoMastersRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _favoriteKey = 'oma_demo_master_favorites_v1';
  static const _requestsKey = 'oma_demo_master_requests_v1';
  static const _uuid = Uuid();

  static const _profiles = <MasterProfile>[
    MasterProfile(
      id: 'demo-master-1',
      displayName: 'Алексей М.',
      city: 'Минск',
      bio:
          'Демонстрационный профиль специалиста по сантехническим работам и установке оборудования.',
      specialties: ['Сантехника', 'Установка оборудования'],
      experienceYears: 8,
      verified: false,
      isFavorite: false,
      isDemo: true,
      rating: 4.9,
      reviewCount: 18,
      portfolio: [
        MasterPortfolioItem(
          id: 'demo-portfolio-1',
          title: 'Демо-кейс · кухня',
          description: 'Замена мойки и смесителя. Фото не опубликовано.',
        ),
        MasterPortfolioItem(
          id: 'demo-portfolio-2',
          title: 'Демо-кейс · санузел',
          description: 'Монтаж сантехнического оборудования.',
        ),
      ],
      reviews: [
        MasterReview(
          id: 'demo-review-1',
          author: 'Демо-клиент',
          text: 'Демонстрационный отзыв для проверки интерфейса профиля.',
          rating: 5,
        ),
      ],
    ),
    MasterProfile(
      id: 'demo-master-2',
      displayName: 'Ирина К.',
      city: 'Минск и область',
      bio:
          'Демонстрационный профиль мастера по отделке, покраске и подготовке поверхностей.',
      specialties: ['Отделка', 'Покраска'],
      experienceYears: 6,
      verified: false,
      isFavorite: false,
      isDemo: true,
      rating: 4.8,
      reviewCount: 12,
      portfolio: [
        MasterPortfolioItem(
          id: 'demo-portfolio-3',
          title: 'Демо-кейс · гостиная',
          description: 'Подготовка и покраска стен.',
        ),
      ],
      reviews: [
        MasterReview(
          id: 'demo-review-2',
          author: 'Демо-клиент',
          text: 'Демонстрационный отзыв, не подтверждённый реальным заказом.',
          rating: 5,
        ),
      ],
    ),
    MasterProfile(
      id: 'demo-master-3',
      displayName: 'Команда «Точный ремонт»',
      city: 'Беларусь',
      bio:
          'Демонстрационная команда для комплексных работ: электрика, освещение и сборка мебели.',
      specialties: ['Электрика', 'Освещение', 'Сборка мебели'],
      experienceYears: 10,
      verified: false,
      isFavorite: false,
      isDemo: true,
      rating: 4.7,
      reviewCount: 9,
      portfolio: [
        MasterPortfolioItem(
          id: 'demo-portfolio-4',
          title: 'Демо-кейс · освещение',
          description: 'Монтаж трековой системы и рабочих светильников.',
        ),
      ],
      reviews: [],
    ),
  ];

  Set<String> _favoriteIds() {
    return (_prefs.getStringList(_favoriteKey) ?? const <String>[]).toSet();
  }

  Future<void> _writeFavoriteIds(Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _prefs.setStringList(_favoriteKey, sorted);
  }

  List<MasterProfile> _profilesWithFavorites() {
    final ids = _favoriteIds();
    return _profiles
        .map((profile) => profile.copyWith(isFavorite: ids.contains(profile.id)))
        .toList(growable: false);
  }

  List<MasterWorkRequest> _readRequests() {
    final raw = _prefs.getString(_requestsKey);
    if (raw == null || raw.isEmpty) return [_seedRequest()];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((item) => MasterWorkRequest.fromJson(
                Map<String, dynamic>.from(item),
                demoFallback: true,
              ))
          .toList();
    } catch (_) {
      return [_seedRequest()];
    }
  }

  Future<void> _writeRequests(List<MasterWorkRequest> requests) async {
    await _prefs.setString(
      _requestsKey,
      jsonEncode(requests.map((request) => request.toJson()).toList()),
    );
  }

  MasterWorkRequest _seedRequest() {
    return MasterWorkRequest(
      id: 'demo-work-1',
      masterId: 'demo-master-1',
      masterName: 'Алексей М.',
      title: 'Установка кухонного смесителя',
      description:
          'Демонстрационная заявка для показа статусов и предложения материалов.',
      propertyId: 'demo-property',
      propertyName: 'Демо-объект',
      roomId: 'demo-room',
      roomName: 'Кухня',
      budgetByn: 350,
      sharedFields: const {
        SharedHomeField.roomDimensions,
        SharedHomeField.installedEquipment,
      },
      status: MasterRequestStatus.materialsProposed,
      createdAt: DateTime(2026, 10, 20),
      isDemo: true,
      materialProposal: const [
        MaterialProposalItem(
          productId: 'p1',
          productName:
              'Смеситель кухонный Ledeme L4399U-12 · демо-каталог',
          quantity: 1,
          unitPriceByn: 182.75,
        ),
      ],
    );
  }

  @override
  Future<List<MasterProfile>> masters({String? specialty}) async {
    final all = _profilesWithFavorites();
    if (specialty == null || specialty.isEmpty) return all;
    return all
        .where((profile) => profile.specialties.contains(specialty))
        .toList(growable: false);
  }

  @override
  Future<MasterProfile?> byId(String id) async {
    for (final profile in _profilesWithFavorites()) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    final ids = _favoriteIds();
    if (favorite) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    await _writeFavoriteIds(ids);
  }

  @override
  Future<List<MasterProfile>> favoriteMasters() async {
    return _profilesWithFavorites()
        .where((profile) => profile.isFavorite)
        .toList(growable: false);
  }

  @override
  Future<MasterWorkRequest> createRequest(MasterRequestDraft draft) async {
    if (!draft.consentGranted) {
      throw StateError('Необходимо подтвердить передачу выбранных сведений.');
    }
    final request = MasterWorkRequest(
      id: 'DEMO-${_uuid.v4().substring(0, 8).toUpperCase()}',
      masterId: draft.masterId,
      masterName: draft.masterName,
      title: draft.title.trim(),
      description: draft.description.trim(),
      propertyId: draft.propertyId,
      propertyName: draft.propertyName,
      roomId: draft.roomId,
      roomName: draft.roomName,
      budgetByn: draft.budgetByn,
      sharedFields: Set.unmodifiable(draft.sharedFields),
      status: MasterRequestStatus.submitted,
      createdAt: DateTime.now(),
      isDemo: true,
    );
    final requests = [request, ..._readRequests()];
    await _writeRequests(requests);
    return request;
  }

  @override
  Future<List<MasterWorkRequest>> myRequests() async {
    final items = _readRequests()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  @override
  Future<List<MasterWorkRequest>> contractorRequests() => myRequests();

  @override
  Future<MasterWorkRequest> updateStatus(
    String requestId,
    MasterRequestStatus status,
  ) async {
    final requests = _readRequests();
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index < 0) throw StateError('Заявка не найдена');
    final updated = requests[index].copyWith(status: status);
    requests[index] = updated;
    await _writeRequests(requests);
    return updated;
  }
}

/// Remote API with a fully working and visibly marked demo fallback. This keeps
/// the hackathon flow usable while the optional contractor service is offline.
class RemoteMastersRepository implements MastersRepository {
  RemoteMastersRepository(this._client, this._fallback);

  final DioClient _client;
  final DemoMastersRepository _fallback;

  @override
  Future<List<MasterProfile>> masters({String? specialty}) async {
    try {
      final data = await _client.get<dynamic>(
        '${ApiConfig.apiPrefix}/contractors',
        query: {
          if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        },
      );
      return _listPayload(data)
          .whereType<Map>()
          .map((item) => MasterProfile.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false);
    } catch (_) {
      return _fallback.masters(specialty: specialty);
    }
  }

  @override
  Future<MasterProfile?> byId(String id) async {
    try {
      final data = await _client.get<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/contractors/$id',
      );
      return MasterProfile.fromJson(data);
    } catch (_) {
      return _fallback.byId(id);
    }
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    try {
      if (favorite) {
        await _client.post<dynamic>(
          '${ApiConfig.apiPrefix}/contractors/$id/favorite',
        );
      } else {
        await _client.delete<dynamic>(
          '${ApiConfig.apiPrefix}/contractors/$id/favorite',
        );
      }
    } catch (_) {
      await _fallback.setFavorite(id, favorite: favorite);
    }
  }

  @override
  Future<List<MasterProfile>> favoriteMasters() async {
    final all = await masters();
    return all.where((profile) => profile.isFavorite).toList(growable: false);
  }

  @override
  Future<MasterWorkRequest> createRequest(MasterRequestDraft draft) async {
    if (!draft.consentGranted) {
      throw StateError('Необходимо подтвердить передачу выбранных сведений.');
    }
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/work-orders',
        data: draft.toApiJson(),
      );
      return MasterWorkRequest.fromJson(data);
    } catch (_) {
      return _fallback.createRequest(draft);
    }
  }

  @override
  Future<List<MasterWorkRequest>> myRequests() async {
    try {
      final data = await _client.get<dynamic>(
        '${ApiConfig.apiPrefix}/work-orders/mine',
      );
      return _workOrders(data);
    } catch (_) {
      return _fallback.myRequests();
    }
  }

  @override
  Future<List<MasterWorkRequest>> contractorRequests() async {
    try {
      final data = await _client.get<dynamic>(
        '${ApiConfig.apiPrefix}/contractor/work-orders',
      );
      return _workOrders(data);
    } catch (_) {
      return _fallback.contractorRequests();
    }
  }

  @override
  Future<MasterWorkRequest> updateStatus(
    String requestId,
    MasterRequestStatus status,
  ) async {
    try {
      final data = await _client.patch<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/work-orders/$requestId/status',
        data: {'status': status.apiValue},
      );
      return MasterWorkRequest.fromJson(data);
    } catch (_) {
      return _fallback.updateStatus(requestId, status);
    }
  }

  List<MasterWorkRequest> _workOrders(dynamic data) {
    return _listPayload(data)
        .whereType<Map>()
        .map((item) => MasterWorkRequest.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  List<dynamic> _listPayload(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map) {
      return data['items'] as List<dynamic>? ??
          data['results'] as List<dynamic>? ??
          const [];
    }
    return const [];
  }
}
