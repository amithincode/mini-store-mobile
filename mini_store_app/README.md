# Mini Store

A responsive Flutter storefront for mobile, tablet, and desktop. The app starts
on a real login screen, restores saved sessions, opens a protected four-tab
shell, and loads the DummyJSON product catalogue with search, pagination,
cache-first rendering, and offline-aware errors.

## Requirements

- Flutter 3.41.7 (Dart 3.11.5) or a compatible SDK
- Chrome for the web workflow
- A DummyJSON account for manual testing

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

`API_BASE_URL` is validated at startup and configures login, refresh, and
protected API requests.

## Manual test account

Authentication uses the DummyJSON demo API. No credentials are hardcoded in the
app; use this public demo account when testing manually:

```text
Username: emilys
Password: emilyspass
```

Invalid credentials return `Invalid credentials`, which is displayed in the
login form.

## Flow

1. The app starts on `/splash` while the saved session is read from storage.
2. A valid saved session opens `/` without calling the login endpoint again.
3. With no session, or with corrupt/incomplete stored data, the app opens
   `/login`.
4. Username and password are validated locally. Empty fields show inline errors,
   and the errors clear as soon as the field is edited. The submit button is
   disabled while a request is in flight.
5. `POST /auth/login` returns the access token, refresh token, and profile. The
   session is saved only after a successful response.
6. Protected requests carry `Authorization: Bearer <latest access token>`.
7. A `401` triggers `POST /auth/refresh` with `{refreshToken, expiresInMins: 30}`.
   The renewed tokens are persisted before the original request is retried once.
8. Simultaneous `401`s share a single refresh request.
9. If refresh is rejected or no usable refresh token remains, the session is
   cleared, the app returns to `/login` with a session-expired message, and the
   navigation stack is reset.
10. Signing out from the Account tab asks for confirmation. Cancelling keeps the
    session; confirming clears it and returns to `/login` with no protected
    route left behind.

The router follows the authentication cubit. Network code never navigates with a
`BuildContext`; expiry is published as an event and handled by the auth layer.

## Session persistence

The session is stored as JSON under `mini_store.auth.session.v1`:

- access token and refresh token
- user id and username
- optional email, first name, last name, gender, and image

Passwords are never persisted or logged. A corrupt, incomplete, or unknown
schema version removes that key and is treated as signed out. Because the access
token may have expired between launches, restoring a session does not contact the
API; the first protected request refreshes it if needed.

## Product catalogue

Home uses the protected Dio client for both endpoints:

```text
GET /products?limit=10&skip=<loaded>
GET /products/search?q=<query>&limit=10&skip=<loaded>
```

- Page size is 10. The next `skip` is the number of loaded products; pages are
  appended, deduplicated by product id, and stop once the API `total` is reached.
- Infinite scroll requests the next page near the bottom. Wide layouts also fill
  the first viewport automatically when ten products do not cover the screen.
- Pull-to-refresh resets to page zero and replaces the list. Web and desktop also
  expose a refresh action in the app bar.
- Next-page and refresh failures keep the visible products on screen. There is no
  full-screen loader during either operation.
- Search is debounced by 500 ms. Pressing Enter submits immediately, the clear
  button resets immediately, and changing the term resets pagination. Responses
  for an older term are ignored.
- Empty searches show `No products found` with a clear action, which is distinct
  from an empty catalogue.
- Session failures (`401`/`403`) are never reported as offline.

### Product cache

Products are cached in `SharedPreferences`, separately per normalized query
(trimmed, lower-cased, whitespace collapsed). Each product is stored under its
own key, so no single value grows with the catalogue:

```text
mini_store.products.v1.schema              # cache schema, currently 1
mini_store.products.v1.index               # most recently written queries
mini_store.products.v1.meta.<query>        # total, limit, updatedAt, ordered ids
mini_store.products.v1.item.<productId>    # one JSON product
```

The normal catalogue uses `__all__` as its meta key. Up to ten query caches are
kept; evicting one removes its metadata and any product entries no longer
referenced by another query. Cached products render immediately and are refreshed
in the background without a hard TTL. On a failed refresh the cache is preserved
and an inline notice explains what is being shown. The product cache survives
logout; only the authentication session is cleared.

### Error states

| Condition | What Home shows |
| --------- | --------------- |
| Offline, no cache | Offline state with Retry |
| Offline, cache available | Cached grid plus an offline notice |
| Refresh failed, cache available | Cached grid plus a refresh-failed notice and Retry |
| Search refresh failed, cache available | Cached search results plus a search notice |
| Empty search | `No products found` and Clear search |
| Next page failed | Inline footer error with Try again; existing products stay |
| Expired session | Session message, no offline copy |

