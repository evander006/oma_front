import 'package:flutter_test/flutter_test.dart';
import 'package:oma/core/data/mappers/property_mapper.dart';
import 'package:oma/shared/models/property.dart';

void main() {
  test('PropertyMapper maps API property and room payloads', () {
    final property = PropertyMapper.propertyFromApi(
      {
        'id': 7,
        'name': 'Квартира на Немиге',
        'address': 'Минск',
        'property_type': 'apartment',
      },
      rooms: [
        PropertyMapper.roomFromApi({
          'id': 3,
          'property_id': 7,
          'name': 'Кухня',
          'room_type': 'kitchen',
          'width_m': '3.2',
          'length_m': '4.1',
        }),
      ],
      selected: true,
      areaSqm: 54,
    );

    expect(property.id, '7');
    expect(property.type, PropertyType.apartment);
    expect(property.rooms.single.kind, 'kitchen');
    expect(property.rooms.single.widthM, 3.2);
    expect(property.selected, isTrue);
  });
}
