# Mini Store

A responsive Flutter storefront for mobile, tablet, and desktop. The app starts
on a real login screen, restores saved sessions, opens a protected four-tab
shell, and loads the DummyJSON product catalogue with search, pagination,
categories, cache-first product details, and offline-aware errors. A shared
local cart with a dummy checkout completes the shopping flow.

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

Home and category browsing use the protected Dio client:

```text
GET /products?limit=10&skip=<loaded>
GET /products/search?q=<query>&limit=10&skip=<loaded>
GET /products/categories
GET /products/category/{slug}?limit=10&skip=<loaded>
GET /products/{id}
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

The normal catalogue uses `__all__` as its meta key. Up to twenty query caches
are kept, including one `category:<slug>` namespace per category; evicting one
removes its metadata and any product entries no longer referenced by another
query. `__all__` is protected from category and search traffic. Cached products
render immediately and are refreshed in the background without a hard TTL. On a
failed refresh the cache is preserved and an inline notice explains what is
being shown. The product cache survives logout; only the authentication session
is cleared.

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

## Categories

The Categories tab loads the plain category list once, shows saved categories
immediately, and refreshes in the background. The list is stored under
`mini_store.categories.v1` as a small JSON array. Pull-to-refresh, Retry, and an
offline notice reuse the same cache-first policy as the catalogue.

Category cards use the first product image of each category as a preview
background. Once the list is visible, missing previews are fetched in the
background with four concurrent requests (`GET /products/category/{slug}` with
`limit=1`, preferring `thumbnail` and falling back to the first gallery image).
Resolved URLs are stored under `mini_store.category_images.v1`; the bytes
themselves stay in the shared network image disk cache, so later launches paint
the grid without extra requests. Preview failures never block the list and
simply leave the category icon fallback in place.

Selecting a category pushes `/categories/:slug` with the display name as a query
parameter. The screen reuses `ProductListCubit` in category mode, so it shares
the Home grid, pagination footer, pull-to-refresh, retry, and notice widgets:

- Requests use the API slug, never the display name.
- Each category has its own cache key, so browsing Beauty can never show saved
  Home Decoration products.
- Next-page failures keep the loaded products on screen and offer Try again.
- Opening a product from the category grid pushes the same product-details route
  used by Home.

## Product details

Details are cache-first per product id under
`mini_store.product_detail.v1.<id>`. When a full detail entry is missing, the
cached list item in `mini_store.products.v1.item.<id>` is used for an immediate
first paint. The cached product renders while a background refresh runs, and a
failed refresh keeps the cached content with a subtle Retry notice. A first
visit without cache shows a loader, then an offline or retryable error state.

The gallery is a swipeable carousel with page dots, a stable aspect ratio,
placeholders for loading or broken images, and a Hero transition for the first
image. Detail caching stores the same fields the screen renders, including the
name, rating, reviews, and comments, without writing one oversized JSON value.
Duplicate loads, stale responses, and emissions after the cubit closes are
ignored or suppressed.

The bottom action bar persists every quantity change before reporting success:

- Add to cart is disabled while a write is in flight.
- A successful add changes the bar to `−` / quantity / `+` plus Go to cart.
- An existing cart line opens directly with its stored quantity.
- Go to cart selects the existing Cart tab instead of pushing a second shell.
- A storage failure keeps the previous cart and shows the error; no success is
  faked.

## Cart and local checkout

`CartCubit` is a single shared cubit registered in the service locator and
provided above the shell. The screen and cubit never touch `SharedPreferences`
directly; the repository writes the cart under `mini_store.cart.v1` and the cubit
persists each change before emitting new state.

- Cart lines store product id, title, unit price, thumbnail, and quantity.
- Duplicate ids are merged on restore; increment, decrement, and remove-at-zero
  keep one line per product.
- Totals are derived from quantity and unit price, including the navigation
  badge, which updates only after a successful write.
- The restored cart survives an app restart and a logout; only auth is cleared.
- Quantity changes apply immediately without confirmation dialogs.

Place order is blocked for an empty cart. Confirmation shows the unit count and
total, then simulates roughly 1.2 seconds of local processing. A dismissible
dialog can cancel without changing the cart. On success the app:

1. generates a readable order number such as `MS-20481`, never a hardcoded one;
2. snapshots the confirmed item count and total;
3. persists an empty cart and updates the badge;
4. opens the order-success screen.

Duplicate submissions are blocked, and a cart persistence failure prevents a
false success. Continue shopping returns to Home with the cart empty. The session,
catalogue cache, category cache, and product-detail cache are preserved. There is
no order API or order history.

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
│ GET https://dummyjson.com/products/categories
└────────────────────────────────────────────────────────────────────────
┌─ API RESPONSE #2 · 200 ───────────────────────────────────────────────
│ GET https://dummyjson.com/products/categories
│ Time: 142 ms
│
│ Response body
│ [
│   {
│     "slug": "beauty",
│     "name": "Beauty",
│     "url": "https://dummyjson.com/products/category/beauty"
│   },
│   {
│     "slug": "fragrances",
│     "name": "Fragrances",
│     "url": "https://dummyjson.com/products/category/fragrances"
│   }
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
- Category browser with cache-first loading, image-backed cards, and isolated
  paginated category product lists
- Cache-first product details with gallery, reviews, Hero transition, and
  non-blocking background refresh
- Shared persistent cart with badge, quantity editing, totals, and confirmed
  remove actions
- Local dummy checkout with confirmation, processing state, unique order number,
  and order-success summary
- Chunked, per-query persistent product cache with cache-first rendering,
  background refresh, and offline notices
- Responsive 2/3/4/5-column lazy product grid with cached thumbnails
- Auto-hiding Home and Categories bottom navigation that collapses while
  scrolling down and returns when scrolling stops
- Single blue Home app bar with a notifications shortcut and a matching
  empty-state notifications screen
- System chrome matched to the app: transparent status bar with readable icons
  and a light surface system navigation bar on every screen
- Debug API logs with redacted credentials
- Preserved responsive storefront, shared `AppScaffold`/`AppAppBar`, bundled
  Poppins, and Material 3 theme
- DevicePreview and a custom Chrome loading screen

## Architecture

```text
lib/
├── main.dart                        # dotenv, DI, app, deferred session restore
├── app/
│   ├── app.dart                     # MaterialApp.router and DevicePreview
│   ├── startup_error_app.dart
│   ├── di/injector.dart             # auth, catalogue, categories, cart, orders, router
│   ├── router/app_router.dart       # splash/login/shell/details/category/notifications/success
│   ├── router/go_router_refresh_stream.dart
│   └── shell/main_shell.dart        # shared four-tab NavigationBar
├── core/
│   ├── config/                      # Environment validation
│   ├── network/                     # Dio transport and debug API logging
│   ├── storage/                     # shared_preferences wrapper
│   ├── theme/                       # Colors, spacing, typography, theme, system chrome
│   ├── utils/                       # Responsive metrics and formatters
│   └── widgets/                     # Scaffold, app bar, images, auto-hide nav, state views
└── features/
    ├── auth/
    │   ├── domain/                  # User, tokens, failures, repositories, use cases
    │   ├── data/                    # Dio data source, models, interceptor, storage
    │   └── presentation/            # AuthCubit, auth states, login, splash
    ├── account/presentation/        # Profile and confirmed logout
    ├── products/
    │   ├── domain/                  # Product, pages, failures, repository, use cases
    │   ├── data/                    # Dio remote, chunked cache, models, error mapper
    │   └── presentation/            # ProductListCubit, Home, category listing, grid
    ├── categories/
    │   ├── domain/                  # Category entity, repository, use cases
    │   ├── data/                    # Categories endpoint, JSON cache, model
    │   └── presentation/            # CategoriesCubit and Categories screen
    ├── product_details/
    │   ├── domain/                  # Detail repository contract and use case
    │   ├── data/                    # Detail endpoint, per-id cache, repository
    │   └── presentation/            # ProductDetailCubit, carousel, detail screen
    ├── cart/
    │   ├── domain/                  # CartItem, repository, storage failure
    │   ├── data/                    # Persistent cart data source and repository
    │   └── presentation/            # Shared CartCubit, cart screen, item tile
    └── orders/
        ├── domain/                  # Order, number generator, place-order use case
        └── presentation/            # CheckoutCubit and order-success screen
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
  logout. It also accepts a `ProductListSource`, which is how category listings
  reuse the same loading, pagination, and refresh logic with an isolated cache
  namespace.

