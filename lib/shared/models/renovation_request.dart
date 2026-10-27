import 'package:equatable/equatable.dart';

enum RenovationPropertyKind { apartment, house, other }

enum RenovationScope {
  turnkey,
  cosmetic,
  major,
  newFinish,
  consultation,
}

enum MaterialTier { standard, balanced, premium }

enum RenovationProjectStatus {
  draft,
  submitted,
  awaitingConsultation,
  estimatePreparing,
  estimateApproved,
  scheduled,
  inProgress,
  completed,
}

extension RenovationProjectStatusRu on RenovationProjectStatus {
  String get labelRu => switch (this) {
        RenovationProjectStatus.draft => 'Черновик',
        RenovationProjectStatus.submitted => 'Заявка отправлена',
        RenovationProjectStatus.awaitingConsultation => 'Ожидает консультации',
        RenovationProjectStatus.estimatePreparing => 'Смета готовится',
        RenovationProjectStatus.estimateApproved => 'Смета согласована',
        RenovationProjectStatus.scheduled => 'Работы запланированы',
        RenovationProjectStatus.inProgress => 'В работе',
        RenovationProjectStatus.completed => 'Завершён',
      };
}

class RenovationRequest extends Equatable {
  const RenovationRequest({
    required this.id,
    this.propertyKind,
    this.scope,
    this.areaSqm,
    this.roomsCount,
    this.housingAge,
    this.condition,
    this.occupancy,
    this.selectedRooms = const {},
    this.workCategories = const {},
    this.photoAssets = const [],
    this.floorPlanAsset,
    this.style,
    this.styleNotes,
    this.budgetRange,
    this.startDateIso,
    this.timeline,
    this.flexibleTimeline = false,
    this.materialTier,
    this.omaSuppliesMaterials = true,
    this.needInstallation = true,
    this.needWasteRemoval = false,
    this.needFurniture = false,
    this.needLighting = false,
    this.address,
    this.contactMethod,
    this.contactName,
    this.contactPhone,
    this.consentPersonalData = false,
    this.status = RenovationProjectStatus.draft,
    this.updatedAt,
    this.name,
  });

  final String id;
  final RenovationPropertyKind? propertyKind;
  final RenovationScope? scope;
  final double? areaSqm;
  final int? roomsCount;
  final String? housingAge;
  final String? condition;
  final String? occupancy;
  final Set<String> selectedRooms;
  final Set<String> workCategories;
  final List<String> photoAssets;
  final String? floorPlanAsset;
  final String? style;
  final String? styleNotes;
  final String? budgetRange;
  final String? startDateIso;
  final String? timeline;
  final bool flexibleTimeline;
  final MaterialTier? materialTier;
  final bool omaSuppliesMaterials;
  final bool needInstallation;
  final bool needWasteRemoval;
  final bool needFurniture;
  final bool needLighting;
  final String? address;
  final String? contactMethod;
  final String? contactName;
  final String? contactPhone;
  final bool consentPersonalData;
  final RenovationProjectStatus status;
  final DateTime? updatedAt;
  final String? name;

  static const roomOptions = [
    'Кухня',
    'Гостиная',
    'Спальня',
    'Детская',
    'Санузел',
    'Прихожая',
    'Другие помещения',
  ];

