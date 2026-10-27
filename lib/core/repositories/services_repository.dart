import 'package:oma/shared/models/home_service.dart';
import 'package:uuid/uuid.dart';

/// Catalog of individual renovation/installation services.
/// Prices marked verified only when known; otherwise «Стоимость уточняется».
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
      relatedCategoryIds: ['plumbing'],
    ),
    HomeService(
      id: 'svc_electro',
      title: 'Электромонтаж',
      category: 'Электрика',
      description: 'Розетки, выключатели, освещение, щит.',
      priceFromByn: 35,
      unitHint: 'за точку',
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
    ),
    HomeService(
      id: 'svc_doors',
      title: 'Установка дверей',
      category: 'Двери',
      description: 'Монтаж межкомнатных дверей и фурнитуры.',
      priceFromByn: 80,
      unitHint: 'за дверь',
    ),
    HomeService(
      id: 'svc_lighting',
      title: 'Монтаж освещения',
      category: 'Электрика',
      description: 'Люстры, споты, треки, подсветка.',
      priceFromByn: 25,
      unitHint: 'за точку',
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
    // No remote services booking endpoint — return local demo request id.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'SRV-${_uuid.v4().substring(0, 8).toUpperCase()}';
  }
}