Categories and product details follow the same feature-first layering. The
detail cubit reads its per-id cache first, emits cached content with
`isRefreshing`, then refreshes asynchronously; generation and in-flight guards
prevent duplicate or post-dispose emissions. Cart and checkout separate domain
contracts from storage and presentation:

- `CartCubit` is created once by the service locator and provided above the
  shell, so the badge, Cart tab, and details action bar share one state.
- Every mutation is serialized and saved before it is emitted; a failed write
  returns `false` and leaves the previous cart intact.
- `CheckoutCubit` snapshots the confirmed totals, blocks concurrent submissions,
  clears the persisted cart, and exposes the completed order only after the clear
  succeeds. The success screen reads that snapshot rather than the live cart.
- `MainTabController` lets pushed screens select Home or Cart without stacking a
  second shell route.

## Responsive behaviour

| Width      | Device  | Page gutter | Product columns |
| ---------- | ------- | ----------- | --------------- |
| `< 600`    | Mobile  | 16          | 2               |
| `600–899`  | Tablet  | 24          | 3               |
| `900–1099` | Desktop | 32          | 4               |
| `≥ 1100`   | Desktop | 32          | 5               |

Content is capped at 1200 px and centred on large screens. Banner and card
heights grow with the text scaler for accessibility. The bottom navigation bar
is used at every width and auto-hides while Home or Categories scroll down.

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
- category parsing, slug preservation, cache-first loading, isolated category
  caches, slug-based pagination, next-page retry, and first-page failures
