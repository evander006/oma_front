import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/properties_repository.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/shared/models/room_item.dart';
import 'package:uuid/uuid.dart';

class PropertiesState extends Equatable {
  const PropertiesState({
    this.properties = const [],
    this.loading = false,
    this.error,
  });

  final List<Property> properties;
  final bool loading;
  final String? error;

  Property? get selected {
    try {
      return properties.firstWhere((p) => p.selected);
    } catch (_) {
      return properties.isEmpty ? null : properties.first;
    }
  }

  bool get hasProperty => properties.isNotEmpty;

  @override
  List<Object?> get props => [properties, loading, error];
}

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit(this._repo) : super(const PropertiesState()) {
    load();
  }

  final PropertiesRepository _repo;
  static const _uuid = Uuid();

  Future<void> load() async {
    emit(PropertiesState(properties: state.properties, loading: true));
    try {
      final list = await _repo.load();
      emit(PropertiesState(properties: list));
    } catch (e) {
      emit(PropertiesState(properties: state.properties, error: '$e'));
    }
  }

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
    PropertyTenure? tenure,
  }) async {
    final draft = await _repo.createDraft(
      name: name,
      type: type,
      address: address,
      areaSqm: areaSqm,
      livingRooms: livingRooms,
      budgetByn: budgetByn,
      goal: goal,
      tenure: tenure,
      isDraft: false,
    );
    final cleared = state.properties
        .where((p) => p.id != draft.id)
        .map((p) => p.copyWith(selected: false))
        .toList();
    final property = draft.copyWith(selected: true, isDraft: false);
    await _persist([property, ...cleared]);
    // Reload to merge server truth (ids/rooms) when remote.
    await load();
    return state.properties.firstWhere(
      (p) => p.id == property.id,
      orElse: () => property,
    );
  }

  Future<Property> addDraft({
    required String name,
    required PropertyType type,
    PropertyTenure? tenure,
  }) async {
    final draft = await _repo.createDraft(
      name: name,
      type: type,
      tenure: tenure,
      isDraft: true,
    );
    final cleared =
        state.properties.map((p) => p.copyWith(selected: false)).toList();
    await _persist([draft.copyWith(selected: true), ...cleared]);
    await load();
    return state.selected ?? draft;
  }

  Future<void> upsert(Property property) async {
    var persisted = property;
    try {
      persisted = await _repo.updateProperty(property);
    } catch (_) {
      // The local overlay remains usable when the remote API is unavailable.
    }
    final exists = state.properties.any((p) => p.id == property.id);
    final list = exists
        ? state.properties
            .map((p) => p.id == property.id ? persisted : p)
            .toList()
        : [persisted, ...state.properties];
    await _persist(list);
  }

  Future<void> addRoom(String propertyId, Room room) async {
    final created = await _repo.createRoom(
      propertyId: propertyId,
      name: room.name,
      kind: room.kind,
    );
    final list = state.properties.map((p) {
      if (p.id != propertyId) return p;
      return p.copyWith(rooms: [...p.rooms, created]);
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
    try {
      await _repo.addPlacement(roomId: roomId, productId: productId);
    } catch (_) {
      // Keep local item even if placement API fails.
    }

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
    var persisted = room;
    try {
      persisted = await _repo.updateRoom(propertyId: propertyId, room: room);
    } catch (_) {
      // Keep the edit in the local overlay if the API is temporarily unavailable.
    }
    final list = state.properties.map((p) {
      if (p.id != propertyId) return p;
      return p.copyWith(
        rooms: p.rooms.map((r) => r.id == room.id ? persisted : r).toList(),
      );
    }).toList();
    await _persist(list);
  }

  Future<void> removeProperty(String id) async {
    await _repo.deleteProperty(id);
    await _persist(state.properties.where((p) => p.id != id).toList());
  }
}
