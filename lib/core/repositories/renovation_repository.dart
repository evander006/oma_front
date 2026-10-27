import 'dart:convert';

import 'package:oma/shared/models/renovation_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local persistence for turnkey renovation drafts/requests.
/// Backend endpoint for submission is not available yet — boundary ready.
abstract class RenovationRepository {
  Future<List<RenovationRequest>> list();
  Future<RenovationRequest?> byId(String id);
  Future<RenovationRequest> save(RenovationRequest request);
  Future<RenovationRequest> createDraft();
  Future<void> delete(String id);
  Future<RenovationRequest> submit(RenovationRequest request);
}

class LocalRenovationRepository implements RenovationRepository {
  LocalRenovationRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'oma_renovation_requests_v1';
  static const _uuid = Uuid();

  List<RenovationRequest> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => RenovationRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<RenovationRequest> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  @override
  Future<List<RenovationRequest>> list() async {
    final items = _read()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000))
            .compareTo(a.updatedAt ?? DateTime(2000)),
      );
    return List.unmodifiable(items);
  }

  @override
  Future<RenovationRequest?> byId(String id) async {
    try {
      return _read().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RenovationRequest> createDraft() async {
    final draft = RenovationRequest(
      id: _uuid.v4(),
      updatedAt: DateTime.now(),
      name: 'Черновик ремонта',
    );
    final items = _read()..insert(0, draft);
    await _write(items);
    return draft;
  }

  @override
  Future<RenovationRequest> save(RenovationRequest request) async {
    final next = request.copyWith(updatedAt: DateTime.now());
    final items = _read();
    final idx = items.indexWhere((e) => e.id == next.id);
    if (idx >= 0) {
      items[idx] = next;
    } else {
      items.insert(0, next);
    }
    await _write(items);
    return next;
  }

  @override
  Future<void> delete(String id) async {
    final items = _read()..removeWhere((e) => e.id == id);
    await _write(items);
  }

  @override
  Future<RenovationRequest> submit(RenovationRequest request) async {
    // No remote renovation endpoint yet — persist as submitted locally.
    return save(
      request.copyWith(
        status: RenovationProjectStatus.submitted,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
