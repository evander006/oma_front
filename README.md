# ОМА. Дом — Flutter

Клиент к backend [oma_be](https://github.com/evander006/oma_be).

## API

По умолчанию приложение ходит на hosted instance:

**https://oma-be-85l2.onrender.com**

Swagger: https://oma-be-85l2.onrender.com/docs

```bash
# другой хост (локальный uvicorn / LAN)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# офлайн mock без сети
flutter run --dart-define=USE_MOCK_API=true
```

Конфиг: `lib/core/network/api_config.dart`.

## Что подключено к oma_be

| Область | Endpoint |
|---------|----------|
| Каталог / категории / карточка / 3D meta | `/products`, `/categories`, assets |
| Корзина / избранное / заказы | `/cart`, `/favorites`, `/orders` |
| Услуги установки (товар) | `/installation-services` |
| ИИ-чат и рекомендации | `/ai/chat`, `/ai/recommendations` |
| Услуги ремонта | `/renovation/services` |
| Заявки на установку | `/renovation/installation-requests` |
| Проекты ремонта под ключ | `/renovation/projects`, `/renovation/requests` |
| Лояльность | `/loyalty/account`, `/rewards`, `/transactions` |
| Профиль | `/me` |

Черновики мастера «Ремонт под ключ» хранятся локально до «Отправить заявку», затем создаются на backend.

«Мой дом»: объекты и комнаты через `/properties` и `/rooms`; фото — `/rooms/{id}/photos`; размещения товаров — `/rooms/{id}/placements`. Локальный overlay хранит выбор объекта, area/budget и список items.

## Запуск

```bash
flutter pub get
flutter run
flutter test
flutter analyze --no-fatal-infos
```