  static const workOptions = [
    'Демонтаж',
    'Электрика',
    'Сантехника',
    'Отделка стен',
    'Полы',
    'Потолки',
    'Двери',
    'Мебель',
  ];

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    final kind = switch (propertyKind) {
      RenovationPropertyKind.apartment => 'Квартира',
      RenovationPropertyKind.house => 'Дом',
      RenovationPropertyKind.other => 'Помещение',
      null => 'Ремонт',
    };
    return '$kind · заявка';
  }

  RenovationRequest copyWith({
    RenovationPropertyKind? propertyKind,
    RenovationScope? scope,
    double? areaSqm,
    int? roomsCount,
    String? housingAge,
    String? condition,
    String? occupancy,
    Set<String>? selectedRooms,
    Set<String>? workCategories,
    List<String>? photoAssets,
    String? floorPlanAsset,
    String? style,
    String? styleNotes,
    String? budgetRange,
    String? startDateIso,
    String? timeline,
    bool? flexibleTimeline,
    MaterialTier? materialTier,
    bool? omaSuppliesMaterials,
    bool? needInstallation,
    bool? needWasteRemoval,
    bool? needFurniture,
    bool? needLighting,
    String? address,
    String? contactMethod,
    String? contactName,
    String? contactPhone,
    bool? consentPersonalData,
    RenovationProjectStatus? status,
    DateTime? updatedAt,
    String? name,
    bool clearFloorPlan = false,
  }) {
    return RenovationRequest(
      id: id,
      propertyKind: propertyKind ?? this.propertyKind,
      scope: scope ?? this.scope,
      areaSqm: areaSqm ?? this.areaSqm,
      roomsCount: roomsCount ?? this.roomsCount,
      housingAge: housingAge ?? this.housingAge,
      condition: condition ?? this.condition,
      occupancy: occupancy ?? this.occupancy,
      selectedRooms: selectedRooms ?? this.selectedRooms,
      workCategories: workCategories ?? this.workCategories,
      photoAssets: photoAssets ?? this.photoAssets,
      floorPlanAsset:
          clearFloorPlan ? null : (floorPlanAsset ?? this.floorPlanAsset),
      style: style ?? this.style,
      styleNotes: styleNotes ?? this.styleNotes,
      budgetRange: budgetRange ?? this.budgetRange,
      startDateIso: startDateIso ?? this.startDateIso,
      timeline: timeline ?? this.timeline,
      flexibleTimeline: flexibleTimeline ?? this.flexibleTimeline,
      materialTier: materialTier ?? this.materialTier,
      omaSuppliesMaterials: omaSuppliesMaterials ?? this.omaSuppliesMaterials,
      needInstallation: needInstallation ?? this.needInstallation,
      needWasteRemoval: needWasteRemoval ?? this.needWasteRemoval,
      needFurniture: needFurniture ?? this.needFurniture,
      needLighting: needLighting ?? this.needLighting,
      address: address ?? this.address,
      contactMethod: contactMethod ?? this.contactMethod,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      consentPersonalData: consentPersonalData ?? this.consentPersonalData,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyKind': propertyKind?.name,
        'scope': scope?.name,
        'areaSqm': areaSqm,
        'roomsCount': roomsCount,
        'housingAge': housingAge,
        'condition': condition,
        'occupancy': occupancy,
        'selectedRooms': selectedRooms.toList(),
        'workCategories': workCategories.toList(),
        'photoAssets': photoAssets,
        'floorPlanAsset': floorPlanAsset,
        'style': style,
        'styleNotes': styleNotes,
        'budgetRange': budgetRange,
        'startDateIso': startDateIso,
        'timeline': timeline,
        'flexibleTimeline': flexibleTimeline,
        'materialTier': materialTier?.name,
        'omaSuppliesMaterials': omaSuppliesMaterials,
        'needInstallation': needInstallation,
        'needWasteRemoval': needWasteRemoval,
        'needFurniture': needFurniture,
        'needLighting': needLighting,
        'address': address,
        'contactMethod': contactMethod,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'consentPersonalData': consentPersonalData,
        'status': status.name,
        'updatedAt': updatedAt?.toIso8601String(),
        'name': name,
      };

  factory RenovationRequest.fromJson(Map<String, dynamic> json) {
    RenovationPropertyKind? kind;
    final kindName = json['propertyKind'] as String?;
    if (kindName != null) {
      kind = RenovationPropertyKind.values.byName(kindName);
    }
    RenovationScope? scope;
    final scopeName = json['scope'] as String?;
    if (scopeName != null) {
      scope = RenovationScope.values.byName(scopeName);
    }
    MaterialTier? tier;
    final tierName = json['materialTier'] as String?;
    if (tierName != null) {
      tier = MaterialTier.values.byName(tierName);
    }
    final statusName = json['status'] as String?;
    return RenovationRequest(
      id: json['id'] as String,
      propertyKind: kind,
      scope: scope,
      areaSqm: (json['areaSqm'] as num?)?.toDouble(),
      roomsCount: json['roomsCount'] as int?,
      housingAge: json['housingAge'] as String?,
      condition: json['condition'] as String?,
      occupancy: json['occupancy'] as String?,
      selectedRooms: {
        ...(json['selectedRooms'] as List<dynamic>? ?? const [])
            .map((e) => '$e'),
      },
      workCategories: {
        ...(json['workCategories'] as List<dynamic>? ?? const [])
            .map((e) => '$e'),
      },
      photoAssets: (json['photoAssets'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      floorPlanAsset: json['floorPlanAsset'] as String?,
      style: json['style'] as String?,
      styleNotes: json['styleNotes'] as String?,
      budgetRange: json['budgetRange'] as String?,
      startDateIso: json['startDateIso'] as String?,
      timeline: json['timeline'] as String?,
      flexibleTimeline: json['flexibleTimeline'] as bool? ?? false,
      materialTier: tier,
      omaSuppliesMaterials: json['omaSuppliesMaterials'] as bool? ?? true,
      needInstallation: json['needInstallation'] as bool? ?? true,
      needWasteRemoval: json['needWasteRemoval'] as bool? ?? false,
      needFurniture: json['needFurniture'] as bool? ?? false,
      needLighting: json['needLighting'] as bool? ?? false,
      address: json['address'] as String?,
      contactMethod: json['contactMethod'] as String?,
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      consentPersonalData: json['consentPersonalData'] as bool? ?? false,
      status: statusName == null
          ? RenovationProjectStatus.draft
          : RenovationProjectStatus.values.byName(statusName),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      name: json['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, updatedAt, selectedRooms, photoAssets];
}
