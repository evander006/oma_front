import 'package:equatable/equatable.dart';

enum SharedHomeField {
  address,
  roomDimensions,
  roomMaterials,
  installedEquipment,
  workHistory,
  photos,
}

extension SharedHomeFieldUi on SharedHomeField {
  String get apiValue => switch (this) {
        SharedHomeField.address => 'address',
        SharedHomeField.roomDimensions => 'room_dimensions',
        SharedHomeField.roomMaterials => 'room_materials',
        SharedHomeField.installedEquipment => 'installed_equipment',
        SharedHomeField.workHistory => 'work_history',
        SharedHomeField.photos => 'photos',
      };

  String get labelRu => switch (this) {
        SharedHomeField.address => 'Адрес объекта',
        SharedHomeField.roomDimensions => 'Размеры выбранной комнаты',
        SharedHomeField.roomMaterials => 'Материалы стен, пола и потолка',
        SharedHomeField.installedEquipment => 'Установленное оборудование',
        SharedHomeField.workHistory => 'История связанных работ',
        SharedHomeField.photos => 'Фотографии комнаты',
      };

  static SharedHomeField? fromApi(String value) {
    for (final field in SharedHomeField.values) {
      if (field.apiValue == value) return field;
    }
    return null;
  }
}

class MasterPortfolioItem extends Equatable {
  const MasterPortfolioItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;

  factory MasterPortfolioItem.fromJson(Map<String, dynamic> json) {
    return MasterPortfolioItem(
      id: '${json['id'] ?? json['title'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? 'Проект'}',
      description: json['description']?.toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
      };

  @override
  List<Object?> get props => [id, title, description, imageUrl];
}

class MasterReview extends Equatable {
  const MasterReview({
    required this.id,
    required this.author,
    required this.text,
    required this.rating,
    this.createdAt,
  });

  final String id;
  final String author;
  final String text;
  final double rating;
  final DateTime? createdAt;

