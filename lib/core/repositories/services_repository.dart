import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/shared/models/home_service.dart';
import 'package:uuid/uuid.dart';

/// Catalog of individual renovation/installation services.
abstract class ServicesRepository {
  Future<List<HomeService>> categories();
  Future<List<HomeService>> all();
  Future<HomeService?> byId(String id);
  Future<String> submitBooking(ServiceBookingDraft draft);
}

class LocalServicesRepository implements ServicesRepository {
  static const _uuid = Uuid();

  static const _services = <HomeService>[
    HomeService(
      id: 'svc_plumbing',
      title: 'Сантехнические работы',
      category: 'Сантехника',
      description: 'Установка смесителей, сифонов, подключение техники.',
      priceFromByn: 45,
      unitHint: 'за точку',
      priceVerified: true,
      relatedCategoryIds: ['plumbing'],
    ),
    HomeService(
      id: 'svc_electro',
      title: 'Электромонтаж',
      category: 'Электрика',
      description: 'Розетки, выключатели, освещение, щит.',
      priceFromByn: 35,
      unitHint: 'за точку',
      priceVerified: true,
    ),
    HomeService(
      id: 'svc_paint',
      title: 'Покраска стен',
      category: 'Отделка',
      description: 'Подготовка и покраска стен/потолков.',
      unitHint: 'за м²',
    ),
    HomeService(
      id: 'svc_wallpaper',
      title: 'Поклейка обоев',
      category: 'Отделка',
      description: 'Поклейка обоев с подгонкой рисунка.',
      unitHint: 'за м²',
    ),
    HomeService(
      id: 'svc_tile',
      title: 'Укладка плитки',
      category: 'Отделка',
      description: 'Керамика и керамогранит на пол и стены.',
      unitHint: 'за м²',
    ),
    HomeService(
      id: 'svc_flooring',
      title: 'Укладка напольных покрытий',
      category: 'Полы',
      description: 'Ламинат, SPC, паркетная доска.',
      unitHint: 'за м²',
    ),
    HomeService(
      id: 'svc_furniture',
      title: 'Сборка мебели',
      category: 'Мебель',
      description: 'Сборка корпусной мебели по инструкции.',
      priceFromByn: 50,
      unitHint: 'за изделие',
      priceVerified: true,
    ),
    HomeService(
      id: 'svc_doors',
      title: 'Установка дверей',
      category: 'Двери',
      description: 'Монтаж межкомнатных дверей и фурнитуры.',
      priceFromByn: 80,
      unitHint: 'за дверь',
      priceVerified: true,
    ),
    HomeService(
      id: 'svc_lighting',
      title: 'Монтаж освещения',
      category: 'Электрика',
      description: 'Люстры, споты, треки, подсветка.',
      priceFromByn: 25,
      unitHint: 'за точку',
      priceVerified: true,
    ),
    HomeService(
      id: 'svc_other',
      title: 'Другие работы',
      category: 'Прочее',
      description: 'Опишите задачу — уточним состав и стоимость.',
    ),
  ];

  @override
  Future<List<HomeService>> all() async => List.unmodifiable(_services);

  @override
  Future<List<HomeService>> categories() async {
    final seen = <String>{};
    final out = <HomeService>[];
    for (final s in _services) {
      if (seen.add(s.category)) out.add(s);
    }
    return out;
  }

  @override
  Future<HomeService?> byId(String id) async {
    try {
      return _services.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> submitBooking(ServiceBookingDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'SRV-${_uuid.v4().substring(0, 8).toUpperCase()}';
  }
}

class RemoteServicesRepository implements ServicesRepository {
  RemoteServicesRepository(this._client);

  final DioClient _client;
  List<HomeService>? _cache;

  HomeService _map(Map<String, dynamic> json) {
    final priceRaw = json['unit_price'];
    double? price;
    if (priceRaw != null) {
      price = priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse('$priceRaw');
    }
    final verified = json['price_verified'] == true;
    return HomeService(
      id: '${json['id']}',
      title: '${json['name'] ?? ''}',
      category: '${json['category'] ?? 'Услуги'}',
      description: json['description']?.toString() ??
          (verified ? null : json['price_note']?.toString()),
      priceFromByn: price,
      unitHint: json['unit']?.toString(),
      priceVerified: verified,
      relatedCategoryIds: const [],
    );
  }

  Future<List<HomeService>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final data = await _client.get<List<dynamic>>(
        '${ApiConfig.apiPrefix}/renovation/services',
      );
      _cache = data
          .whereType<Map>()
          .map((e) => _map(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return _cache!;
    } catch (_) {
      return LocalServicesRepository().all();
    }
  }

  @override
  Future<List<HomeService>> all() => _load();

  @override
  Future<List<HomeService>> categories() async {
    final all = await _load();
    final seen = <String>{};
    return [
      for (final s in all)
        if (seen.add(s.category)) s,
    ];
  }

  @override
  Future<HomeService?> byId(String id) async {
    final all = await _load();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> submitBooking(ServiceBookingDraft draft) async {
    final serviceId = int.tryParse(draft.serviceId);
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/renovation/installation-requests',
      data: {
        'service_id': serviceId,
        'address': draft.address,
        'preferred_dates': draft.preferredDate,
        'notes': [
          if (draft.roomLabel != null) 'Комната: ${draft.roomLabel}',
          if (draft.volumeHint != null && draft.volumeHint!.isNotEmpty)
            'Объём: ${draft.volumeHint}',
          if (draft.contactName != null) 'Имя: ${draft.contactName}',
          if (draft.contactPhone != null) 'Тел: ${draft.contactPhone}',
          if (draft.notes != null) draft.notes,
          if (draft.photoAssets.isNotEmpty)
            'Фото (локальные): ${draft.photoAssets.length}',
        ].whereType<String>().join('\n'),
      },
    );
    return '${data['id'] ?? 'ok'}';
  }
}
