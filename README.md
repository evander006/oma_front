# ОМА. Дом — Flutter

Домашняя платформа ремонта, услуг, каталога OMA и ИИ-дизайна.

## Стек

- Cubit / `flutter_bloc`
- Dio → REST `/api/v1` ([oma_be](https://github.com/evander006/oma_be))
- go_router (StatefulShell + push-маршруты)
- SharedPreferences для объектов, заявок на ремонт, заказов

## Навигация

1. **Главная** — ремонт под ключ, услуги, ИИ, лояльность, каталог  
2. **Каталог** — поиск, категории, карточки, 3D-метаданные  
3. **Услуги** — отдельные работы, замерщик, мастер-заявка  
4. **Мои проекты** — черновики/заявки + вход в «Мой дом»  
5. **Профиль** — объекты, заказы, лояльность, избранное  

Корзина — из шапки (счётчик), не отдельная вкладка.

## API

По умолчанию: **https://oma-be-85l2.onrender.com**

```bash
flutter run --dart-define=API_BASE_URL=https://other-host.example
flutter run --dart-define=USE_MOCK_API=true
```

Подключено: каталог, категории, карточка (+ assets/3D meta), корзина/избранное (remote), ИИ-чат, услуги установки.

Локально (пока нет endpoint): заявки «ремонт под ключ», booking отдельных услуг, лояльность (демо), объекты «Мой дом».

## Запуск

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```
