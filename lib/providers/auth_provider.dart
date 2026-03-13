import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../services/api_client.dart';
import '../services/account_service.dart';
import '../utils/constants.dart';

/// Manages the currently authenticated user.
///
/// Call [tryRestoreSession] once at app startup. On success the user goes
/// straight to the dashboard; on failure the login screen is shown.
class AuthProvider extends ChangeNotifier {
  Account? _currentUser;
  bool _loading = false;
  String? _error;

  Account? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  /// True when the authenticated account has type admin (id = 1).
  bool get isAdmin => _currentUser?.accountTypeId == kAccountTypeAdmin;

  final _accountService = AccountService();

  /// Attempts to log in with [username] / [password].
  /// Stores credentials in SharedPreferences on success.
  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      ApiClient.instance.configure(username, password);
      final account = await _accountService.getMe();

      // Device accounts (type 3) are not allowed to use the GUI.
      if (account.accountTypeId == kAccountTypeDevice) {
        ApiClient.instance.clear();
        _error = 'Device accounts cannot log in.';
        _loading = false;
        notifyListeners();
        return false;
      }

      _currentUser = account;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefUsername, username);
      await prefs.setString(kPrefPassword, password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      ApiClient.instance.clear();
      _currentUser = null;
      _error = 'Login failed. Check your credentials.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reads saved credentials and tries to restore the previous session silently.
  /// Returns true when the session was restored.
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(kPrefUsername);
    final password = prefs.getString(kPrefPassword);
    if (username == null || password == null) return false;
    return login(username, password);
  }

  /// Clears credentials and returns to the logged-out state.
  Future<void> logout() async {
    ApiClient.instance.clear();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kPrefUsername);
    await prefs.remove(kPrefPassword);
    notifyListeners();
  }
}
