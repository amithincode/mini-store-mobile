| Screen 1 | Screen 2 | Screen 3 | Screen 4 | Screen 5 | Screen 6 | Screen 7 | Screen 8 |
|---|---|---|---|---|---|---|---|
| <img src="https://github.com/user-attachments/assets/c7c415ad-7348-4730-9aaf-89a9f81b4cd6" width="120"> | <img src="https://github.com/user-attachments/assets/20de0ada-d5c0-46c1-8ae7-53c19f58b15b" width="120"> | <img src="https://github.com/user-attachments/assets/11e4b9a1-c07d-493c-a416-cb4a5389345c" width="120"> | <img src="https://github.com/user-attachments/assets/60c3647b-4300-48b5-9183-b81c45eccd84" width="120"> | <img src="https://github.com/user-attachments/assets/266855a9-be7c-487d-80cc-3057dfcbe49f" width="120"> | <img src="https://github.com/user-attachments/assets/77660e65-6868-4fb1-84b5-c791e65c308f" width="120"> | <img src="https://github.com/user-attachments/assets/80b2481f-c851-4a03-92e2-3b7fb0d57145" width="120"> | <img src="PASTE_SECOND_NEW_IMAGE_URL_HERE" width="120"> |



# Mini Store 🛍️

A responsive shopping application built with **Flutter** and **DummyJSON API**. Mini Store demonstrates clean architecture, API integration, state management, persistent local storage, authentication, and a complete shopping flow.

The application supports product discovery, search, category browsing, product details, cart management, local checkout, order history, wishlist management, and light/dark themes.

## ✨ Features

### 🔐 Authentication
- Login using the DummyJSON authentication API.
- Field validation and API error handling.
- Persistent login sessions and automatic session restoration.
- Access-token refresh and retry for expired sessions.
- Automatic logout when the session can no longer be renewed.
- Protected routes and confirmation before logout.

### 🛒 Product Catalogue
- Fetch products from the DummyJSON API.
- Paginated product listing with infinite scrolling.
- Debounced product search.
- Browse products by category.
- Pull-to-refresh and retry options.
- Responsive product grid for mobile, tablet, and desktop.
- Loading, empty, offline, and error states.

### 📦 Product Details
- Product images displayed in a swipeable gallery.
- Product information, ratings, reviews, and comments.
- Cache-first loading with background refresh.
- Add products to the cart and manage quantities.
- Navigate to the cart directly from product details.

### 🛍️ Cart and Checkout
- Add, increment, decrement, and remove cart items.
- Persistent cart data using local storage.
- Automatic calculation of quantities and totals.
- Cart item count displayed in navigation.
- Checkout confirmation and processing state.
- Unique order number generation.
- Order-success screen with a summary of the completed purchase.
- Cart cleared after successful checkout.

### ❤️ Wishlist
- Add or remove products from the wishlist.
- Wishlist actions available from product browsing and product details.
- View saved products from the Account section.
- Open wishlist products and add them to the cart.
- Persist wishlist data locally across application restarts.
- Handle empty wishlist and storage errors gracefully.

### 📋 My Orders
- View completed purchases from the Account section.
- Save order details locally after successful checkout.
- Generate a unique order number for each completed purchase.
- Preserve the purchased items, quantities, prices, order date, and total.
- View previous orders after restarting the application.
- Keep order history separate from the active cart.
- Retain local order history when logging out.

**Note:** Checkout, order history, and wishlist storage are local features. The application does not process real payments or submit orders to a backend order-management API.

### 🌙 Theme and Appearance
- Material 3 design system.
- Light mode, dark mode, and system-default appearance.
- Persist the selected theme preference.
- Consistent colours, typography, surfaces, and system-bar styling.

### 📱 Responsive UI
- Responsive layouts for mobile, tablet, and desktop.
- Adaptive product grid columns.
- Reusable UI components and consistent spacing.
- Loading placeholders, empty states, and error feedback.
- Poppins typography and Material 3 styling.

## 🧰 Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI development |
| Dart | Application programming language |
| Cubit / flutter_bloc | State management |
| Clean Architecture | Separation of concerns |
| GetIt | Dependency injection |
| GoRouter | Declarative navigation |
| Dio | HTTP requests and interceptors |
| DummyJSON | Authentication and product data |
| SharedPreferences | Persistent local application data |
| flutter_dotenv | Environment-based API configuration |
| Material 3 | UI components and theming |

## 🏗️ Architecture

