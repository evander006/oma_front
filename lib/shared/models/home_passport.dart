import 'package:equatable/equatable.dart';

class HomeEquipment extends Equatable {
  const HomeEquipment({
    required this.id,
    required this.propertyId,
    required this.name,
    this.roomId,
    this.roomName,
    this.productId,
    this.category,
    this.brand,
    this.model,
    this.serialNumber,
    this.specifications = const {},
    this.installedAt,
    this.warrantyUntil,
    this.contractorId,
    this.contractorName,
    this.workOrderId,
    this.source = 'manual',
    this.isDemonstration = false,
  });

  final String id;
  final String propertyId;
  final String? roomId;
  final String? roomName;
  final String? productId;
  final String name;
  final String? category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final Map<String, String> specifications;
  final DateTime? installedAt;
  final DateTime? warrantyUntil;
  final String? contractorId;
  final String? contractorName;
  final String? workOrderId;
  final String source;
  final bool isDemonstration;

  String get subtitle {
    final parts = <String>[
      if (brand != null) brand!,
      if (model != null) model!,
      if (roomName != null) roomName!,
    ];
    return parts.isEmpty ? 'Характеристики можно дополнить позже' : parts.join(' · ');
  }

  factory HomeEquipment.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specifications'] ?? json['specifications_snapshot'] ?? {};
    return HomeEquipment(
      id: '${json['id']}',
      propertyId: '${json['property_id'] ?? ''}',
      roomId: json['room_id']?.toString(),
      roomName: json['room_name']?.toString(),
      productId: json['product_id']?.toString(),
      name: (json['name'] ?? json['product_name'] ?? 'Оборудование').toString(),
      category: json['category']?.toString(),
      brand: json['brand']?.toString(),
      model: (json['model'] ?? json['model_name'])?.toString(),
      serialNumber: json['serial_number']?.toString(),
      specifications: rawSpecs is Map
          ? rawSpecs.map((key, value) => MapEntry('$key', '$value'))
          : const {},
      installedAt: _date(json['installed_at']),
      warrantyUntil: _date(json['warranty_until']),
      contractorId: json['contractor_id']?.toString(),
      contractorName: json['contractor_name']?.toString(),
      workOrderId: json['work_order_id']?.toString(),
      source: json['source']?.toString() ?? 'manual',
      isDemonstration: json['is_demonstration'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'room_id': roomId,
        'room_name': roomName,
        'product_id': productId,
        'name': name,
        'category': category,
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'specifications': specifications,
        'installed_at': installedAt?.toIso8601String(),
        'warranty_until': warrantyUntil?.toIso8601String(),
        'contractor_id': contractorId,
        'contractor_name': contractorName,
        'work_order_id': workOrderId,
        'source': source,
        'is_demonstration': isDemonstration,
      };

  @override
  List<Object?> get props => [id, propertyId, roomId, name, specifications, installedAt];
}

class HomeHistoryEvent extends Equatable {
  const HomeHistoryEvent({
    required this.id,
    required this.propertyId,
    required this.eventType,
    required this.title,
    this.description,
    this.roomId,
    this.roomName,
    this.contractorId,
    this.contractorName,
    this.workOrderId,
    this.productIds = const [],
    this.occurredAt,
    this.isDemonstration = false,
  });

  final String id;
  final String propertyId;
  final String eventType;
  final String title;
  final String? description;
  final String? roomId;
  final String? roomName;
  final String? contractorId;
  final String? contractorName;
  final String? workOrderId;
  final List<String> productIds;
  final DateTime? occurredAt;
  final bool isDemonstration;

  factory HomeHistoryEvent.fromJson(Map<String, dynamic> json) => HomeHistoryEvent(
        id: '${json['id']}',
        propertyId: '${json['property_id'] ?? ''}',
        eventType: json['event_type']?.toString() ?? 'note',
        title: json['title']?.toString() ?? 'Событие',
        description: json['description']?.toString(),
        roomId: json['room_id']?.toString(),
        roomName: json['room_name']?.toString(),
        contractorId: json['contractor_id']?.toString(),
        contractorName: json['contractor_name']?.toString(),
        workOrderId: json['work_order_id']?.toString(),
        productIds: (json['product_ids'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(growable: false),
        occurredAt: _date(json['occurred_at'] ?? json['created_at']),
        isDemonstration: json['is_demonstration'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, propertyId, eventType, title, occurredAt];
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
