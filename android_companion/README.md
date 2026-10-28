# OMA Companion — Android overlay demo (hackathon)

A separate, unofficial Android APK. **It does not patch, hook, inspect, or repackage the official OMA application.** Instead, a user-controlled `TYPE_APPLICATION_OVERLAY` bubble and a limited-width panel appear above OMA. The panel opens an interactive companion app for a customer and a demo contractor.

## Implemented in this repository

- Kotlin app for Android 8.0+ (minSdk 26; targetSdk 35).
- Opt-in overlay permission screen, draggable floating bubble, dismissible card, persistent notification, stop control.
- Explicit `specialUse` foreground service declaration for Android 14+ (sideload/hackathon use only).
- Detect/open the official OMA Android package, `ru.oma.android` (installed separately via official app store).
- Point both phones to the same HTTPS FastAPI demo instance, configurable in the app.
- Customer flow: fetch demo properties, open 3D scene / PDF passport, list demo contractors, explicitly consent and submit a job request, refresh work order statuses, accept a material proposal into the demo shopping cart.
- Contractor flow: configure demo contractor ID, poll for work orders, accept a request and propose the first available demo product.
- Network requests occur off the main thread. Server errors are shown; no synthetic success messages.

## Prerequisites

- Android SDK 35, Gradle 8.9, JDK 17, Android phone with original OMA installed.
- FastAPI backend running **the branch** `evander006/oma_be:codex/digital-home-ecosystem`. The original `main` or old Render deployment may **not** expose these endpoints.
- For live two-phone demonstration: one reachable HTTPS endpoint and its persistent database.
- This is a DEMO backend: `get_current_user` returns one common user and demo contractor IDs identify the contractor, **not secure authentication**. Never input genuine customer information.

## Build

From this `android_companion` directory:

```bash
gradle :app:assembleDebug
# Debug APK: app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Or build via included GitHub Actions workflow (copy `.github/workflows/companion-android.yml` to the **root** of the `oma_front` repository and place this directory at `oma_front/android_companion`). The workflow uploads the debug APK artifact.

## Setup phone 1 (customer)

1. Install original OMA from its official source and the debug APK of OMA Companion. Open Companion.
2. Enter the HTTPS backend address and tap **Сохранить адрес и проверить**. Choose **1 · Клиент**.
3. Tap **Включить плавающую панель**, approve **Display over other apps** in Android settings, return to Companion and tap again.
4. Tap **Открыть настоящее приложение ОМА**. The floating blue house icon is independent of the original app. Tap it, then **Открыть сервисы клиента**.
5. Select a demo contractor, check consent, and send a demo work order. Press **Обновить статусы** to see updates.

## Setup phone 2 (contractor)

1. Install the same Companion APK. Use the exact same HTTPS backend URL.
2. Choose **2 · Мастер**. Enter the selected contractor's numeric ID (displayed after selecting them on phone 1), tap **Подключить демо-мастера**.
3. Wait up to 10 seconds or tap **Обновить заявки**. Accept the request.
4. Tap **Предложить первый товар из демо-каталога** (the request is written to the shared Backend).
5. On phone 1, tap **Обновить статусы** and **Принять предложение**. The original OMA cart does NOT change — this updates the demo backend's cart.

## Backend prep (from the existing `oma_be` checkout)

```bash
# checkout codex/digital-home-ecosystem, create virtualenv, install dependencies
cd backend
python -m alembic upgrade head
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Serve via HTTPS reverse proxy or deploy that branch. Both phones must be able to connect to the same service. `https://oma-be-85l2.onrender.com` is just the existing default and may be on the wrong branch.

Before showing the demo, check `GET /api/v1/contractors`, `/api/v1/properties`, `/api/v1/work-orders/mine` and `GET /api/v1/products?page_size=1` in `/docs`. Start with a seeded demo contractor and product catalog. To see a 3D apartment, add a demo property using your existing Flutter demo beforehand. The original mobile OMA **is not integrated with these API calls**; the integration is strictly through the separate overlay app.

## Security and platform caveats

- Uses Android `SYSTEM_ALERT_WINDOW` with explicit user grant. No Accessibility Service, no rooting, no APK repackaging, no reading third-party screen contents.
- Android versions/OEMs may block overlay display in sensitive screens. The overlay is not shown automatically on such screens; avoid payments and OS permission prompts.
- Foreground service starts only from visible activity action. A persistent notification gives access to stop the service, with a separate stop button in the app. Android may stop the service under device policies.
- No secure auth, role enforcement, official checkout, official item-to-cart transfer, order linkage, push notifications or verified official product inventory. For a real product: implement authentication, isolation of tenants/users, privacy, refresh policy, stronger audit logs, and an OMA-provided API.
- For Play Store distribution, `specialUse` foreground-service use must satisfy Google Play's declaration/review rules. This artifact is intended for local installation for a hackathon.

## Verification status

Source structure, manifest validity and API-path references can be checked without Android SDK. This environment has **no Android SDK or Gradle and blocks external downloads**, so `assembleDebug` and on-device overlay tests could not be run here. Use the CI workflow or an Android development machine to build and verify the APK before the event. Do not claim a compiled, tested APK exists until the build succeeds.
