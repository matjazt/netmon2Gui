# netmon2Gui

Flutter web + Windows frontend for the [netmon2](https://github.com/matjazt/netmon2) Spring Boot network monitoring backend.

## Overview

netmon2Gui provides a Material 3 dashboard UI for managing networks, devices, alerts, and logs collected by the netmon2 backend. It supports two user roles — **Admin** and **User** — with role-aware navigation and scoped data access.

**Supported platforms:** Web (primary), Windows (debug/dev).

## Tech Stack

| Concern | Library / Version |
|---|---|
| Framework | Flutter 3.32.1, Dart SDK `^3.8.1` |
| HTTP client | dio `^5.7.0` |
| State management | provider `^6.1.2` |
| Persistence | shared_preferences `^2.3.3` |
| Date formatting | intl `^0.20.1` |
| UI design system | Material 3, seed color `#1565C0` |

## Prerequisites

The backend — **netmon2** (Spring Boot, Java 21) — must be running and reachable.  
Default base URL: `http://localhost:8080/netmon2`  
Change it in **one place**: `lib/utils/constants.dart` → `kApiBaseUrl`.

```dart
// lib/utils/constants.dart
const String kApiBaseUrl = 'http://localhost:8080/netmon2';
```

## Running the App

```bash
# Install dependencies
flutter pub get

# Web (primary target)
flutter run -d chrome

# Windows desktop
flutter run -d windows

# Release build for web
flutter build web
```

## Project Structure

```
lib/
├── main.dart                  # App entry point, MaterialApp, routing, AppShell, MainScaffold
├── utils/
│   ├── constants.dart         # API base URL, account type IDs, SharedPreferences keys,
│   │                          #   refresh interval, page size, logLevelName() helper
│   └── theme.dart             # AppTheme.lightTheme / darkTheme (Material 3, seed #1565C0)
├── models/
│   ├── account.dart           # Account, SaveAccountRequest
│   ├── network.dart           # Network, NetworkConfiguration (parses embedded JSON string)
│   ├── device.dart            # Device, SaveDeviceRequest, DeviceStats
│   ├── alert.dart             # Alert, AlertType enum (networkDown/deviceDown/…)
│   ├── log_entry.dart         # LogEntry
│   ├── device_status_history.dart  # DeviceStatusHistory
│   └── page_result.dart       # Generic PageResult<T> for Spring Page* DTOs
├── services/
│   ├── api_client.dart        # Dio singleton; configure(u,p) sets Basic Auth; clear() on logout
│   ├── account_service.dart   # CRUD + access grant/revoke for /api/accounts, /api/account-networks
│   ├── network_service.dart   # CRUD for /api/networks; SaveNetworkRequest (serialises config)
│   ├── device_service.dart    # Read + update for /api/devices; mode change, stats, history
│   ├── alert_service.dart     # Read-only: /api/alerts by network or device
│   ├── log_service.dart       # Paginated log fetch: all (admin) or by-network / by-device
│   └── history_service.dart   # Status history: by-network, by-device, with timestamp range
├── providers/
│   ├── auth_provider.dart     # Login/logout/session restore; blocks device-type accounts (typeId=3)
│   ├── network_provider.dart  # Loads + persists selected network; admins see all, users see own
│   └── settings_provider.dart # ThemeMode: System / Light / Dark; persisted to SharedPreferences
├── widgets/
│   ├── network_card.dart      # Card widget: alert-state colour, LAN icon, onTap
│   ├── device_list_tile.dart  # Tile: online indicator, MAC/vendor/IP, mode chip
│   ├── alert_list_tile.dart   # Tile: open/closed colour, type label, timestamp
│   ├── log_list_tile.dart     # Tile: colour-coded level (TRACE→ERROR), origin, timestamp
│   ├── history_list_tile.dart # Tile: online/offline circle icon, timestamp, IP
│   ├── network_config_form.dart  # Form: all 6 NetworkConfiguration fields; onSave callback
│   ├── confirm_dialog.dart    # showConfirmDialog() → Future<bool>
│   └── error_display.dart     # Centered error icon + message + optional retry button
└── screens/
    ├── login_screen.dart      # Credential form; onLoginSuccess callback wires into AppShell
    ├── dashboard_screen.dart  # 30 s auto-refresh; network panel + device list with stats header
    ├── network_detail_screen.dart  # 3 tabs: Devices / Alerts / Info; admin can edit config
    ├── device_detail_screen.dart   # 3 tabs: Info / Alerts / History; admin rename + mode change
    ├── logs_screen.dart       # Infinite-scroll; admin → all logs; user → selected-network logs
    ├── history_screen.dart    # Infinite-scroll; scoped to selected network
    ├── settings_screen.dart   # ThemeMode radio; account info; sign-out
    └── admin/
        ├── admin_accounts_screen.dart  # List + create/edit/delete accounts
        ├── admin_account_form.dart     # Account fields incl. type dropdown; password optional on edit
        ├── admin_networks_screen.dart  # List + create/edit/delete networks
        └── admin_network_form.dart     # Name field + NetworkConfigForm
```

## Authentication

- HTTP **Basic Auth** on every request, managed by `ApiClient` (Dio interceptor).
- Credentials are saved to `SharedPreferences` (browser `localStorage` on web) so the session survives a page reload.
- **Device accounts** (`typeId = 3`) are blocked from logging in — they exist for API-only access from monitoring agents.

### Account Types

| typeId | Role | UI Access |
|---|---|---|
| `1` | **Admin** | All screens, all networks, admin management pages |
| `2` | **User** | Dashboard, Logs, History scoped to assigned networks |
| `3` | **Device** | API only — login blocked in the UI |

## Navigation

`MainScaffold` renders adaptively based on the window width:

- **≥ 600 px** — `NavigationRail` (left sidebar, always visible)
- **< 600 px** — `NavigationDrawer` (hamburger menu)

Nav items visible to everyone: **Dashboard**, **Logs**, **History**, **Settings**.  
Nav items visible to admins only: **Accounts**, **Networks**.

## Key Design Decisions

| Decision | Rationale |
|---|---|
| `dio` with `InterceptorsWrapper` | Centralises Basic Auth; credentials set once in `ApiClient`, used by all services |
| `provider` (not Riverpod/BLoC) | Sufficient complexity level; minimal boilerplate for a CRUD monitoring UI |
| Dashboard auto-refresh every 30 s | Configurable via `kDashboardRefreshInterval` in `constants.dart` |
| No client-side log filtering | Logs can be voluminous; filtering deferred to backend query parameters |
| Logs/History scoped to selected network for users | Network context is the primary organisational unit for non-admins |
| `NetworkConfiguration` stored as JSON string in DB | Backend serialises the config; the frontend parses it in `Network.config` getter |
| `SaveNetworkRequest` defined in `network_service.dart` | Belongs with the service that uses it, avoiding a thin standalone model file |
| Routing via named routes | Simple enough for this app size; passes model objects as `RouteSettings.arguments` |

## API Endpoint Mapping

| Screen | Main Endpoints |
|---|---|
| Login | `GET /api/accounts/me` |
| Dashboard | `GET /api/networks`, `GET /api/devices/by-network/{id}`, `GET /api/devices/{id}/stats` |
| Network Detail | `GET /api/devices/by-network/{id}`, `GET /api/alerts/by-network/{id}`, `PUT /api/networks/{id}` |
| Device Detail | `GET /api/devices/{id}`, `GET /api/alerts/by-device/{id}`, `GET /api/device-status-history/by-device/{id}` |
| Logs (admin) | `GET /api/logs/paginated` |
| Logs (user) | `GET /api/logs/network/{id}` |
| History | `GET /api/device-status-history/by-network/{id}` |
| Admin Accounts | `GET/POST /api/accounts`, `PUT/DELETE /api/accounts/{id}` |
| Admin Networks | `GET/POST /api/networks`, `PUT/DELETE /api/networks/{id}` |

## Notes for AI Agents

### Layer Responsibilities

- **`models/`** — pure data classes with `fromJson` / `toJson`. No business logic.
- **`services/`** — one class per resource, each method maps to one API call. Use `ApiClient.instance.dio` directly.
- **`providers/`** — `ChangeNotifier` subclasses that orchestrate services, hold UI state, and call `notifyListeners()`. Never call services from widgets directly.
- **`widgets/`** — stateless display components. Receive data and callbacks as constructor parameters.
- **`screens/`** — stateful pages. Consume providers via `context.watch` / `context.read`. Build UI from widget primitives.

### Provider Access Pattern

```dart
// Read reactive state (rebuilds on change):
final auth = context.watch<AuthProvider>();

// Trigger action (no rebuild):
context.read<NetworkProvider>().loadNetworks(isAdmin: true);
```

### Adding a New Screen

1. Create `lib/screens/my_screen.dart`.
2. Add a named route in `main.dart` → `MaterialApp.routes`.
3. If it requires a nav item, add it to `MainScaffold._destinations` and conditionally include it.
4. If it needs new data, add a service method + provider getter as appropriate.

### Adding a New Service Method

1. Add the method to the relevant file in `lib/services/`.
2. Use `ApiClient.instance.dio.get/post/put/delete(path)`.
3. The `Authorization: Basic …` header is added automatically by the interceptor.

### SharedPreferences Keys

All keys are defined as constants in `lib/utils/constants.dart`:

```dart
const String kPrefUsername = 'username';
const String kPrefPassword = 'password';
const String kPrefThemeMode = 'themeMode';
const String kPrefSelectedNetworkId = 'selectedNetworkId';
```

### Important Caveats

- `NetworkConfiguration` is serialised as a JSON **string** inside the `Network` JSON. The `Network.config` getter calls `jsonDecode` on that string — do not double-decode.
- `DeviceStatusHistory` records are fetched per-device; looping over devices is done in `HistoryScreen` / `HistoryService` methods.
- The `dart analyze lib` baseline is **"No issues found!"** — keep it clean before committing.

## License

[MIT](LICENSE) © 2025 matjazt

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
