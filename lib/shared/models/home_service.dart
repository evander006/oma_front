import 'package:equatable/equatable.dart';

class HomeService extends Equatable {
  const HomeService({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.priceFromByn,
    this.unitHint,
    this.relatedCategoryIds = const [],
  });

  final String id;
  final String title;
  final String category;
  final String? description;
  final double? priceFromByn;
  final String? unitHint;
  final List<String> relatedCategoryIds;

  String get priceLabel {
    if (priceFromByn == null) return 'Стоимость уточняется';
    return 'от ${priceFromByn!.toStringAsFixed(0)} BYN';
  }

  bool get hasVerifiedPrice => priceFromByn != null;

  @override
  List<Object?> get props => [id, title, category, priceFromByn];
}

class ServiceBookingDraft extends Equatable {
  const ServiceBookingDraft({
    required this.serviceId,
    this.roomLabel,
    this.volumeHint,
    this.photoAssets = const [],
    this.address,
    this.preferredDate,
    this.contactName,
    this.contactPhone,
    this.notes,
  });

  final String serviceId;
  final String? roomLabel;
  final String? volumeHint;
  final List<String> photoAssets;
  final String? address;
  final String? preferredDate;
  final String? contactName;
  final String? contactPhone;
  final String? notes;

  ServiceBookingDraft copyWith({
    String? roomLabel,
    String? volumeHint,
    List<String>? photoAssets,
    String? address,
    String? preferredDate,
    String? contactName,
    String? contactPhone,
    String? notes,
  }) {
    return ServiceBookingDraft(
      serviceId: serviceId,
      roomLabel: roomLabel ?? this.roomLabel,
      volumeHint: volumeHint ?? this.volumeHint,
      photoAssets: photoAssets ?? this.photoAssets,
      address: address ?? this.address,
      preferredDate: preferredDate ?? this.preferredDate,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [serviceId, roomLabel, address, preferredDate];
}
