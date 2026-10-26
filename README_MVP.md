# ОМА. Дом — Flutter MVP

Кликабельный демо-MVP по [Figma Frame 1](https://www.figma.com/design/kcNYUsu1iX7ltN61eYWs7E) и `.cursor/OMA_Dom_Flutter_Cursor_Spec.md`.

## Запуск

```bash
flutter pub get
flutter run
```

## Что реализовано

- 5 вкладок: Главная, Каталог, Корзина, Избранное, Профиль
- Онбординг объекта (квартира/дом) с сохранением в `shared_preferences`
- Каталог, поиск, карточка товара + блок «Нужна установка?»
- Корзина / избранное (Cubit), демо-заказы
- Мой дом → комнаты → ИИ-mock, предложения, 3D-placeholder
- SafeArea под вырез экрана

## Mock-данные

`lib/core/data/mock_catalog.dart` — категории и товары с `img_icon`.  
Цены демонстрационные (BYN), не актуальный каталог OMA.

## Куда потом подключить API / 3D

- Репозитории: `lib/core/repositories/`
- 3D-виджет: `lib/features/room_3d/presentation/room_3d_screen.dart` (`Room3dViewer`)
- Поля товара: `model3dAsset` / `model3dUrl` в `Product`
