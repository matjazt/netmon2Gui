import '../models/alert.dart';
import 'api_client.dart';

/// Wraps /api/alerts endpoints.
class AlertService {
  final _dio = ApiClient.instance.dio;

  Future<Alert> getAlertById(int id) async {
    final r = await _dio.get('/api/alerts/$id');
    return Alert.fromJson(r.data as Map<String, dynamic>);
  }

  /// [active] = true returns only open (un-closed) alerts.
  Future<List<Alert>> getAlertsByNetwork(
    int networkId, {
    bool activeOnly = false,
  }) async {
    final r = await _dio.get(
      '/api/alerts/network/$networkId',
      queryParameters: {'active': activeOnly},
    );
    return (r.data as List)
        .map((e) => Alert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [active] = true returns only open alerts.
  Future<List<Alert>> getAlertsByDevice(
    int deviceId, {
    bool activeOnly = false,
  }) async {
    final r = await _dio.get(
      '/api/alerts/device/$deviceId',
      queryParameters: {'active': activeOnly},
    );
    return (r.data as List)
        .map((e) => Alert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
