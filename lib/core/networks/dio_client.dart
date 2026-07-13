import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'logging_interceptor.dart';

class DioClient {
  static final Dio dio = _initDio();

  static Dio _initDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    client.interceptors.add(LoggingInterceptor());

    return client;
  }
}