## Debug API logging

Debug builds print every API call as a numbered, boxed JSON block:

```text
[API] Network logging active. Each request, response, and error prints as a formatted JSON block.
[AUTH] Login request for @emilys.
┌─ API REQUEST #1 ──────────────────────────────────────────────────────
│ POST https://dummyjson.com/auth/login
│
│ Request body
│ {
│   "username": "emilys",
│   "password": "[REDACTED]"
│ }
└────────────────────────────────────────────────────────────────────────
┌─ API ERROR #1 · 400 ──────────────────────────────────────────────────
│ POST https://dummyjson.com/auth/login
│ Time: 118 ms
│
│ Error body
│ {
│   "message": "Invalid credentials"
│ }
└────────────────────────────────────────────────────────────────────────
[AUTH] Login failed: Invalid credentials
```

A successful call shows the response body instead:

```text
┌─ API REQUEST #2 ──────────────────────────────────────────────────────
│ GET https://dummyjson.com/products/category-list
└────────────────────────────────────────────────────────────────────────
┌─ API RESPONSE #2 · 200 ───────────────────────────────────────────────
│ GET https://dummyjson.com/products/category-list
│ Time: 142 ms
│
│ Response body
│ [
│   "beauty",
│   "fragrances",
│   "furniture"
│ ]
└────────────────────────────────────────────────────────────────────────
```

Requests and responses share a number, which continues across the
authentication and protected clients so concurrent calls stay distinguishable.
Bodies are pretty-printed with two-space indentation.

Logging is disabled in release builds. Request and response headers are never
printed, so `Authorization` stays out of the log. Body fields named `password`,
`accessToken`, `refreshToken`, `token`, `access_token`, `refresh_token`, and
`authorization` are replaced with `[REDACTED]`. Bodies over 8,000 characters are
omitted with a length notice instead of being cut into invalid JSON.

Authentication actions are logged separately because logout is local-only:

```text
[AUTH] Restoring saved session.
[AUTH] No saved session; showing login.
[AUTH] Login request for @emilys.
[AUTH] Login succeeded for @emilys.
[AUTH] Logout requested.
[AUTH] Signed out.
```

If these lines do not appear, make sure the app was started with `flutter run`
in debug mode and fully restarted after code changes. A hot reload does not
rebuild the dependency singletons that hold the interceptor; use `R` (hot
restart) or stop and relaunch. Browser console output is also visible in
Chrome DevTools, but `flutter run` forwards it to the terminal.

## Features

- Real DummyJSON login with per-field validation, API error messages, password
  visibility, and duplicate-submit protection
- Persistent sessions with splash restore
- Bearer-token interceptor with single-flight refresh, persist-before-retry, and
  retry-once behaviour
- Automatic logout and login redirect when a session can no longer be renewed
- Protected four-tab shell: Home, Categories, Cart, and Account
- Account profile from saved data with graceful placeholders, plus confirmed
  logout
- Product catalogue from `/products` with paginated infinite scroll and
  pull-to-refresh
- Debounced `/products/search` with stale-response protection, Enter to submit,
  immediate clear, and distinct empty states
- Chunked, per-query persistent product cache with cache-first rendering,
  background refresh, and offline notices
- Responsive 2/3/4/5-column lazy product grid with cached thumbnails
- Debug API logs with redacted credentials
- Preserved responsive storefront, shared `AppScaffold`/`AppAppBar`, bundled
  Poppins, and Material 3 theme
- DevicePreview and a custom Chrome loading screen

Categories and Cart remain themed placeholders in this phase.

## Architecture