  factory MasterReview.fromJson(Map<String, dynamic> json) {
    return MasterReview(
      id: '${json['id'] ?? json['author'] ?? ''}',
      author: '${json['author'] ?? json['author_name'] ?? 'Клиент'}',
      text: '${json['text'] ?? json['body'] ?? ''}',
      rating: _asDouble(json['rating']) ?? 0,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  @override
  List<Object?> get props => [id, author, text, rating, createdAt];
}

class MasterProfile extends Equatable {
  const MasterProfile({
    required this.id,
    required this.displayName,
    required this.city,
    required this.bio,
    required this.specialties,
    required this.experienceYears,
    required this.verified,
    required this.isFavorite,
    required this.isDemo,
    this.rating,
    this.reviewCount = 0,
    this.portfolio = const [],
    this.reviews = const [],
  });

  final String id;
  final String displayName;
  final String city;
  final String bio;
  final List<String> specialties;
  final int experienceYears;
  final bool verified;
  final bool isFavorite;
  final bool isDemo;
  final double? rating;
  final int reviewCount;
  final List<MasterPortfolioItem> portfolio;
  final List<MasterReview> reviews;

  MasterProfile copyWith({bool? isFavorite, bool? isDemo}) {
    return MasterProfile(
      id: id,
      displayName: displayName,
      city: city,
      bio: bio,
      specialties: specialties,
      experienceYears: experienceYears,
      verified: verified,
      isFavorite: isFavorite ?? this.isFavorite,
      isDemo: isDemo ?? this.isDemo,
      rating: rating,
      reviewCount: reviewCount,
      portfolio: portfolio,
      reviews: reviews,
    );
  }

  factory MasterProfile.fromJson(
    Map<String, dynamic> json, {
    bool demoFallback = false,
  }) {
    final specialtiesRaw = json['specialties'] as List<dynamic>? ?? const [];
    final portfolioRaw = json['portfolio'] as List<dynamic>? ?? const [];
    final reviewsRaw = json['reviews'] as List<dynamic>? ?? const [];
    return MasterProfile(
      id: '${json['id']}',
      displayName:
          '${json['display_name'] ?? json['displayName'] ?? json['name'] ?? 'Мастер'}',
      city: '${json['city'] ?? 'Беларусь'}',
      bio: '${json['bio'] ?? json['description'] ?? ''}',
      specialties: specialtiesRaw.map((value) {
        if (value is Map) return '${value['name'] ?? value['title'] ?? ''}';
        return '$value';
      }).where((value) => value.isNotEmpty).toList(growable: false),
      experienceYears:
          (json['experience_years'] as num?)?.toInt() ??
              (json['experienceYears'] as num?)?.toInt() ??
              0,
      verified: json['verified'] == true,
      isFavorite:
          json['is_favorite'] == true || json['isFavorite'] == true,
      isDemo: demoFallback || json['is_demo'] == true || json['isDemo'] == true,
      rating: _asDouble(json['rating']),
      reviewCount:
          (json['review_count'] as num?)?.toInt() ??
              (json['reviewCount'] as num?)?.toInt() ??
              reviewsRaw.length,
      portfolio: portfolioRaw
          .whereType<Map>()
          .map((item) => MasterPortfolioItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false),
      reviews: reviewsRaw
          .whereType<Map>()
          .map((item) => MasterReview.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        specialties,
        isFavorite,
        isDemo,
        rating,
        reviewCount,
      ];
}

enum MasterRequestStatus {
  submitted,
  accepted,
  materialsProposed,
  scheduled,
  inProgress,
  completed,
  declined,
}

extension MasterRequestStatusUi on MasterRequestStatus {
  String get apiValue => switch (this) {
        MasterRequestStatus.submitted => 'submitted',
        MasterRequestStatus.accepted => 'accepted',
        MasterRequestStatus.materialsProposed => 'materials_proposed',
        MasterRequestStatus.scheduled => 'scheduled',
        MasterRequestStatus.inProgress => 'in_progress',
        MasterRequestStatus.completed => 'completed',
        MasterRequestStatus.declined => 'declined',
      };

  String get labelRu => switch (this) {
        MasterRequestStatus.submitted => 'Новая заявка',
        MasterRequestStatus.accepted => 'Принята мастером',
        MasterRequestStatus.materialsProposed => 'Материалы предложены',
        MasterRequestStatus.scheduled => 'Работы запланированы',
        MasterRequestStatus.inProgress => 'В работе',
        MasterRequestStatus.completed => 'Завершена',
        MasterRequestStatus.declined => 'Отклонена',
      };

  static MasterRequestStatus fromApi(String? value) => switch (value) {
        'accepted' => MasterRequestStatus.accepted,
        'materials_proposed' => MasterRequestStatus.materialsProposed,
        'scheduled' => MasterRequestStatus.scheduled,
        'in_progress' => MasterRequestStatus.inProgress,
        'completed' => MasterRequestStatus.completed,
        'declined' => MasterRequestStatus.declined,
        _ => MasterRequestStatus.submitted,
      };
}

class MaterialProposalItem extends Equatable {
  const MaterialProposalItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPriceByn,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double? unitPriceByn;

  double get lineTotal => (unitPriceByn ?? 0) * quantity;

  factory MaterialProposalItem.fromJson(Map<String, dynamic> json) {
    return MaterialProposalItem(
      productId: '${json['product_id'] ?? json['productId'] ?? ''}',
      productName:
          '${json['product_name'] ?? json['productName'] ?? json['name'] ?? 'Товар из каталога'}',
      quantity:
          (json['quantity'] as num?)?.toInt() ??
              (json['qty'] as num?)?.toInt() ??
              1,
      unitPriceByn:
          _asDouble(json['unit_price_byn'] ?? json['unitPriceByn'] ?? json['price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price_byn': unitPriceByn,
      };

  @override
  List<Object?> get props => [productId, productName, quantity, unitPriceByn];
}

class MasterWorkRequest extends Equatable {
  const MasterWorkRequest({
    required this.id,
    required this.masterId,
    required this.masterName,
    required this.title,
    required this.description,
    required this.sharedFields,
    required this.status,
    required this.createdAt,
    required this.isDemo,
    this.propertyId,
    this.propertyName,
    this.roomId,
    this.roomName,
    this.budgetByn,
    this.materialProposal = const [],
  });

  final String id;
  final String masterId;
  final String masterName;
  final String title;
  final String description;
  final String? propertyId;
  final String? propertyName;
  final String? roomId;
  final String? roomName;
  final double? budgetByn;
  final Set<SharedHomeField> sharedFields;
  final MasterRequestStatus status;
  final DateTime createdAt;
  final bool isDemo;
  final List<MaterialProposalItem> materialProposal;

  double get proposalTotal => materialProposal.fold(
        0,
        (total, item) => total + item.lineTotal,
      );

  MasterWorkRequest copyWith({
    MasterRequestStatus? status,
    List<MaterialProposalItem>? materialProposal,
  }) {
    return MasterWorkRequest(
      id: id,
      masterId: masterId,
      masterName: masterName,
      title: title,
      description: description,
      propertyId: propertyId,
      propertyName: propertyName,
      roomId: roomId,
      roomName: roomName,
      budgetByn: budgetByn,
      sharedFields: sharedFields,
      status: status ?? this.status,
      createdAt: createdAt,
      isDemo: isDemo,
      materialProposal: materialProposal ?? this.materialProposal,
    );
  }

  factory MasterWorkRequest.fromJson(
    Map<String, dynamic> json, {
    bool demoFallback = false,
  }) {
    final fields = (json['shared_fields'] as List<dynamic>? ?? const [])
        .map((value) => SharedHomeFieldUi.fromApi('$value'))
        .whereType<SharedHomeField>()
        .toSet();
    final proposal = json['material_proposal'];
    final proposalItems = proposal is Map
        ? proposal['items'] as List<dynamic>? ?? const []
        : proposal as List<dynamic>? ?? const [];
    final contractor = json['contractor'] as Map?;
    final property = json['property'] as Map?;
    final room = json['room'] as Map?;
    return MasterWorkRequest(
      id: '${json['id']}',
      masterId:
          '${json['contractor_id'] ?? json['master_id'] ?? contractor?['id'] ?? ''}',
      masterName:
          '${json['contractor_name'] ?? json['master_name'] ?? contractor?['display_name'] ?? 'Мастер'}',
      title: '${json['title'] ?? 'Заявка на работу'}',
      description: '${json['description'] ?? json['details'] ?? ''}',
      propertyId:
          (json['property_id'] ?? property?['id'])?.toString(),
      propertyName:
          (json['property_name'] ?? property?['name'])?.toString(),
      roomId: (json['room_id'] ?? room?['id'])?.toString(),
      roomName: (json['room_name'] ?? room?['name'])?.toString(),
      budgetByn: _asDouble(json['budget_byn'] ?? json['budget']),
      sharedFields: fields,
      status: MasterRequestStatusUi.fromApi(json['status']?.toString()),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      isDemo: demoFallback || json['is_demo'] == true || json['isDemo'] == true,
      materialProposal: proposalItems
          .whereType<Map>()
          .map((item) => MaterialProposalItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractor_id': masterId,
        'contractor_name': masterName,
        'title': title,
        'description': description,
        'property_id': propertyId,
        'property_name': propertyName,
        'room_id': roomId,
        'room_name': roomName,
        'budget_byn': budgetByn,
        'shared_fields': sharedFields.map((field) => field.apiValue).toList(),
        'status': status.apiValue,
        'created_at': createdAt.toIso8601String(),
        'is_demo': isDemo,
        'material_proposal': materialProposal.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        masterId,
        title,
        propertyId,
        roomId,
        sharedFields,
        status,
        materialProposal,
      ];
}

class MasterRequestDraft extends Equatable {
  const MasterRequestDraft({
    required this.masterId,
    required this.masterName,
    required this.title,
    required this.description,
    required this.propertyId,
    required this.propertyName,
    required this.sharedFields,
    required this.consentGranted,
    this.roomId,
    this.roomName,
    this.budgetByn,
  });

  final String masterId;
  final String masterName;
  final String title;
  final String description;
  final String propertyId;
  final String propertyName;
  final String? roomId;
  final String? roomName;
  final double? budgetByn;
  final Set<SharedHomeField> sharedFields;
  final bool consentGranted;

  Map<String, dynamic> toApiJson() => {
        'contractor_id': int.tryParse(masterId) ?? masterId,
        'title': title,
        'description': description,
        'property_id': int.tryParse(propertyId) ?? propertyId,
        if (roomId != null) 'room_id': int.tryParse(roomId!) ?? roomId,
        if (budgetByn != null) 'budget_byn': budgetByn,
        'shared_fields': sharedFields.map((field) => field.apiValue).toList(),
        'consent_granted': consentGranted,
      };

  @override
  List<Object?> get props => [
        masterId,
        title,
        propertyId,
        roomId,
        sharedFields,
        consentGranted,
      ];
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
