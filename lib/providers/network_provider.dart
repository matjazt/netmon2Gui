import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/network.dart';
import '../services/network_service.dart';
import '../utils/constants.dart';
import '../utils/errors.dart';

/// Holds the list of networks the current user can see and tracks which one
/// is selected. The selected network is persisted in SharedPreferences so the
/// choice survives across app restarts.
class NetworkProvider extends ChangeNotifier {
  List<Network> _networks = [];
  Network? _selectedNetwork;
  bool _loading = false;
  String? _error;

  List<Network> get networks => _networks;
  Network? get selectedNetwork => _selectedNetwork;
  bool get loading => _loading;
  String? get error => _error;

  final _networkService = NetworkService();

  /// Loads networks for the given account. Pass [isAdmin] and [accountId].
  /// Restores (or picks) the selected network from SharedPreferences.
  Future<void> loadNetworks({
    required bool isAdmin,
    required int accountId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (isAdmin) {
        _networks = await _networkService.getAllNetworks();
      } else {
        _networks = await _networkService.getNetworksByAccount(accountId);
      }
      _networks.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      // Restore persisted selection.
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(kPrefSelectedNetworkId);
      if (savedId != null) {
        _selectedNetwork = _networks.where((n) => n.id == savedId).firstOrNull;
      }
      // Fall back to first network if saved id is no longer accessible.
      _selectedNetwork ??= _networks.isNotEmpty ? _networks.first : null;
    } catch (e) {
      _error = 'Failed to load networks.\n${errorMessage(e)}';
    }

    _loading = false;
    notifyListeners();
  }

  /// Changes the selected network and persists the choice.
  Future<void> selectNetwork(Network network) async {
    _selectedNetwork = network;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kPrefSelectedNetworkId, network.id);
    notifyListeners();
  }

  /// Call when the user logs out to clear cached data.
  void clear() {
    _networks = [];
    _selectedNetwork = null;
    _error = null;
    notifyListeners();
  }
}
