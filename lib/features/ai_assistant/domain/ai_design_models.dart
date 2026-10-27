import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:oma/shared/models/product.dart';

enum AiDesignSelectionMode { vision, catalogFallback }

class InteriorImageSelection extends Equatable {
  const InteriorImageSelection({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  double get sizeMb => bytes.lengthInBytes / (1024 * 1024);

  @override
  List<Object?> get props => [name, bytes.lengthInBytes, mimeType];
}

class AiDesignCapabilities extends Equatable {
  const AiDesignCapabilities({
    required this.supportsImageInput,
    required this.provider,
    required this.model,
    this.privacyNotice,
  });

  final bool supportsImageInput;
  final String provider;
  final String model;
  final String? privacyNotice;

  @override
  List<Object?> get props => [supportsImageInput, provider, model];
}

class AiDesignSourceResult extends Equatable {
  const AiDesignSourceResult({
    required this.mode,
    required this.products,
    required this.summary,
    required this.notice,
    this.provider,
    this.photoId,
  });

  final AiDesignSelectionMode mode;
  final List<Product> products;
  final String summary;
  final String notice;
  final String? provider;
  final int? photoId;

  @override
  List<Object?> get props => [mode, products, summary, notice, provider, photoId];
}

class DesignBundle extends Equatable {
  const DesignBundle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.selectionNote,
    this.serviceEstimateByn = 0,
    this.serviceLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Product> products;
  final String selectionNote;
  final double serviceEstimateByn;
  final String? serviceLabel;

  double get productsTotal => products.fold<double>(
        0,
        (sum, product) => sum + (product.priceByn ?? 0),
      );

  double get total => productsTotal + serviceEstimateByn;

  @override
  List<Object?> get props => [
        id,
        products,
        serviceEstimateByn,
        selectionNote,
      ];
}

class AiDesignLinkIntent extends Equatable {
  const AiDesignLinkIntent({
    required this.propertyId,
    required this.roomId,
    required this.bundleId,
    required this.productIds,
    required this.mode,
    required this.photoName,
    this.designSessionId,
  });

  final String propertyId;
  final String roomId;
  final String bundleId;
  final List<String> productIds;
  final AiDesignSelectionMode mode;
  final String photoName;
  final int? designSessionId;

  @override
  List<Object?> get props => [
        propertyId,
        roomId,
        bundleId,
        productIds,
        mode,
        photoName,
        designSessionId,
      ];
}
