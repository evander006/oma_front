import 'package:oma/core/network/api_config.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/shared/models/room_item.dart';

abstract final class PropertyMapper {
  static PropertyType typeFromApi(String? raw) {
    final v = (raw ?? '').toLowerCase();
    if (v.contains('house') || v.contains('дом')) return PropertyType.house;
    if (v.contains('dacha') || v.contains('дач')) return PropertyType.dacha;
    return PropertyType.apartment;
  }

  static String typeToApi(PropertyType type) => switch (type) {
        PropertyType.apartment => 'apartment',
        PropertyType.house => 'house',
        PropertyType.dacha => 'dacha',
      };

  static PropertyTenure? tenureFromApi(String? raw) => switch (raw) {
        'owned' => PropertyTenure.owned,
        'rented' => PropertyTenure.rented,
        _ => null,
      };

  static Property propertyFromApi(
    Map<String, dynamic> json, {
    List<Room> rooms = const [],
    bool selected = false,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    PropertyTenure? tenure,
    bool isDraft = false,
  }) {
    return Property(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      type: typeFromApi(json['property_type']?.toString()),
      rooms: rooms,
      address: json['address']?.toString(),
      areaSqm: areaSqm ?? _num(json['area_sqm']),
      livingRooms: livingRooms,
      budgetByn: budgetByn,
      goal: goal,
      tenure: tenure ?? tenureFromApi(json['tenure']?.toString()),
      completionPercent: (json['completion_percent'] as num?)?.toInt() ?? 0,
      isDraft: isDraft,
      selected: selected,
    );
  }

  static Room roomFromApi(
    Map<String, dynamic> json, {
    List<RoomItem> items = const [],
    List<String> photoPaths = const [],
  }) {
    return Room(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      kind: json['room_type']?.toString() ?? 'other',
      items: items,
      photoPaths: photoPaths,
      widthM: _num(json['width_m']),
      lengthM: _num(json['length_m']),
      heightM: _num(json['height_m']),
      stylePreference: json['style_preference']?.toString(),
      description: json['description']?.toString(),
      wallMaterial: json['wall_material']?.toString(),
      floorMaterial: json['floor_material']?.toString(),
      ceilingMaterial: json['ceiling_material']?.toString(),
    );
  }

  static String absolutePhotoUrl(String? url) => ApiConfig.absoluteUrl(url);

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
