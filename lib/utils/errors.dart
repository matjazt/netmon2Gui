import 'package:dio/dio.dart';

/// Returns a concise, human-readable detail string for [e].
/// Extracts HTTP status code and server-provided message from [DioException].
/// Falls back to [e.toString()] for other exceptions.
String errorMessage(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMsg;
    if (data is Map) {
      serverMsg = (data['message'] ?? data['error'] ?? data['detail'])
          ?.toString();
    } else if (data is String && data.isNotEmpty) {
      serverMsg = data;
    }
    if (status != null && serverMsg != null) return 'HTTP $status: $serverMsg';
    if (status != null) return 'HTTP $status';
    if (serverMsg != null) return serverMsg;
    return e.message ?? e.toString();
  }
  return e.toString();
}
