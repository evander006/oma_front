import 'dart:convert';

import 'package:oma/core/data/mappers/renovation_mapper.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Turnkey renovation projects — local drafts and/or [oma_be] remote projects.
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
    return save(
      request.copyWith(
        status: RenovationProjectStatus.submitted,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

/// Remote projects from oma_be + local drafts until submit.
class RemoteRenovationRepository implements RenovationRepository {
  RemoteRenovationRepository(this._client, this._local);

  final DioClient _client;
  final LocalRenovationRepository _local;

  bool _isRemoteId(String id) => int.tryParse(id) != null;

  @override
  Future<List<RenovationRequest>> list() async {
    final remote = await _fetchRemote();
    final localDrafts = (await _local.list())
        .where((e) => e.status == RenovationProjectStatus.draft)
        .where((e) => !_isRemoteId(e.id))
        .toList();
    return [...localDrafts, ...remote];
  }

  Future<List<RenovationRequest>> _fetchRemote() async {
    final data = await _client.get<List<dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/projects',
    );
    return data
        .whereType<Map>()
        .map((e) => RenovationMapper.fromProjectJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  Future<RenovationRequest?> byId(String id) async {
    if (_isRemoteId(id)) {
      try {
        final data = await _client.get<Map<String, dynamic>>(
          '${ApiConfig.apiPrefix}/renovation/projects/$id',
        );
        return RenovationMapper.fromProjectJson(data);
      } catch (_) {
        return null;
      }
    }
    return _local.byId(id);
  }

  @override
  Future<RenovationRequest> createDraft() => _local.createDraft();

  @override
  Future<RenovationRequest> save(RenovationRequest request) async {
    if (_isRemoteId(request.id)) {
      final data = await _client.patch<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/renovation/projects/${request.id}',
        data: RenovationMapper.toProjectPatch(request),
      );
      return RenovationMapper.fromProjectJson(data);
    }
    return _local.save(request);
  }

  @override
  Future<void> delete(String id) async {
    if (_isRemoteId(id)) {
      await _client.delete('${ApiConfig.apiPrefix}/renovation/projects/$id');
      return;
    }
    await _local.delete(id);
  }

  @override
  Future<RenovationRequest> submit(RenovationRequest request) async {
    // Create full project on backend, then submit request envelope.
    final created = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/projects',
      data: RenovationMapper.toProjectCreate(request),
    );
    final projectId = created['id'];
    await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/requests',
      data: {
        'project_id': projectId,
        'request_type': 'turnkey',
        'notes': 'Заявка из Flutter · ремонт под ключ',
        'payload': RenovationMapper.toRequestPayload(request),
        'submit': true,
      },
    );
    await _client.patch<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/projects/$projectId',
      data: {'status': 'submitted'},
    );

    // Drop local draft after successful sync.
    if (!_isRemoteId(request.id)) {
      await _local.delete(request.id);
    }

    final refreshed = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/projects/$projectId',
    );
    return RenovationMapper.fromProjectJson(refreshed);
  }
}
