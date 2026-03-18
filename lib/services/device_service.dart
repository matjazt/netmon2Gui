import '../models/device.dart';
import '../models/device_status_history.dart';
import 'api_client.dart';

/// Wraps all /api/devices and related endpoints.
class DeviceService {
  final _dio = ApiClient.instance.dio;

  Future<List<Device>> getDevicesByNetwork(int networkId) async {
    final r = await _dio.get('/api/devices/network/$networkId');
    return (r.data as List)
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Device> getDeviceById(int id) async {
    final r = await _dio.get('/api/devices/$id');
    return Device.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Device> updateDevice(int id, SaveDeviceRequest req) async {
    final r = await _dio.put('/api/devices/$id', data: req.toJson());
    return Device.fromJson(r.data as Map<String, dynamic>);
  }

  /// Quickly flips a device's operation mode.
  /// [mode] must be one of: UNAUTHORIZED, AUTHORIZED, ALWAYS_ON
  Future<Device> updateDeviceMode(int id, String mode) async {
    final r = await _dio.put(
      '/api/devices/$id/mode',
      queryParameters: {'mode': mode},
    );
    return Device.fromJson(r.data as Map<String, dynamic>);
  }

  Future<DeviceStats> getDeviceStats(int networkId) async {
    final r = await _dio.get('/api/devices/network/$networkId/stats');
    return DeviceStats.fromJson(r.data as Map<String, dynamic>);
  }

  /// Returns the most recent [limit] status history entries for a device.
  Future<List<DeviceStatusHistory>> getDeviceHistory(
    int deviceId, {
    int limit = 1000,
  }) async {
    final r = await _dio.get(
      '/api/devices/$deviceId/history',
      queryParameters: {'limit': limit},
    );
    return (r.data as List)
        .map((e) => DeviceStatusHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
