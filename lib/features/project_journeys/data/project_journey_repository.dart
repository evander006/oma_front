import 'dart:convert';

import 'package:oma/core/network/api_config.dart';
import 'package:oma/core/network/dio_client.dart';
import 'package:oma/features/project_journeys/domain/project_journey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class ProjectJourneyRepository {
  bool get isDemo;

  Future<List<JourneyTemplate>> templates();

  Future<List<ProjectJourney>> journeys();

  Future<ProjectJourney> startJourney({
    required String templateId,
    String? propertyId,
    String? roomId,
  });

  Future<ProjectJourney> completeStep({
    required String journeyId,
    required String stepId,
  });
}

class RemoteProjectJourneyRepository implements ProjectJourneyRepository {
  RemoteProjectJourneyRepository(this._client);

  final DioClient _client;

  @override
  bool get isDemo => false;

  @override
  Future<List<JourneyTemplate>> templates() async {
    final data = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/journeys/templates',
    );
    return _rows(data)
        .map((row) => JourneyTemplate.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<List<ProjectJourney>> journeys() async {
    final data = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/journeys',
    );
    return _rows(data)
        .map((row) => ProjectJourney.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<ProjectJourney> startJourney({
    required String templateId,
    String? propertyId,
    String? roomId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/journeys',
      data: {
        'template_id': templateId,
        if (propertyId != null) 'property_id': int.tryParse(propertyId) ?? propertyId,
        if (roomId != null) 'room_id': int.tryParse(roomId) ?? roomId,
      },
    );
    return ProjectJourney.fromJson(_objectBody(data));
  }

  @override
  Future<ProjectJourney> completeStep({
    required String journeyId,
    required String stepId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/journeys/${Uri.encodeComponent(journeyId)}/steps/${Uri.encodeComponent(stepId)}/complete',
    );
    return ProjectJourney.fromJson(_objectBody(data));
  }

  static List<Map<String, dynamic>> _rows(dynamic data) {
    final raw = data is Map ? data['items'] ?? data['journeys'] ?? data['templates'] : data;
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static Map<String, dynamic> _objectBody(Map<String, dynamic> data) {
    final nested = data['journey'];
    return nested is Map ? Map<String, dynamic>.from(nested) : data;
  }
}

class PersistedDemoProjectJourneyRepository
    implements ProjectJourneyRepository {
  PersistedDemoProjectJourneyRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'oma_project_journeys_demo_v1';
  static const _uuid = Uuid();

  @override
  bool get isDemo => true;

  @override
  Future<List<JourneyTemplate>> templates() async => demoJourneyTemplates;

  @override
  Future<List<ProjectJourney>> journeys() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (row) => ProjectJourney.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ProjectJourney> startJourney({
    required String templateId,
    String? propertyId,
    String? roomId,
  }) async {
    JourneyTemplate? template;
    for (final item in demoJourneyTemplates) {
      if (item.id == templateId) {
        template = item;
        break;
      }
    }
    if (template == null) {
      throw StateError('Шаблон маршрута не найден');
    }
    final steps = <JourneyStep>[];
    for (var index = 0; index < template.steps.length; index++) {
      steps.add(
        template.steps[index].copyWith(
          status: index == 0
              ? JourneyStepStatus.current
              : JourneyStepStatus.locked,
        ),
      );
    }
    final journey = ProjectJourney(
      id: _uuid.v4(),
      templateId: template.id,
      title: template.title,
      propertyId: propertyId,
      roomId: roomId,
      steps: steps,
      status: 'active',
      isDemo: true,
    );
    final items = await journeys();
    await _write([journey, ...items]);
    return journey;
  }

  @override
  Future<ProjectJourney> completeStep({
    required String journeyId,
    required String stepId,
  }) async {
    final items = await journeys();
    final index = items.indexWhere((item) => item.id == journeyId);
    if (index < 0) throw StateError('Маршрут не найден');
    final journey = items[index];
    final stepIndex = journey.steps.indexWhere((step) => step.id == stepId);
    if (stepIndex < 0) throw StateError('Этап не найден');
    final current = journey.steps[stepIndex];
    if (current.status == JourneyStepStatus.completed) return journey;
    if (current.status != JourneyStepStatus.current) {
      throw StateError('Сначала завершите текущий этап');
    }

    final steps = [...journey.steps];
    steps[stepIndex] = current.copyWith(
      status: JourneyStepStatus.completed,
      completedAt: DateTime.now(),
    );
    if (stepIndex + 1 < steps.length) {
      steps[stepIndex + 1] = steps[stepIndex + 1].copyWith(
        status: JourneyStepStatus.current,
      );
    }
    final updated = journey.copyWith(
      steps: steps,
      status: stepIndex + 1 == steps.length ? 'completed' : 'active',
    );
    items[index] = updated;
    await _write(items);
    return updated;
  }

  Future<void> _write(List<ProjectJourney> items) {
    return _prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

class FallbackProjectJourneyRepository implements ProjectJourneyRepository {
  FallbackProjectJourneyRepository(this.remote, this.demo);

  final ProjectJourneyRepository remote;
  final ProjectJourneyRepository demo;
  var _usingDemo = false;

  @override
  bool get isDemo => _usingDemo;

  Future<T> _try<T>(
    Future<T> Function() remoteCall,
    Future<T> Function() demoCall,
  ) async {
    try {
      final result = await remoteCall();
      _usingDemo = false;
      return result;
    } catch (_) {
      _usingDemo = true;
      return demoCall();
    }
  }

  @override
  Future<List<JourneyTemplate>> templates() =>
      _try(remote.templates, demo.templates);

  @override
  Future<List<ProjectJourney>> journeys() =>
      _try(remote.journeys, demo.journeys);

  @override
  Future<ProjectJourney> startJourney({
    required String templateId,
    String? propertyId,
    String? roomId,
  }) {
    return _try(
      () => remote.startJourney(
        templateId: templateId,
        propertyId: propertyId,
        roomId: roomId,
      ),
      () => demo.startJourney(
        templateId: templateId,
        propertyId: propertyId,
        roomId: roomId,
      ),
    );
  }

  @override
  Future<ProjectJourney> completeStep({
    required String journeyId,
    required String stepId,
  }) {
    return _try(
      () => remote.completeStep(journeyId: journeyId, stepId: stepId),
      () => demo.completeStep(journeyId: journeyId, stepId: stepId),
    );
  }
}

const demoJourneyTemplates = <JourneyTemplate>[
  JourneyTemplate(
    id: 'first-room',
    title: 'Ремонт первой комнаты',
    description: 'От плана и основных материалов до завершённой комнаты.',
    icon: 'room',
    isDemo: true,
    steps: [
      JourneyStep(
        id: 'plan',
        title: 'Спланировать ремонт',
        order: 1,
        description: 'Зафиксируйте комнату, бюджет и желаемый результат.',
      ),
      JourneyStep(
        id: 'base-materials',
        title: 'Подобрать основные материалы',
        order: 2,
        recommendedCategoryIds: ['flooring', 'wall-finishes'],
      ),
      JourneyStep(
        id: 'related-products',
        title: 'Добавить сопутствующие товары',
        order: 3,
        recommendedCategoryIds: ['lighting', 'tools'],
      ),
      JourneyStep(
        id: 'master',
        title: 'Выбрать мастера при необходимости',
        order: 4,
      ),
      JourneyStep(
        id: 'finish',
        title: 'Завершить проект',
        order: 5,
        reward: JourneyReward(
          title: 'Бонус за завершение маршрута',
          points: 250,
          description: 'Демонстрационная награда, не официальная скидка ОМА.',
        ),
      ),
    ],
  ),
  JourneyTemplate(
    id: 'first-apartment',
    title: 'Обустройство первой квартиры',
    description: 'Последовательный запуск ключевых зон нового жилья.',
    icon: 'apartment',
    isDemo: true,
    steps: [
      JourneyStep(id: 'measure', title: 'Снять размеры', order: 1),
      JourneyStep(id: 'essentials', title: 'Выбрать самое необходимое', order: 2),
      JourneyStep(id: 'kitchen-bath', title: 'Оборудовать кухню и санузел', order: 3),
      JourneyStep(id: 'lighting', title: 'Настроить освещение', order: 4),
      JourneyStep(id: 'finish', title: 'Сохранить паспорт жилья', order: 5),
    ],
  ),
  JourneyTemplate(
    id: 'bathroom',
    title: 'Ремонт ванной',
    description: 'Безопасная последовательность от замеров до установки.',
    icon: 'bath',
    isDemo: true,
    steps: [
      JourneyStep(id: 'plan', title: 'Проверить размеры и коммуникации', order: 1),
      JourneyStep(id: 'rough', title: 'Подобрать черновые материалы', order: 2),
      JourneyStep(id: 'finish', title: 'Выбрать плитку и сантехнику', order: 3),
      JourneyStep(id: 'install', title: 'Запланировать установку', order: 4),
    ],
  ),
  JourneyTemplate(
    id: 'house-build',
    title: 'Строительство дома',
    description: 'Крупные этапы в реальной строительной последовательности.',
    icon: 'house',
    isDemo: true,
    steps: [
      JourneyStep(id: 'foundation', title: 'Основание и фундамент', order: 1),
      JourneyStep(id: 'walls', title: 'Стены и перекрытия', order: 2),
      JourneyStep(id: 'roof', title: 'Крыша', order: 3),
      JourneyStep(id: 'utilities', title: 'Инженерные системы', order: 4),
      JourneyStep(id: 'finish', title: 'Отделка', order: 5),
    ],
  ),
  JourneyTemplate(
    id: 'dacha-season',
    title: 'Подготовка дачи к сезону',
    description: 'Проверка, ремонт и оснащение перед первым приездом.',
    icon: 'dacha',
    isDemo: true,
    steps: [
      JourneyStep(id: 'inspect', title: 'Осмотреть дом и участок', order: 1),
      JourneyStep(id: 'repair', title: 'Закрыть срочные ремонты', order: 2),
      JourneyStep(id: 'water', title: 'Проверить воду и электрику', order: 3),
      JourneyStep(id: 'garden', title: 'Подготовить сад и инвентарь', order: 4),
    ],
  ),
];
