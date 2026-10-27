import 'dart:convert';

import 'package:oma/core/data/demo_properties.dart';
import 'package:oma/core/data/mappers/property_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/shared/models/room_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class PropertiesRepository {
  Future<List<Property>> load();

  /// Persist local-only fields (selection, room items overlay, extras).
  Future<void> save(List<Property> properties);

  Future<Property> createDraft({
    required String name,
    required PropertyType type,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    PropertyTenure? tenure,
    bool isDraft = true,
  });

  Future<Room> createRoom({
    required String propertyId,
    required String name,
    required String kind,
  });

  Future<void> addPlacement({
    required String roomId,
    required String productId,
  });

  Future<Property> updateProperty(Property property);

  Future<Room> updateRoom({required String propertyId, required Room room});

  Future<void> deleteProperty(String id);
}

class LocalPropertiesRepository implements PropertiesRepository {
  LocalPropertiesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'oma_properties_v2';
  static const _uuid = Uuid();

  @override
  Future<List<Property>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final demo = buildDemoProperties();
      await save(demo);
      return demo;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Property.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return buildDemoProperties();
    }
  }

  @override
  Future<void> save(List<Property> properties) async {
    final encoded = jsonEncode(properties.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  @override
  Future<Property> createDraft({
    required String name,
    required PropertyType type,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    PropertyTenure? tenure,
    bool isDraft = true,
  }) async {
    final rooms = _defaultRooms(type);
    return Property(
      id: _uuid.v4(),
      name: name,
      type: type,
      rooms: rooms,
      address: address,
      areaSqm: areaSqm,
      livingRooms: livingRooms,
      budgetByn: budgetByn,
      goal: goal,
      tenure: tenure,
      isDraft: isDraft,
      selected: false,
    );
  }

  @override
  Future<Room> createRoom({
    required String propertyId,
    required String name,
    required String kind,
  }) async {
    return Room(id: _uuid.v4(), name: name, kind: kind);
  }

  @override
  Future<void> addPlacement({
    required String roomId,
    required String productId,
  }) async {}

  @override
  Future<Property> updateProperty(Property property) async => property;

  @override
  Future<Room> updateRoom({
    required String propertyId,
    required Room room,
  }) async => room;

  @override
  Future<void> deleteProperty(String id) async {
    final list = await load();
    await save(list.where((p) => p.id != id).toList());
  }

  List<Room> _defaultRooms(PropertyType type) {
    final base = <(String, String)>[
      ('Гостиная', 'living'),
      ('Спальня', 'bedroom'),
      ('Кухня', 'kitchen'),
      ('Санузел', 'bathroom'),
      ('Прихожая', 'entry'),
      ('Коридор', 'hallway'),
    ];
    return base
        .map((e) => Room(id: _uuid.v4(), name: e.$1, kind: e.$2))
        .toList();
  }
}

/// Remote properties/rooms from oma_be + local overlay (selection, items, extras).
class RemotePropertiesRepository implements PropertiesRepository {
  RemotePropertiesRepository(this._client, this._prefs);

  final DioClient _client;
  final SharedPreferences _prefs;
  static const _overlayKey = 'oma_properties_overlay_v1';
  static const _selectedKey = 'oma_selected_property_id';

  Map<String, dynamic> _readOverlay() {
    final raw = _prefs.getString(_overlayKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeOverlay(Map<String, dynamic> data) async {
    await _prefs.setString(_overlayKey, jsonEncode(data));
  }

  bool _isRemoteId(String id) => int.tryParse(id) != null;

  @override
  Future<List<Property>> load() async {
    try {
      final propsRaw = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/properties',
      );
      final roomsRaw = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/rooms',
      );
      final overlay = _readOverlay();
      final selectedId = _prefs.getString(_selectedKey);

      final roomsByProperty = <String, List<Room>>{};
      for (final raw in roomsRaw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(raw);
        final propertyId = '${map['property_id']}';
        final roomId = '${map['id']}';
        final photos = await _safePhotos(roomId);
        final roomOverlay = (overlay['rooms'] as Map?)?[roomId] as Map?;
        final items = (roomOverlay?['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => RoomItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final room = PropertyMapper.roomFromApi(
          map,
          items: items,
          photoPaths: photos,
        ).copyWith(
          wallMaterial: roomOverlay?['wallMaterial'] as String?,
          floorMaterial: roomOverlay?['floorMaterial'] as String?,
          ceilingMaterial: roomOverlay?['ceilingMaterial'] as String?,
        );
        roomsByProperty.putIfAbsent(propertyId, () => []).add(room);
      }

      final list = <Property>[];
      for (final raw in propsRaw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(raw);
        final id = '${map['id']}';
        final propOverlay = (overlay['properties'] as Map?)?[id] as Map?;
        final property = PropertyMapper.propertyFromApi(
            map,
            rooms: roomsByProperty[id] ?? const [],
            selected: selectedId == id,
            areaSqm: (propOverlay?['areaSqm'] as num?)?.toDouble(),
            livingRooms: propOverlay?['livingRooms'] as int?,
            budgetByn: (propOverlay?['budgetByn'] as num?)?.toDouble(),
            goal: propOverlay?['goal'] as String?,
            isDraft: propOverlay?['isDraft'] as bool? ?? false,
          );
        list.add(
          property.copyWith(
            tenure: _tenureFromOverlay(propOverlay?['tenure']),
          ),
        );
      }

      if (list.isNotEmpty && !list.any((p) => p.selected)) {
        list[0] = list[0].copyWith(selected: true);
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _safePhotos(String roomId) async {
    try {
      final data = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/rooms/$roomId/photos',
      );
      return data
          .whereType<Map>()
          .map((e) => PropertyMapper.absolutePhotoUrl(e['url']?.toString()))
          .where((u) => u.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<Property> properties) async {
    final overlay = _readOverlay();
    final propOverlay = <String, dynamic>{
      ...(overlay['properties'] as Map? ?? {}),
    };
    final roomOverlay = <String, dynamic>{
      ...(overlay['rooms'] as Map? ?? {}),
    };

    String? selectedId;
    for (final p in properties) {
      if (p.selected) selectedId = p.id;
      propOverlay[p.id] = {
        'areaSqm': p.areaSqm,
        'livingRooms': p.livingRooms,
        'budgetByn': p.budgetByn,
        'goal': p.goal,
        'tenure': p.tenure?.name,
        'isDraft': p.isDraft,
      };
      for (final r in p.rooms) {
        roomOverlay[r.id] = {
          'items': r.items.map((e) => e.toJson()).toList(),
          'wallMaterial': r.wallMaterial,
          'floorMaterial': r.floorMaterial,
          'ceilingMaterial': r.ceilingMaterial,
        };
      }
    }

    await _writeOverlay({
      'properties': propOverlay,
      'rooms': roomOverlay,
    });
    if (selectedId != null) {
      await _prefs.setString(_selectedKey, selectedId);
    }
  }

  @override
  Future<Property> createDraft({
    required String name,
    required PropertyType type,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    PropertyTenure? tenure,
    bool isDraft = true,
  }) async {
    final created = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/properties',
      data: {
        'name': name,
        'address': address,
        'property_type': PropertyMapper.typeToApi(type),
        'tenure': tenure?.name,
        'area_sqm': areaSqm,
      },
    );
    final propertyId = '${created['id']}';
    const defaultRooms = <(String, String)>[
      ('Гостиная', 'living'),
      ('Спальня', 'bedroom'),
      ('Кухня', 'kitchen'),
      ('Санузел', 'bathroom'),
      ('Прихожая', 'entry'),
      ('Коридор', 'hallway'),
    ];
    final rooms = <Room>[];
    for (final e in defaultRooms) {
      rooms.add(
        await createRoom(propertyId: propertyId, name: e.$1, kind: e.$2),
      );
    }

    final property = PropertyMapper.propertyFromApi(
      created,
      rooms: rooms,
      areaSqm: areaSqm,
      livingRooms: livingRooms,
      budgetByn: budgetByn,
      goal: goal,
      tenure: tenure,
      isDraft: isDraft,
      selected: true,
    );
    await save([property]);
    return property;
  }

  @override
  Future<Room> createRoom({
    required String propertyId,
    required String name,
    required String kind,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/rooms',
      data: {
        'property_id': int.parse(propertyId),
        'name': name,
        'room_type': kind,
      },
    );
    return PropertyMapper.roomFromApi(data);
  }

  @override
  Future<void> addPlacement({
    required String roomId,
    required String productId,
  }) async {
    if (!_isRemoteId(roomId)) return;
    await _client.dio.post(
      '${ApiConfig.apiPrefix}/rooms/$roomId/placements',
      queryParameters: {'product_id': productId},
    );
  }

  @override
  Future<Property> updateProperty(Property property) async {
    if (!_isRemoteId(property.id)) return property;
    final data = await _client.patch<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/properties/${property.id}',
      data: {
        'name': property.name,
        'address': property.address,
        'property_type': PropertyMapper.typeToApi(property.type),
        'tenure': property.tenure?.name,
        'area_sqm': property.areaSqm,
      },
    );
    return property.copyWith(
      name: data['name']?.toString() ?? property.name,
      type: PropertyMapper.typeFromApi(data['property_type']?.toString()),
      tenure: PropertyMapper.tenureFromApi(data['tenure']?.toString()),
      address: data['address']?.toString(),
      areaSqm: _asDouble(data['area_sqm']) ?? property.areaSqm,
    );
  }

  @override
  Future<Room> updateRoom({
    required String propertyId,
    required Room room,
  }) async {
    if (!_isRemoteId(room.id)) return room;
    final data = await _client.patch<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/rooms/${room.id}',
      data: {
        'name': room.name,
        'room_type': room.kind,
        'description': room.description,
        'width_m': room.widthM,
        'length_m': room.lengthM,
        'height_m': room.heightM,
        'style_preference': room.stylePreference,
        'wall_material': room.wallMaterial,
        'floor_material': room.floorMaterial,
        'ceiling_material': room.ceilingMaterial,
      },
    );
    return PropertyMapper.roomFromApi(
      data,
      items: room.items,
      photoPaths: room.photoPaths,
    );
  }

  @override
  Future<void> deleteProperty(String id) async {
    if (_isRemoteId(id)) {
      await _client.delete('${ApiConfig.apiPrefix}/properties/$id');
    }
    final overlay = _readOverlay();
    final props =
        Map<String, dynamic>.from(overlay['properties'] as Map? ?? {});
    props.remove(id);
    await _writeOverlay({...overlay, 'properties': props});
  }

  static PropertyTenure? _tenureFromOverlay(dynamic value) => switch (value) {
        'owned' => PropertyTenure.owned,
        'rented' => PropertyTenure.rented,
        _ => null,
      };

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
