import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oma/features/onboarding/domain/onboarding_photo.dart';

void main() {
  test('validates JPG and PNG photo names for onboarding', () {
    final jpg = OnboardingPhoto.fromBytes(
      name: 'kitchen.JPG',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    expect(jpg.name, 'kitchen.JPG');
    expect(jpg.mimeType, 'image/jpeg');
    expect(jpg.bytes.length, 3);

    final png = OnboardingPhoto.fromBytes(
      name: 'room.png',
      bytes: Uint8List.fromList([1]),
    );
    expect(png.mimeType, 'image/png');
  });

  test('rejects unsupported documents and empty images', () {
    expect(
      () => OnboardingPhoto.fromBytes(
        name: 'floorplan.pdf',
        bytes: Uint8List.fromList([1]),
      ),
      throwsFormatException,
    );
    expect(
      () => OnboardingPhoto.fromBytes(
        name: 'empty.png',
        bytes: Uint8List(0),
      ),
      throwsFormatException,
    );
  });

  test('rejects oversized images', () {
    expect(
      () => OnboardingPhoto.fromBytes(
        name: 'too-big.png',
        bytes: Uint8List(OnboardingPhoto.maxBytes + 1),
      ),
      throwsFormatException,
    );
  });
}
