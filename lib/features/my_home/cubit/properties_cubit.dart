import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/properties_repository.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/shared/models/room_item.dart';
import 'package:uuid/uuid.dart';

class PropertiesState extends Equatable {
  const PropertiesState({this.properties = const []});

  final List<Property> properties;

  Property? get selected {
    try {
      return properties.firstWhere((p) => p.selected);
    } catch (_) {
      return properties.isEmpty ? null : properties.first;
    }
  }

  bool get hasProperty => properties.isNotEmpty;

  @override
  List<Object?> get props => [properties];
}

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit(this._repo) : super(const PropertiesState()) {
    emit(PropertiesState(properties: _repo.load()));
  }

  final PropertiesRepository _repo;
  static const _uuid = Uuid();

  Future<void> _persist(List<Property> list) async {
    emit(PropertiesState(properties: list));
    await _repo.save(list);
  }

  Future<Property> addFromOnboarding({
    required String name,
    required PropertyType type,
    String? address,
    double? areaSqm,
    int? livingRooms,
    double? budgetByn,
    String? goal,
  }) async {
    final draft = _repo.createDraft(
      name: name,
      type: type,
      address: address,
      areaSqm: areaSqm,
      livingRooms: livingRooms,
      budgetByn: budgetByn,
      goal: goal,
      isDraft: false,
    );
    final cleared = state.properties
        .map((p) => p.copyWith(selected: false))
        .toList();
    final property = draft.copyWith(selected: true, isDraft: false);
    await _persist([property, ...cleared]);
    return property;
  }

  Future<Property> addDraft({
    required String name,
    required PropertyType type,
  }) async {
    final draft = _repo.createDraft(name: name, type: type, isDraft: true);
    await _persist([draft, ...state.properties]);
    return draft;
  }

  Future<void> upsert(Property property) async {
    final exists = state.properties.any((p) => p.id == property.id);
    final list = exists
        ? state.properties
            .map((p) => p.id == property.id ? property : p)
            .toList()
        : [property, ...state.properties];
    await _persist(list);
  }

  Future<void> addRoom(String propertyId, Room room) async {
    final list = state.properties.map((p) {
      if (p.id != propertyId) return p;
      return p.copyWith(rooms: [...p.rooms, room]);
    }).toList();
    await _persist(list);
  }

  Future<void> select(String id) async {
    final list = state.properties
        .map((p) => p.copyWith(selected: p.id == id))
        .toList();
    await _persist(list);
  }

  Future<void> rename(String id, String name) async {
    final list = state.properties
        .map((p) => p.id == id ? p.copyWith(name: name) : p)
        .toList();
    await _persist(list);
  }

  Future<void> addItemToRoom({
    required String propertyId,
    required String roomId,
    required String productId,
    required String name,
    int qty = 1,
  }) async {
    final list = state.properties.map((p) {
      if (p.id != propertyId) return p;
      final rooms = p.rooms.map((r) {
        if (r.id != roomId) return r;
        final existing = r.items.indexWhere((i) => i.productId == productId);
        if (existing >= 0) {
          final items = [...r.items];
          items[existing] =
              items[existing].copyWith(qty: items[existing].qty + qty);
          return r.copyWith(items: items);
        }
        return r.copyWith(items: [
          ...r.items,
          RoomItem(
            id: _uuid.v4(),
            productId: productId,
            name: name,
            qty: qty,
          ),
        ]);
      }).toList();
      return p.copyWith(rooms: rooms);
    }).toList();
    await _persist(list);
  }

  Future<void> updateRoom(String propertyId, Room room) async {
    final list = state.properties.map((p) {
      if (p.id != propertyId) return p;
      return p.copyWith(
        rooms: p.rooms.map((r) => r.id == room.id ? room : r).toList(),
      );
    }).toList();
    await _persist(list);
  }
}
