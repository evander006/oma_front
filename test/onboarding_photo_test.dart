import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oma/features/onboarding/domain/onboarding_photo.dart';

void main() {
  test('validates JPG and PNG photo names for onboarding', () async {
    final jpg = await OnboardingPhoto.fromFile(
      XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'kitchen.JPG'),
    );
    expect(jpg.name, 'kitchen.JPG');
    expect(jpg.mimeType, 'image/jpeg');
    expect(jpg.bytes.length, 3);

    final png = await OnboardingPhoto.fromFile(
      XFile.fromData(Uint8List.fromList([1]), name: 'room.png'),
    );
    expect(png.mimeType, 'image/png');
  });

  test('rejects unsupported documents and empty images', () async {
    await expectLater(
      OnboardingPhoto.fromFile(
        XFile.fromData(Uint8List.fromList([1]), name: 'floorplan.pdf'),
      ),
      throwsFormatException,
    );
    await expectLater(
      OnboardingPhoto.fromFile(
        XFile.fromData(Uint8List(0), name: 'empty.png'),
      ),
      throwsFormatException,
    );
  });
}
