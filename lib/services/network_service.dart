import 'dart:convert';

import '../models/network.dart';
import 'api_client.dart';

/// Wraps all /api/networks endpoints.
class NetworkService {
  final _dio = ApiClient.instance.dio;

  /// Admin: returns all networks.
  Future<List<Network>> getAllNetworks() async {
    final r = await _dio.get('/api/networks');
    return (r.data as List)
        .map((e) => Network.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// User: returns networks accessible to the given account.
  /// Uses the account-networks controller.
  Future<List<Network>> getNetworksByAccount(int accountId) async {
    final r = await _dio.get(
      '/api/account-networks/networks-by-account/$accountId',
    );
    return (r.data as List)
        .map((e) => Network.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Network> getNetworkById(int id) async {
    final r = await _dio.get('/api/networks/$id');
    return Network.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Network> createNetwork(SaveNetworkRequest req) async {
    final r = await _dio.post('/api/networks', data: req.toJson());
    return Network.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Network> updateNetwork(int id, SaveNetworkRequest req) async {
    final r = await _dio.put('/api/networks/$id', data: req.toJson());
    return Network.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteNetwork(int id) async {
    await _dio.delete('/api/networks/$id');
  }
}

/// Sent when creating or updating a network.
/// The [configuration] field is serialised to JSON string before sending.
class SaveNetworkRequest {
  final String name;
  final NetworkConfiguration configuration;

  const SaveNetworkRequest({required this.name, required this.configuration});

  Map<String, dynamic> toJson() => {
    'name': name,
    // Server expects configuration as a JSON string.
    'configuration': jsonEncode(configuration.toJson()),
  };
}
