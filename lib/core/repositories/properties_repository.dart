import 'dart:convert';

import 'package:oma/core/data/demo_properties.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PropertiesRepository {
  PropertiesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'oma_properties_v2';
  static const _uuid = Uuid();

  List<Property> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final demo = buildDemoProperties();
      // Fire-and-forget persist so next launch keeps demo edits.
      save(demo);
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

  Future<void> save(List<Property> properties) async {
    final encoded = jsonEncode(properties.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  Property createDraft({
    required String name,
    required PropertyType type,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    bool isDraft = true,
  }) {
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
      isDraft: isDraft,
      selected: false,
    );
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
    if (type == PropertyType.house) {
      // Same set for demo house.
    }
    return base
        .map((e) => Room(id: _uuid.v4(), name: e.$1, kind: e.$2))
        .toList();
  }
}
