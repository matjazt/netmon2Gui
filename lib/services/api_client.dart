import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/constants.dart';

/// Singleton Dio instance shared by all services.
/// Attaches HTTP Basic Auth on every request, reading credentials from the
/// [ApiClient.configure] method called at login / app start.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  String? _username;
  String? _password;

  /// Sets Basic Auth credentials and adds an interceptor that injects them on
  /// every request.
  void configure(String username, String password) {
    _username = username;
    _password = password;
    _dio.interceptors.clear();
    _dio.interceptors.add(
      LogInterceptor(
        // TODO: tule izklopi HTTP logiranje v release buildih
        requestBody: true,
        responseBody: true,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final credentials = base64Encode(
            utf8.encode('$_username:$_password'),
          );
          options.headers['Authorization'] = 'Basic $credentials';
          handler.next(options);
        },
      ),
    );
  }

  /// Clears stored credentials. Call on logout.
  void clear() {
    _username = null;
    _password = null;
    _dio.interceptors.clear();
  }

  Dio get dio => _dio;
}
