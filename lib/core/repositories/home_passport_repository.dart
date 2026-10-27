import 'dart:convert';

import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/home_passport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class HomePassportRepository {
  Future<List<HomeEquipment>> equipment(String propertyId, {String? roomId});
  Future<List<HomeHistoryEvent>> history(String propertyId, {String? roomId});
  Future<HomeEquipment> addEquipment({
    required String propertyId,
    String? roomId,
    required String name,
    String? category,
    String? brand,
    String? model,
    String? serialNumber,
    Map<String, String> specifications = const {},
  });
}

class RemoteHomePassportRepository implements HomePassportRepository {
  RemoteHomePassportRepository(this._client);

  final DioClient _client;

  @override
  Future<List<HomeEquipment>> equipment(
    String propertyId, {
    String? roomId,
  }) async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/properties/$propertyId/equipment',
      query: {if (roomId != null) 'room_id': roomId},
    );
    return data
        .whereType<Map>()
        .map((item) => HomeEquipment.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<List<HomeHistoryEvent>> history(
    String propertyId, {
    String? roomId,
  }) async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/properties/$propertyId/history',
      query: {if (roomId != null) 'room_id': roomId},
    );
    return data
        .whereType<Map>()
        .map((item) => HomeHistoryEvent.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<HomeEquipment> addEquipment({
    required String propertyId,
    String? roomId,
    required String name,
    String? category,
    String? brand,
    String? model,
    String? serialNumber,
    Map<String, String> specifications = const {},
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/properties/$propertyId/equipment',
      data: {
        'room_id': roomId == null ? null : int.tryParse(roomId),
        'name': name,
        'category': category,
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'specifications': specifications,
      },
    );
    return HomeEquipment.fromJson(data);
  }
}

class LocalHomePassportRepository implements HomePassportRepository {
  LocalHomePassportRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _equipmentKey = 'oma_home_equipment_v1';
  static const _uuid = Uuid();

  List<HomeEquipment> _read() {
    final raw = _prefs.getString(_equipmentKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((item) => HomeEquipment.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(List<HomeEquipment> items) => _prefs.setString(
        _equipmentKey,
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );

  @override
  Future<List<HomeEquipment>> equipment(
    String propertyId, {
    String? roomId,
  }) async =>
      _read()
          .where((item) => item.propertyId == propertyId)
          .where((item) => roomId == null || item.roomId == roomId)
          .toList(growable: false);

  @override
  Future<List<HomeHistoryEvent>> history(
    String propertyId, {
    String? roomId,
  }) async =>
      const [];

  @override
  Future<HomeEquipment> addEquipment({
    required String propertyId,
    String? roomId,
    required String name,
    String? category,
    String? brand,
    String? model,
    String? serialNumber,
    Map<String, String> specifications = const {},
  }) async {
    final item = HomeEquipment(
      id: _uuid.v4(),
      propertyId: propertyId,
      roomId: roomId,
      name: name,
      category: category,
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      specifications: specifications,
      source: 'local_demo',
      isDemonstration: true,
    );
    await _write([..._read(), item]);
    return item;
  }
}
