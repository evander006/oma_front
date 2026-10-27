import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/room_item.dart';

class Room extends Equatable {
  const Room({
    required this.id,
    required this.name,
    required this.kind,
    this.items = const [],
    this.photoPaths = const [],
    this.widthM,
    this.lengthM,
    this.heightM,
    this.stylePreference,
    this.description,
  });

  final String id;
  final String name;
  final String kind;
  final List<RoomItem> items;
  final List<String> photoPaths;
  final double? widthM;
  final double? lengthM;
  final double? heightM;
  final String? stylePreference;
  final String? description;

  Room copyWith({
    String? name,
    String? kind,
    List<RoomItem>? items,
    List<String>? photoPaths,
    double? widthM,
    double? lengthM,
    double? heightM,
    String? stylePreference,
    String? description,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      photoPaths: photoPaths ?? this.photoPaths,
      widthM: widthM ?? this.widthM,
      lengthM: lengthM ?? this.lengthM,
      heightM: heightM ?? this.heightM,
      stylePreference: stylePreference ?? this.stylePreference,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'items': items.map((e) => e.toJson()).toList(),
        'photoPaths': photoPaths,
        'widthM': widthM,
        'lengthM': lengthM,
        'heightM': heightM,
        'stylePreference': stylePreference,
        'description': description,
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: '${json['id']}',
      name: json['name'] as String,
      kind: json['kind'] as String? ?? json['room_type'] as String? ?? 'other',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => RoomItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? [])
          .map((e) => '$e')
          .toList(),
      widthM: (json['widthM'] as num?)?.toDouble(),
      lengthM: (json['lengthM'] as num?)?.toDouble(),
      heightM: (json['heightM'] as num?)?.toDouble(),
      stylePreference: json['stylePreference'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, kind, items, photoPaths, widthM, lengthM, heightM];
}
