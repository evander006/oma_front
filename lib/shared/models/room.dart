import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/room_item.dart';

class Room extends Equatable {
  const Room({
    required this.id,
    required this.name,
    required this.kind,
    this.items = const [],
    this.photoPaths = const [],
  });

  final String id;
  final String name;
  final String kind;
  final List<RoomItem> items;
  final List<String> photoPaths;

  Room copyWith({
    String? name,
    List<RoomItem>? items,
    List<String>? photoPaths,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      kind: kind,
      items: items ?? this.items,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'items': items.map((e) => e.toJson()).toList(),
        'photoPaths': photoPaths,
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => RoomItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, kind, items, photoPaths];
}
