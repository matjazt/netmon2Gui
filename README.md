# netmon2Gui

Flutter frontend for the [netmon2](https://github.com/matjazt/netmon2) network monitoring backend.

## Overview

netmon2Gui is a Material 3 dashboard for managing networks, devices, alerts, and logs collected by the netmon2 backend. All communication goes through the netmon2 REST API with HTTP Basic Auth.

netmon2 handles MQTT-based device scanning, state change detection, alerting, and persistent storage. This app is the read/write GUI on top of it.

Most of the code was written with the help of an AI coding assistant (GitHub Copilot / Claude).
It is a work in progress, with lots of duplicated code and room for refactoring, but it is functional and supports most needed features of the backend.

## Supported Platforms

- Web
- Android
- Windows desktop

## Live Demo

A public demo is available at **<https://netmon2.terpin-it.eu/gui/>**

Log in with:

| Field | Value |
|---|---|
| Username | `hitchhiker` |
| Password | `galaxyfarfaraway` |

The `hitchhiker` account has read-only access to two fictional simulated networks. Feel free to explore.

## Prerequisites

- Flutter SDK — see `pubspec.yaml` for the SDK constraint
- A running [netmon2](https://github.com/matjazt/netmon2) backend instance

## Configuration

The REST API base URL is injected at build time via `--dart-define`. The default fallback is `http://localhost:8080/netmon2`.

Pass it on the command line:

```bash
flutter run  --dart-define=API_BASE_URL=https://yourserver/netmon2
flutter build web --dart-define=API_BASE_URL=https://yourserver/netmon2
```

Or keep it in an untracked JSON file and use `--dart-define-from-file`:

```json
// env/prod.json  — add to .gitignore
{
  "API_BASE_URL": "https://yourserver/netmon2"
}
```

```bash
flutter run --dart-define-from-file=env/prod.json
```

## Building and Running

### Web

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://yourserver/netmon2
flutter build web --dart-define=API_BASE_URL=https://yourserver/netmon2
# Output: build/web/
```

### Android

```bash
flutter pub get
flutter run -d <device-id> --dart-define=API_BASE_URL=https://yourserver/netmon2
flutter build apk --dart-define=API_BASE_URL=https://yourserver/netmon2
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Windows

```bash
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=https://yourserver/netmon2
flutter build windows --dart-define=API_BASE_URL=https://yourserver/netmon2
# Output: build/windows/x64/runner/Release/
```

## Account Types

| typeId | Role | Access |
|---|---|---|
| 1 | Admin | All screens, all networks, admin management pages |
| 2 | User | Dashboard, Logs, History scoped to assigned networks |
| 4 | Viewer | Read-only access to assigned networks |

Credentials are persisted to `SharedPreferences` (browser `localStorage` on web) and restored on next startup.

## Project Structure

```
lib/
├── main.dart              # App entry point, routing, AppShell
├── models/                # JSON-serialisable data classes
├── services/              # One class per API resource (thin Dio wrappers)
├── providers/             # ChangeNotifier state management
├── screens/               # Full-page widgets
│   └── admin/             # Admin-only management pages
├── widgets/               # Reusable display components
└── utils/
    ├── constants.dart     # API URL, account type IDs, page sizes, intervals
    └── theme.dart         # Material 3 theme
```

## API Endpoint Mapping

All endpoints require HTTP Basic Auth. Paths are relative to the configured API base URL.

| Screen / Feature | Endpoints |
|---|---|
| Login / session restore | `GET /api/accounts/me` |
| Dashboard | `GET /api/networks` (admin) · `GET /api/account-networks/networks-by-account/{id}` (users) · `GET /api/devices/network/{id}/stats` · `GET /api/alerts/network/{id}` |
| Network Detail | `GET /api/networks/{id}` · `GET /api/devices/network/{id}` · `GET /api/alerts/network/{id}` · `GET /api/logs/network/{id}` · `GET /api/device-status-history/network/{id}` · `PUT /api/networks/{id}` (admin) · `PUT /api/devices/{id}/mode` (admin) |
| Device Detail | `GET /api/devices/{id}` · `GET /api/alerts/device/{id}` · `GET /api/logs/device/{id}` · `GET /api/device-status-history/device/{id}` · `PUT /api/devices/{id}/name` (admin) |
| Logs | `GET /api/logs/my` |
| History | `GET /api/device-status-history/my` |
| Admin → Accounts | `GET /api/accounts` · `POST /api/accounts` · `PUT /api/accounts/{id}` · `DELETE /api/accounts/{id}` · `GET /api/account-networks/networks-by-account/{id}` · `POST /api/account-networks/grant-access` · `GET /api/account-networks/network/{id}` · `DELETE /api/account-networks/{id}` |
| Admin → Networks | `GET /api/networks` · `POST /api/networks` · `PUT /api/networks/{id}` · `DELETE /api/networks/{id}` |
