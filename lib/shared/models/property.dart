import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/room.dart';

enum PropertyType { apartment, house }

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
        'isDraft': isDraft,
        'selected': selected,
      };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PropertyType.values.byName(json['type'] as String),
      rooms: (json['rooms'] as List<dynamic>)
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: json['address'] as String?,
      areaSqm: (json['areaSqm'] as num?)?.toDouble(),
      livingRooms: json['livingRooms'] as int?,
      budgetByn: (json['budgetByn'] as num?)?.toDouble(),
      goal: json['goal'] as String?,
      isDraft: json['isDraft'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, type, rooms, selected, isDraft];
}
