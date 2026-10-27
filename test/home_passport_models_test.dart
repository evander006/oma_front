import 'package:flutter_test/flutter_test.dart';
import 'package:oma/shared/models/home_passport.dart';
import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';

void main() {
  test('property keeps dacha, tenure and room material fields', () {
    final property = Property(
      id: '1',
      name: 'Моя дача',
      type: PropertyType.dacha,
      tenure: PropertyTenure.rented,
      rooms: const [
        Room(
          id: '2',
          name: 'Комната',
          kind: 'living',
          wallMaterial: 'кирпич',
          floorMaterial: 'доска',
        ),
      ],
    );

    final restored = Property.fromJson(property.toJson());

    expect(restored.type, PropertyType.dacha);
    expect(restored.tenure, PropertyTenure.rented);
    expect(restored.rooms.single.wallMaterial, 'кирпич');
  });

  test('equipment maps technical snapshot and installer link', () {
    final item = HomeEquipment.fromJson({
      'id': 7,
      'property_id': 1,
      'room_id': 2,
      'name': 'Смеситель',
      'specifications': {'Материал': 'латунь'},
      'contractor_name': 'Демо-мастер',
      'installed_at': '2026-10-27T10:00:00',
      'is_demonstration': true,
    });

    expect(item.specifications['Материал'], 'латунь');
    expect(item.contractorName, 'Демо-мастер');
    expect(item.installedAt, isNotNull);
    expect(item.isDemonstration, isTrue);
  });
}
