import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// A photo selected during onboarding. Kept in memory until a property and
/// a room exist, then sent to the room-photo API (not stored as base64).
class OnboardingPhoto {
  const OnboardingPhoto({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  static const maxBytes = 8 * 1024 * 1024;

  final String name;
  final String mimeType;
  final Uint8List bytes;

  /// Validate filename and size without relying on platform-specific XFile
  /// metadata. This is also used by unit tests with in-memory image bytes.
  static OnboardingPhoto fromBytes({
    required String name,
    required Uint8List bytes,
  }) {
    final filename = name.trim();
    final ext = filename.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mime == null) {
      throw FormatException('Файл $filename: поддерживаются JPG, PNG и WEBP.');
    }
    if (bytes.isEmpty) {
      throw FormatException('Файл $filename пустой.');
    }
    if (bytes.length > maxBytes) {
      throw FormatException('Файл $filename больше 8 МБ.');
    }
    return OnboardingPhoto(name: filename, mimeType: mime, bytes: bytes);
  }

  static Future<OnboardingPhoto> fromFile(XFile file) async {
    // Picked files normally have a name. On some native platforms an XFile
    // constructed from raw data does not; use a filesystem basename if present.
    final filename = file.name.trim().isNotEmpty
        ? file.name.trim()
        : file.path.split(RegExp(r'[/\\]')).last;
    if (await file.length() > maxBytes) {
      throw FormatException('Файл $filename больше 8 МБ.');
    }
    return fromBytes(name: filename, bytes: await file.readAsBytes());
  }
}
