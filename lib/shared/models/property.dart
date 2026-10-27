import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/room.dart';

enum PropertyType { apartment, house, dacha }

enum PropertyTenure { owned, rented }

class Property extends Equatable {
  const Property({
    required this.id,
    required this.name,
    required this.type,
    required this.rooms,
    this.address,
    this.areaSqm,
    this.livingRooms,
    this.budgetByn,
    this.goal,
    this.tenure,
    this.completionPercent = 0,
    this.isDraft = false,
    this.selected = false,
  });

  final String id;
  final String name;
  final PropertyType type;
  final List<Room> rooms;
  final String? address;
  final double? areaSqm;
  final int? livingRooms;
  final double? budgetByn;
  final String? goal;
  final PropertyTenure? tenure;
  final int completionPercent;
  final bool isDraft;
  final bool selected;

  Property copyWith({
    String? name,
    PropertyType? type,
    List<Room>? rooms,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
    PropertyTenure? tenure,
    int? completionPercent,
    bool? isDraft,
    bool? selected,
  }) {
    return Property(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      rooms: rooms ?? this.rooms,
      address: address ?? this.address,
      areaSqm: areaSqm ?? this.areaSqm,
      livingRooms: livingRooms ?? this.livingRooms,
      budgetByn: budgetByn ?? this.budgetByn,
      goal: goal ?? this.goal,
      tenure: tenure ?? this.tenure,
      completionPercent: completionPercent ?? this.completionPercent,
      isDraft: isDraft ?? this.isDraft,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'rooms': rooms.map((r) => r.toJson()).toList(),
        'address': address,
        'areaSqm': areaSqm,
        'livingRooms': livingRooms,
        'budgetByn': budgetByn,
        'goal': goal,
        'tenure': tenure?.name,
        'completionPercent': completionPercent,
        'isDraft': isDraft,
        'selected': selected,
      };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: '${json['id']}',
      name: json['name'] as String,
      type: _propertyType(json['type'] ?? json['property_type']),
      rooms: (json['rooms'] as List<dynamic>? ?? const [])
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: json['address'] as String?,
      areaSqm: (json['areaSqm'] as num?)?.toDouble(),
      livingRooms: json['livingRooms'] as int?,
      budgetByn: (json['budgetByn'] as num?)?.toDouble(),
      goal: json['goal'] as String?,
      tenure: _propertyTenure(json['tenure']),
      completionPercent:
          (json['completionPercent'] ?? json['completion_percent'] ?? 0) as int,
      isDraft: json['isDraft'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        rooms,
        tenure,
        completionPercent,
        selected,
        isDraft,
      ];
}

PropertyType _propertyType(dynamic raw) {
  final value = '$raw'.toLowerCase();
  if (value == 'house' || value.contains('дом')) return PropertyType.house;
  if (value == 'dacha' || value.contains('дач')) return PropertyType.dacha;
  return PropertyType.apartment;
}

PropertyTenure? _propertyTenure(dynamic raw) {
  final value = raw?.toString().toLowerCase();
  if (value == 'owned') return PropertyTenure.owned;
  if (value == 'rented') return PropertyTenure.rented;
  return null;
}