```text
lib/
├── main.dart                        # dotenv, DI, app, deferred session restore
├── app/
│   ├── app.dart                     # MaterialApp.router and DevicePreview
│   ├── startup_error_app.dart
│   ├── di/injector.dart             # auth, product, cache, and router wiring
│   ├── router/app_router.dart       # splash/login/protected redirects
│   ├── router/go_router_refresh_stream.dart
│   └── shell/main_shell.dart        # four-tab NavigationBar
├── core/
│   ├── config/                      # Environment validation
│   ├── network/                     # Dio transport and debug API logging
│   ├── storage/                     # shared_preferences wrapper
│   ├── theme/                       # Colors, spacing, typography, theme
│   ├── utils/                       # Responsive metrics and formatters
│   └── widgets/                     # Scaffold, app bar, brand, state views
└── features/
    ├── auth/
    │   ├── domain/                  # User, tokens, failures, repositories, use cases
    │   ├── data/                    # Dio data source, models, interceptor, storage
    │   └── presentation/            # AuthCubit, auth states, login, splash
    ├── account/presentation/        # Profile and confirmed logout
    ├── products/
    │   ├── domain/                  # Product, pages, failures, repository, use cases
    │   ├── data/                    # Dio remote, chunked cache, models, error mapper
    │   └── presentation/            # ProductListCubit, Home screen, grid, notices
    ├── categories/presentation/     # Categories placeholder
    └── cart/presentation/           # Cart placeholder
```

The auth feature follows Clean Architecture:

- Presentation depends on domain use cases through `AuthCubit`.
- Domain owns `User`, `AuthSession`, failures, repository contracts, and the
  session-expiration event.
- Data implements the repositories with a Dio data source, response models, an
  error mapper, and JSON session storage.
- Dependency injection wires a separate bare Dio for login/refresh and a
  protected Dio with `AuthInterceptor`.

Widgets receive dependencies through constructors and `BlocProvider`; only
bootstrap code and tests touch the service locator.

The products feature follows the same layering:

- Presentation owns `ProductListCubit`, the sealed list states, and widgets.
- Domain owns `Product`, `ProductPage`, query normalization, failures, the
  repository contract, and catalogue/search/cache use cases.
- Data implements the repository with an authenticated Dio data source, tolerant
  response models, a chunked `SharedPreferences` cache, and a Dio error mapper.
- `ProductListCubit` guards every first-page request with a generation counter
  and drops results after `close()`, so late responses cannot update Home after
  logout.

## Responsive behaviour

| Width      | Device  | Page gutter | Product columns |
| ---------- | ------- | ----------- | --------------- |
| `< 600`    | Mobile  | 16          | 2               |
| `600–899`  | Tablet  | 24          | 3               |
| `900–1099` | Desktop | 32          | 4               |
| `≥ 1100`   | Desktop | 32          | 5               |

Content is capped at 1200 px and centred on large screens. Banner and card
heights grow with the text scaler for accessibility. The bottom navigation bar
is used at every width.

## Device preview

The bootstrap currently passes `enableDevicePreview: false`; the debug/profile
expression is kept commented in `main.dart`. The project pins
`device_preview: 1.3.1` because 3.x requires Flutter ≥ 3.47.0.

## Verification

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

The test suite uses fakes and a fake HTTP adapter, so it never calls the live
API. It covers:

- login validation, success, API failures, password visibility, and in-flight
  submit protection
- session JSON round-trips, corrupt storage, save/read/clear, and restore
- API log redaction for passwords, tokens, nested fields, failures, and disabled
  logging
- interceptor token attachment, refresh-and-retry, shared refresh for concurrent
  `401`s, transient refresh failures, and expiry
- Account profile rendering, placeholders, logout cancellation, and confirmation
- splash restore, route protection, logout routing, and expiry redirects
- tolerant product parsing, pagination metadata, and malformed-item skipping
- chunked cache writes, per-query separation, append/dedupe, eviction, schema
  mismatch, and corrupted entries
- repository endpoint selection, query normalization, empty-search cache
  clearing, cache-write failures, and offline cache preservation
- cubit cache-first loading, background refresh, offline and refresh notices,
  auth-vs-offline classification, 500 ms debounce, stale responses, immediate
  clear, distinct empty states, pagination/dedupe/stop, retry, and post-logout
  response suppression
- Home responsive columns, search/clear, offline retry, refresh notices,
  pagination loader/error, refresh action visibility, placeholders, narrow
  text-scale layout, and capped search width

Latest verification (Flutter 3.41.7 / Dart 3.11.5): `flutter analyze` reports no
issues and `flutter test` passes all 144 tests.

## Current scope

Implemented:

- Real authentication, token persistence, and automatic refresh
- Session restore with a splash screen and protected routing
- Four-tab shell with a working Account tab
- Paginated product catalogue with infinite scroll, pull-to-refresh, and a
  responsive lazy grid
- Debounced API search with empty/error states and stale-response protection
- Chunked per-query product cache with cache-first rendering and offline notices

Deliberately excluded:

- Product details, reviews, and category filtering
- Cart logic, checkout, and payments
- New authentication flows, profile editing, and dark theme
