import '../models/log_entry.dart';
import '../models/page_result.dart';
import 'api_client.dart';

/// Wraps /api/logs endpoints.
class LogService {
  final _dio = ApiClient.instance.dio;

  /// Admin: all logs, paginated.
  Future<PageResult<LogEntry>> getAllLogsPaginated({
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/logs/my',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      LogEntry.fromJson,
    );
  }

  /// Logs scoped to a specific network.
  Future<PageResult<LogEntry>> getLogsByNetwork(
    int networkId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/logs/network/$networkId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      LogEntry.fromJson,
    );
  }

  /// Logs scoped to a specific device.
  Future<PageResult<LogEntry>> getLogsByDevice(
    int deviceId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/logs/device/$deviceId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResult.fromJson(
      r.data as Map<String, dynamic>,
      LogEntry.fromJson,
    );
  }
}
