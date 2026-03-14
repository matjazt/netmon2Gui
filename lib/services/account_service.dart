import '../models/account.dart';
import 'api_client.dart';

/// Wraps all /api/accounts and /api/account-networks endpoints used by the UI.
class AccountService {
  final _dio = ApiClient.instance.dio;

  /// Returns the account belonging to the currently authenticated user.
  Future<Account> getMe() async {
    final r = await _dio.get('/api/accounts/me');
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  /// Admin only: returns every account.
  Future<List<Account>> getAllAccounts() async {
    final r = await _dio.get('/api/accounts');
    return (r.data as List)
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Account> getAccountById(int id) async {
    final r = await _dio.get('/api/accounts/$id');
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Account> createAccount(SaveAccountRequest req) async {
    final r = await _dio.post('/api/accounts', data: req.toJson());
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Account> updateAccount(int id, SaveAccountRequest req) async {
    final r = await _dio.put('/api/accounts/$id', data: req.toJson());
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteAccount(int id) async {
    await _dio.delete('/api/accounts/$id');
  }

  /// Grants an existing user-type account access to a network.
  Future<void> grantAccess(int accountId, int networkId) async {
    await _dio.post(
      '/api/account-networks/grant-access',
      queryParameters: {'accountId': accountId, 'networkId': networkId},
    );
  }

  /// Returns networks accessible to a given account.
  Future<List<dynamic>> getNetworksByAccount(int accountId) async {
    final r = await _dio.get(
      '/api/account-networks/networks-by-account/$accountId',
    );
    return r.data as List;
  }

  /// Removes an account-network link by its own id.
  Future<void> revokeAccess(int accountNetworkId) async {
    await _dio.delete('/api/account-networks/$accountNetworkId');
  }

  /// Returns all AccountNetworkDto records for a network (to get link IDs for revocation).
  Future<List<dynamic>> getAccountNetworksByNetwork(int networkId) async {
    final r = await _dio.get('/api/account-networks/network/$networkId');
    return r.data as List;
  }
}
