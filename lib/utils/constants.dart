/// Application-wide constants.
///
/// The API base URL is defined here only — change it in one place to point
/// the app at a different backend instance.
library;

// ─── Backend ────────────────────────────────────────────────────────────────

/// Base URL of the NetMon2 REST API (no trailing slash).
const String kApiBaseUrl = 'http://localhost:8080/netmon2';

// ─── Account type IDs (hardcoded, matches schema.sql seed data) ─────────────

/// Administrator — full access to all networks and admin panel.
const int kAccountTypeAdmin = 1;

/// Regular user — access only to their assigned networks.
const int kAccountTypeUser = 2;

/// Device account (used by MQTT scanner scripts).
/// These accounts can be managed by admins but cannot log in to the GUI.
const int kAccountTypeDevice = 3;

/// Human-readable labels for account type IDs.
const Map<int, String> kAccountTypeLabels = {
  kAccountTypeAdmin: 'Admin',
  kAccountTypeUser: 'User',
  kAccountTypeDevice: 'Device',
};

// ─── SharedPreferences keys ──────────────────────────────────────────────────

const String kPrefUsername = 'username';
const String kPrefPassword = 'password';
const String kPrefThemeMode = 'themeMode'; // 'light' | 'dark' | 'system'
const String kPrefSelectedNetworkId = 'selectedNetworkId';

// ─── Dashboard refresh interval ─────────────────────────────────────────────

const Duration kDashboardRefreshInterval = Duration(seconds: 30);

// ─── Pagination defaults ─────────────────────────────────────────────────────

const int kDefaultPageSize = 20;
const int kLogPageSize = 100; // larger page to compensate for no server filter
const int kHistoryPageSize = 50;

// ─── Log level definitions (match server-side values) ────────────────────────

const int kLogLevelTrace = 5000;
const int kLogLevelDebug = 10000;
const int kLogLevelInfo = 20000;
const int kLogLevelWarn = 30000;
const int kLogLevelError = 40000;

/// Returns a short display name for a raw log level integer.
String logLevelName(int level) {
  if (level <= kLogLevelTrace) return 'TRACE';
  if (level <= kLogLevelDebug) return 'DEBUG';
  if (level <= kLogLevelInfo) return 'INFO';
  if (level <= kLogLevelWarn) return 'WARN';
  return 'ERROR';
}
