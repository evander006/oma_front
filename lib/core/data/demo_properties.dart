import 'package:oma/shared/models/property.dart';
import 'package:oma/shared/models/room.dart';
import 'package:oma/shared/models/room_item.dart';

/// Seed data matching Dom screenshots for empty local storage.
List<Property> buildDemoProperties() {
  const kitchenId = 'room-kitchen';
  const livingId = 'room-living';
  const bedroomId = 'room-bedroom';
  const bathId = 'room-bath';
  const entryId = 'room-entry';
  const hallId = 'room-hall';

  return [
    Property(
      id: 'prop-apartment',
      name: 'Моя квартира',
      type: PropertyType.apartment,
      address: 'Минск, ул. Лесная, 12, кв. 48',
      areaSqm: 56,
      livingRooms: 2,
      budgetByn: 1000,
      goal: 'Обновить кухню',
      isDraft: false,
      selected: true,
      rooms: [
        const Room(id: livingId, name: 'Гостиная', kind: 'living'),
        const Room(id: bedroomId, name: 'Спальня', kind: 'bedroom'),
        Room(
          id: kitchenId,
          name: 'Кухня',
          kind: 'kitchen',
          photoPaths: const ['assets/images/kitchen.png'],
          items: const [
            RoomItem(
              id: 'item-faucet',
              productId: 'p1',
              name:
                  'Смеситель кухонный с гибким изливом (графит+графит) Ledeme арт. L4399U-12',
              qty: 1,
              note: 'purchased',
            ),
          ],
        ),
        const Room(id: bathId, name: 'Санузел', kind: 'bathroom'),
        const Room(id: entryId, name: 'Прихожая', kind: 'entry'),
        const Room(id: hallId, name: 'Коридор', kind: 'hallway'),
      ],
    ),
    const Property(
      id: 'prop-draft-house',
      name: 'Дом за городом',
      type: PropertyType.house,
      isDraft: true,
      selected: false,
      rooms: [],
    ),
  ];
}