The project follows **feature-first Clean Architecture**, separating presentation, domain, and data responsibilities.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── di/
│   ├── router/
│   └── shell/
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── account/
    ├── products/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── categories/
    ├── product_details/
    ├── cart/
    ├── wishlist/
    └── orders/
```

*The tree is a high-level overview. Some features may use a different folder depth depending on their implementation.*

### Architecture principles
- **Presentation:** Screens, reusable widgets, Cubits, and UI states.
- **Domain:** Entities, repository contracts, failures, and use cases.
- **Data:** API data sources, models, repository implementations, and local persistence.
- **Core:** Shared networking, configuration, storage, themes, utilities, and widgets.
- **Dependency injection:** Dependencies are registered centrally and provided to features.
- **State consistency:** UI state changes are handled through Cubit rather than being scattered across widgets.

## 💾 Local Storage

SharedPreferences is used for lightweight persistent application data through the project's storage and repository layers.

| Data | Behaviour |
|---|---|
| Authentication session | Restored on application startup |
| Cart | Saved when cart contents change |
| Wishlist | Saved when products are added or removed |
| My Orders | Updated after successful local checkout |
| Theme preference | Restored on the next launch |
| Product catalogue | Cached for faster loading |
| Categories and product details | Cached for cache-first rendering |

Local storage is separate from the DummyJSON API. Product and authentication data can come from the API, while cart, wishlist, and order history are managed locally.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK **3.41.7** or a compatible version.
- Dart SDK compatible with the installed Flutter version.
- Android Studio or Visual Studio Code.
- Chrome for running the web version.
- Internet access for API requests.

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```env
API_BASE_URL=https://dummyjson.com
API_AUTH_LOGIN_PATH=/auth/login
API_AUTH_REFRESH_PATH=/auth/refresh
API_PRODUCTS_PATH=/products
API_PRODUCTS_SEARCH_PATH=/products/search
API_PRODUCTS_DETAIL_PATH=/products/{id}
API_CATEGORIES_PATH=/products/categories
API_CATEGORY_PRODUCTS_PATH=/products/category/{slug}
```

The application reads its API configuration from this file. Ensure `.env` is included as a Flutter asset in `pubspec.yaml`, as required by the project configuration.

Do not commit private credentials or secrets. Every fresh clone must have its own correctly configured environment file.

### 3. Run the application

Run on Chrome:

```bash
flutter run -d chrome
```

Run on a connected Android device or emulator:

```bash
flutter run
```

### 4. Build a release APK

```bash
flutter build apk --release
```

The generated APK is normally available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 🔑 Demo Login

Use the public DummyJSON demo account for manual testing.

```text
Username: emilys
Password: emilyspass
```

API documentation: [DummyJSON](https://dummyjson.com/docs)

These are public demo credentials, not application-specific credentials.

## 🔄 Application Flow

```text
Splash Screen
     |
     ├── Saved session ──────────> Main Application
     |
     └── No valid session ───────> Login
                                      |
                                      v
                              Main Application
                                      |
                  ┌───────────┬───────┼───────────┐
                  v           v       v           v
                Home      Categories  Cart      Account
                  |           |       |           |
                  └──── Product Details           |
                                                  |
                                        ┌─────────┴─────────┐
                                        v                   v
                                      Wishlist           My Orders
```

The main application provides four navigation tabs: Home, Categories, Cart, and Account. Wishlist and My Orders are accessible through the Account section.

## 🧪 Verification

Run the following commands to check formatting, static analysis, and automated tests:

```bash
dart format lib test
flutter analyze
flutter test
```

Run the application manually to verify:

- Login, session restoration, token refresh, and logout.
- Product search, pagination, categories, and product details.
- Cart persistence, quantity changes, and checkout.
- My Orders history after a successful checkout and application restart.
- Wishlist add/remove operations and persistence.
- Theme selection and persistence.
- Empty, loading, offline, and error states.

## 📌 Scope and Assumptions

- DummyJSON provides authentication and catalogue data.
- Checkout simulates a purchase; it does not process a real payment.
- Completed orders are stored locally rather than sent to an order API.
- Wishlist and cart operations use local persistence.
- Product caching improves loading behaviour when network access is limited.
- Local data is not automatically synchronized across devices.
- The application uses the configured API endpoints and demo account for development.

## 👨‍💻 Project Goal

Mini Store demonstrates practical Flutter development skills through a structured, responsive shopping application, with an emphasis on maintainable architecture, reliable API integration, state management, local persistence, and user experience.
