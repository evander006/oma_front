import 'package:equatable/equatable.dart';

class InstallationOption extends Equatable {
  const InstallationOption({
    required this.id,
    required this.title,
    required this.priceFromByn,
    this.subtitle,
  });

  final String id;
  final String title;
  final double priceFromByn;
  final String? subtitle;

  String get priceLabel => 'от ${priceFromByn.toStringAsFixed(0)} р.';

  @override
  List<Object?> get props => [id, title, priceFromByn];
}
