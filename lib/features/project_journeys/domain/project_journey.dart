import 'package:equatable/equatable.dart';

enum JourneyStepStatus { locked, current, completed }

class JourneyReward extends Equatable {
  const JourneyReward({
    required this.title,
    this.points,
    this.description,
    this.isDemo = true,
  });

  final String title;
  final int? points;
  final String? description;
  final bool isDemo;

  factory JourneyReward.fromJson(Map<String, dynamic> json) {
    return JourneyReward(
      title: '${json['title'] ?? 'Награда'}',
      points: (json['points'] as num?)?.toInt(),
      description: json['description']?.toString(),
      isDemo: json['is_demo'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'points': points,
        'description': description,
        'is_demo': isDemo,
      };

  @override
  List<Object?> get props => [title, points, description, isDemo];
}

class JourneyStep extends Equatable {
  const JourneyStep({
    required this.id,
    required this.title,
    required this.order,
    this.description,
    this.recommendedCategoryIds = const [],
    this.reward,
    this.status = JourneyStepStatus.locked,
    this.completedAt,
  });

  final String id;
  final String title;
  final int order;
  final String? description;
  final List<String> recommendedCategoryIds;
  final JourneyReward? reward;
  final JourneyStepStatus status;
  final DateTime? completedAt;

  JourneyStep copyWith({
    JourneyStepStatus? status,
    DateTime? completedAt,
  }) {
    return JourneyStep(
      id: id,
      title: title,
      order: order,
      description: description,
      recommendedCategoryIds: recommendedCategoryIds,
      reward: reward,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    final rewardRaw = json['reward'];
    return JourneyStep(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      order: (json['order'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      recommendedCategoryIds:
          (json['recommended_category_ids'] as List<dynamic>? ?? const [])
              .map((value) => '$value')
              .toList(growable: false),
      reward: rewardRaw is Map
          ? JourneyReward.fromJson(Map<String, dynamic>.from(rewardRaw))
          : null,
      status: _statusFromJson(json['status']),
      completedAt: DateTime.tryParse('${json['completed_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'order': order,
        'description': description,
        'recommended_category_ids': recommendedCategoryIds,
        'reward': reward?.toJson(),
        'status': status.name,
        'completed_at': completedAt?.toIso8601String(),
      };

  static JourneyStepStatus _statusFromJson(dynamic raw) {
    final name = '$raw';
    for (final value in JourneyStepStatus.values) {
      if (value.name == name) return value;
    }
    return JourneyStepStatus.locked;
  }

  @override
  List<Object?> get props => [id, title, order, status, completedAt, reward];
}

class JourneyTemplate extends Equatable {
  const JourneyTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.icon = 'route',
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final List<JourneyStep> steps;
  final bool isDemo;

  factory JourneyTemplate.fromJson(Map<String, dynamic> json) {
    return JourneyTemplate(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      icon: '${json['icon'] ?? 'route'}',
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => JourneyStep.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      isDemo: json['is_demo'] == true,
    );
  }

  @override
  List<Object?> get props => [id, title, steps, isDemo];
}

class ProjectJourney extends Equatable {
  const ProjectJourney({
    required this.id,
    required this.templateId,
    required this.title,
    required this.steps,
    required this.status,
    this.propertyId,
    this.roomId,
    this.isDemo = false,
  });

  final String id;
  final String templateId;
  final String title;
  final String? propertyId;
  final String? roomId;
  final List<JourneyStep> steps;
  final String status;
  final bool isDemo;

  int get completedCount =>
      steps.where((step) => step.status == JourneyStepStatus.completed).length;

  double get progress => steps.isEmpty ? 0 : completedCount / steps.length;

  JourneyStep? get currentStep {
    for (final step in steps) {
      if (step.status == JourneyStepStatus.current) return step;
    }
    return null;
  }

  ProjectJourney copyWith({
    List<JourneyStep>? steps,
    String? status,
  }) {
    return ProjectJourney(
      id: id,
      templateId: templateId,
      title: title,
      propertyId: propertyId,
      roomId: roomId,
      steps: steps ?? this.steps,
      status: status ?? this.status,
      isDemo: isDemo,
    );
  }

  factory ProjectJourney.fromJson(Map<String, dynamic> json) {
    final template = json['template'];
    final templateMap = template is Map
        ? Map<String, dynamic>.from(template)
        : const <String, dynamic>{};
    final stepsRaw = json['steps'] ?? templateMap['steps'];
    return ProjectJourney(
      id: '${json['id']}',
      templateId: '${json['template_id'] ?? templateMap['id'] ?? ''}',
      title: '${json['title'] ?? templateMap['title'] ?? 'Проектный маршрут'}',
      propertyId: json['property_id']?.toString(),
      roomId: json['room_id']?.toString(),
      steps: (stepsRaw as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => JourneyStep.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      status: '${json['status'] ?? 'active'}',
      isDemo: json['is_demo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'template_id': templateId,
        'title': title,
        'property_id': propertyId,
        'room_id': roomId,
        'steps': steps.map((step) => step.toJson()).toList(),
        'status': status,
        'is_demo': isDemo,
      };

  @override
  List<Object?> get props => [id, steps, status, isDemo];
}
