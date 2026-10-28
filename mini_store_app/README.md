# Mini Store

A responsive Flutter storefront for mobile, tablet, and desktop. The app starts
on a login screen and opens an empty store shell until the product catalogue is
connected in a later phase.

## Requirements

- Flutter 3.41.7 (Dart 3.11.5) or a compatible SDK
- Chrome for the web workflow

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

Create a `.env` file in the project root before the first run:

```env
API_BASE_URL=https://dummyjson.com
```

`.env` is declared as a Flutter asset because `flutter_dotenv` reads it from the
bundle, and it is ignored by Git. Every machine or fresh clone must create its
own `.env`. When the file is missing or invalid, the app shows a startup error
screen instead of silently falling back.

`API_BASE_URL` is validated at startup and configures the Dio client for a later
phase. No network request is made yet.

## Flow

1. App launches on `/login`.
2. Email and password are validated locally. Any valid email and a password of
   at least 6 characters are accepted.
3. The store opens at `/` with an empty catalogue.
4. Sessions are in-memory only, so every app launch starts at login again.

The route guard redirects signed-out users to `/login` and signed-in users away
from it. No real authentication, token, or account is implemented.

## Features

- Login-first flow with local validation and password visibility toggle
- Responsive store shell with a clear empty-catalogue state
- Search, category chips, promo banner, and 2/3/4/5-column grid ready for data
- Shared `AppScaffold`, `AppAppBar`, brand mark, and state views
- Material 3 theme with bundled Poppins fonts
- DevicePreview and a custom Chrome loading screen

## Architecture

```text
lib/
├── main.dart                     # dotenv, config, DI, startup errors
├── app/
│   ├── app.dart                  # MaterialApp.router and DevicePreview
│   ├── startup_error_app.dart
│   ├── di/injector.dart
│   └── router/app_router.dart    # routes and login guard
├── core/
│   ├── config/                   # Environment validation
│   ├── network/                  # Transport-only Dio client
│   ├── storage/                  # shared_preferences wrapper
│   ├── theme/                    # Colors, spacing, typography, theme
│   ├── utils/                    # Responsive metrics and formatters
│   └── widgets/                  # Scaffold, app bar, brand, state views
└── features/
    ├── auth/presentation/        # AuthSession and LoginScreen
    ├── products/                 # Store cubit, screen, and widgets
    ├── categories/presentation/  # Category chips
    └── cart/presentation/        # Presentational cart button
```

Widgets receive dependencies through constructors. The router is given a
`StoreCubit Function()` factory, and the auth session is registered in DI.

## Responsive behaviour

| Width      | Device  | Page gutter | Product columns |
| ---------- | ------- | ----------- | --------------- |
| `< 600`    | Mobile  | 16          | 2               |
| `600–899`  | Tablet  | 24          | 3               |
| `900–1099` | Desktop | 32          | 4               |
| `≥ 1100`   | Desktop | 32          | 5               |

Content is capped at 1200 px and centred on large screens. Banner and card
heights grow with the text scaler for accessibility.

## Device preview

`DevicePreview` is enabled in debug and profile builds and disabled in release.
The project pins `device_preview: 1.3.1` because 3.x requires Flutter ≥ 3.47.0.

## Verification

```bash
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

The test suite covers configuration, Dio setup, storage, formatters, responsive
metrics, shared widgets, auth session and login validation, route gating, the
store cubit, the store screen across four widths, DI, and routing.

## Current scope

Implemented:

- Project setup, `.env` configuration, and startup failure UI
- Login-first gate with in-memory session
- Empty store shell and reusable responsive UI
- DevicePreview and the Chrome loading experience

Deliberately excluded:

- Real authentication, accounts, and tokens
- Product data, repositories, and API calls
- Cart logic, checkout, and product details
