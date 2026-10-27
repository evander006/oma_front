import 'package:oma/shared/models/renovation_request.dart';

/// Maps between Flutter [RenovationRequest] and oma_be renovation project JSON.
abstract final class RenovationMapper {
  static RenovationRequest fromProjectJson(Map<String, dynamic> json) {
    final status = _statusFromApi('${json['status'] ?? 'draft'}');
    final scope = _scopeFromApi(json['scope']?.toString());
    final building = _kindFromApi(json['building_type']?.toString());
    final work = (json['work_categories'] as List<dynamic>? ?? const [])
        .map((e) => '$e')
        .toSet();
    final budgetMin = _num(json['budget_min']);
    final budgetMax = _num(json['budget_max']);
    String? budgetRange;
    if (budgetMin != null || budgetMax != null) {
      budgetRange =
          '${budgetMin?.toStringAsFixed(0) ?? '—'}–${budgetMax?.toStringAsFixed(0) ?? '—'} BYN';
    }

    return RenovationRequest(
      id: '${json['id']}',
      name: json['name']?.toString(),
      propertyKind: building,
      scope: scope,
      areaSqm: _num(json['area_m2']),
      roomsCount: (json['room_count'] as num?)?.toInt(),
      housingAge: json['renovation_type']?.toString(),
      condition: json['condition']?.toString(),
      workCategories: work,
      selectedRooms: work, // backend stores work cats; rooms kept in payload
      style: json['style_preferences']?.toString(),
      styleNotes: json['customer_notes']?.toString(),
      budgetRange: budgetRange,
      timeline: json['timeline_notes']?.toString(),
      materialTier: _tierFromApi(json['materials_preferences']?.toString()),
      address: json['address']?.toString(),
      contactName: json['contact_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      status: status,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
      consentPersonalData: true,
    );
  }

  static Map<String, dynamic> toProjectCreate(RenovationRequest r) {
    final budget = _parseBudget(r.budgetRange);
    return {
      'name': r.displayName,
      'renovation_type': r.housingAge,
      'scope': _scopeToApi(r.scope),
      'area_m2': r.areaSqm,
      'room_count': r.roomsCount,
      'building_type': _kindToApi(r.propertyKind),
      'condition': r.condition,
      'work_categories': [
        ...r.workCategories,
        if (r.selectedRooms.isNotEmpty) ...r.selectedRooms.map((e) => 'room:$e'),
      ],
      'budget_min': budget.$1,
      'budget_max': budget.$2,
      'timeline_notes': [
        if (r.startDateIso != null) 'Старт: ${r.startDateIso}',
        if (r.timeline != null) 'Срок: ${r.timeline}',
        if (r.flexibleTimeline) 'Гибкий график',
      ].where((e) => e.isNotEmpty).join('; '),
      'style_preferences': r.style,
      'materials_preferences': r.materialTier?.name,
      'customer_notes': [
        if (r.styleNotes != null && r.styleNotes!.isNotEmpty) r.styleNotes,
        if (r.occupancy != null) 'Заселённость: ${r.occupancy}',
        if (r.photoAssets.isNotEmpty) 'Фото (локальные): ${r.photoAssets.length}',
        if (r.floorPlanAsset != null) 'План: ${r.floorPlanAsset}',
        'oma_supplies=${r.omaSuppliesMaterials}',
        'install=${r.needInstallation}',
        'waste=${r.needWasteRemoval}',
        'furniture=${r.needFurniture}',
        'lighting=${r.needLighting}',
        if (r.contactMethod != null) 'Связь: ${r.contactMethod}',
      ].whereType<String>().join('\n'),
      'contact_name': r.contactName,
      'contact_phone': r.contactPhone,
      'address': r.address,
      'work_items': [
        for (final w in r.workCategories) {'name': w},
      ],
    };
  }

  static Map<String, dynamic> toProjectPatch(RenovationRequest r) {
    final budget = _parseBudget(r.budgetRange);
    return {
      'name': r.displayName,
      'budget_min': budget.$1,
      'budget_max': budget.$2,
      'timeline_notes': r.timeline,
      'style_preferences': r.style,
      'materials_preferences': r.materialTier?.name,
      'customer_notes': r.styleNotes,
      'contact_name': r.contactName,
      'contact_phone': r.contactPhone,
      'address': r.address,
    };
  }

  static Map<String, dynamic> toRequestPayload(RenovationRequest r) {
    return {
      'wizard': r.toJson(),
      'label': 'turnkey_wizard',
    };
  }

  static String statusToApi(RenovationProjectStatus s) => switch (s) {
        RenovationProjectStatus.draft => 'draft',
        RenovationProjectStatus.submitted => 'submitted',
        RenovationProjectStatus.awaitingConsultation => 'awaiting_consultation',
        RenovationProjectStatus.estimatePreparing => 'estimate_preparation',
        RenovationProjectStatus.estimateApproved => 'estimate_confirmed',
        RenovationProjectStatus.scheduled => 'scheduled',
        RenovationProjectStatus.inProgress => 'in_progress',
        RenovationProjectStatus.completed => 'completed',
      };

  static RenovationProjectStatus _statusFromApi(String raw) => switch (raw) {
        'submitted' => RenovationProjectStatus.submitted,
        'awaiting_consultation' ||
        'inspection_requested' =>
          RenovationProjectStatus.awaitingConsultation,
        'estimate_preparation' => RenovationProjectStatus.estimatePreparing,
        'estimate_confirmed' => RenovationProjectStatus.estimateApproved,
        'scheduled' => RenovationProjectStatus.scheduled,
        'in_progress' => RenovationProjectStatus.inProgress,
        'completed' => RenovationProjectStatus.completed,
        'cancelled' => RenovationProjectStatus.draft,
        _ => RenovationProjectStatus.draft,
      };

  static RenovationScope? _scopeFromApi(String? raw) => switch (raw) {
        'turnkey' => RenovationScope.turnkey,
        'cosmetic' => RenovationScope.cosmetic,
        'major' => RenovationScope.major,
        'new_finish' || 'newFinish' => RenovationScope.newFinish,
        'consultation' => RenovationScope.consultation,
        _ => null,
      };

  static String _scopeToApi(RenovationScope? s) => switch (s) {
        RenovationScope.turnkey => 'turnkey',
        RenovationScope.cosmetic => 'cosmetic',
        RenovationScope.major => 'major',
        RenovationScope.newFinish => 'new_finish',
        RenovationScope.consultation => 'consultation',
        null => 'turnkey',
      };

  static RenovationPropertyKind? _kindFromApi(String? raw) => switch (raw) {
        'apartment' || 'квартира' => RenovationPropertyKind.apartment,
        'house' || 'дом' => RenovationPropertyKind.house,
        'other' => RenovationPropertyKind.other,
        _ => null,
      };

  static String? _kindToApi(RenovationPropertyKind? k) => switch (k) {
        RenovationPropertyKind.apartment => 'apartment',
        RenovationPropertyKind.house => 'house',
        RenovationPropertyKind.other => 'other',
        null => null,
      };

  static MaterialTier? _tierFromApi(String? raw) {
    if (raw == null) return null;
    try {
      return MaterialTier.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  static (double?, double?) _parseBudget(String? range) {
    if (range == null) return (null, null);
    final digits = RegExp(r'(\d[\d\s]*)')
        .allMatches(range)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(' ', '')))
        .whereType<double>()
        .toList();
    if (digits.isEmpty) return (null, null);
    if (digits.length == 1) {
      if (range.contains('от')) return (digits.first, null);
      if (range.contains('до')) return (null, digits.first);
      return (digits.first, digits.first);
    }
    return (digits[0], digits[1]);
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
