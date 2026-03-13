import '../models/device_status_history.dart';
import '../models/page_result.dart';
import 'api_client.dart';

/// Wraps /api/device-status-history endpoints.
class HistoryService {
  final _dio = ApiClient.instance.dio;

  Future<PageResult<DeviceStatusHistory>> getByNetwork(
    int networkId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/device-status-history/network/$networkId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      DeviceStatusHistory.fromJson,
    );
  }

  Future<PageResult<DeviceStatusHistory>> getByDevice(
    int deviceId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/device-status-history/device/$deviceId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      DeviceStatusHistory.fromJson,
    );
  }

  Future<PageResult<DeviceStatusHistory>> getByNetworkAndTimestampRange(
    int networkId,
    DateTime minTimestamp,
    DateTime maxTimestamp, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/device-status-history/network/$networkId/by-timestamp',
      queryParameters: {
        'minTimestamp': minTimestamp.toUtc().toIso8601String(),
        'maxTimestamp': maxTimestamp.toUtc().toIso8601String(),
        'page': page,
        'size': size,
      },
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      DeviceStatusHistory.fromJson,
    );
  }

  Future<PageResult<DeviceStatusHistory>> getByDeviceAndTimestampRange(
    int deviceId,
    DateTime minTimestamp,
    DateTime maxTimestamp, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/device-status-history/device/$deviceId/by-timestamp',
      queryParameters: {
        'minTimestamp': minTimestamp.toUtc().toIso8601String(),
        'maxTimestamp': maxTimestamp.toUtc().toIso8601String(),
        'page': page,
        'size': size,
      },
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      DeviceStatusHistory.fromJson,
    );
  }
}
