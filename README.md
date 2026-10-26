# ОМА. Дом — Flutter MVP

Кликабельный демо-MVP. UI по Figma + бэкенд [oma_be](https://github.com/evander006/oma_be).

## Стек клиента

- Cubit / `flutter_bloc`
- Dio → REST `/api/v1`
- Repositories (remote/mock) → Cubit → UI

## API

По умолчанию приложение ходит на:

**https://oma-be-85l2.onrender.com**

Swagger: https://oma-be-85l2.onrender.com/docs

Константа: `ApiConfig.defaultBaseUrl` в `lib/core/network/api_config.dart`.

Переопределение:

```bash
flutter run --dart-define=API_BASE_URL=https://other-host.example
```

Офлайн-mock:

```bash
flutter run --dart-define=USE_MOCK_API=true
```

## Запуск

```bash
flutter pub get
flutter run
```

## Что ходит в API

- Каталог / категории / карточка (+ `/api/v1/assets/...`)
- Корзина, избранное
- ИИ-чат `POST /api/v1/ai/chat`
- Услуги установки

«Мой дом» пока локально (SharedPreferences).

## Тесты

```bash
flutter test
flutter analyze
```