- detail cache round-trips (including reviews), per-id isolation, first-visit
  loader/error paths, cached-before-refresh rendering, refresh updates and
  failures, duplicate-load protection, and post-close emission suppression
- cart restore, add/increment/decrement/remove, duplicate merging, totals,
  persistence failures, serialized mutations, and empty-cart clearing
- checkout empty/cancelled/confirmed flows, cart snapshotting, processing state,
  unique order numbers, duplicate submissions, storage-failure handling, and
  Continue shopping reset
- category screen cards, selection, empty state, and bottom-bar auto-hide on
  both Home and Categories, including tab switches
- shared system chrome values, app-bar overlay brightness, and bottom-bar
  hide/restore timing

Latest verification (Flutter 3.41.7 / Dart 3.11.5): `flutter analyze` reports no
issues and `flutter test` passes all 240 tests.

## Current scope

Implemented:

- Real authentication, token persistence, and automatic refresh
- Session restore with a splash screen and protected routing
- Four-tab shell with working Categories, Cart, and Account tabs
- Paginated product catalogue with infinite scroll, pull-to-refresh, and a
  responsive lazy grid
- Debounced API search with empty/error states and stale-response protection
- Cache-first categories and isolated paginated category product lists
- Cache-first product details with gallery, reviews, Hero transition, and
  background refresh
- Shared persistent cart with badge, quantity controls, totals, and storage
  failure handling
- Local dummy checkout with confirmation, processing state, order number, and
  success summary
- Chunked per-query product cache with cache-first rendering and offline notices

Deliberately excluded:

- Real payments, order history, and order APIs
- Quick add-to-cart actions on product cards
- New authentication flows, profile editing, and dark theme
