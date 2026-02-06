import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/storage_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('🌐 Dio Request: ${options.method} ${options.path}');
        if (options.data != null) {
          print('🌐 Dio Data: ${options.data}');
        }
        final token = await ref.read(secureSessionStorageProvider).readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('🌐 Dio Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (e, handler) async {
        print('🌐 Dio Error: ${e.response?.statusCode} ${e.requestOptions.path}');
        print('🌐 Dio Error Body: ${e.response?.data}');
        // If backend returns 401, session is invalid.
        if (e.response?.statusCode == 401) {
          await ref.read(secureSessionStorageProvider).clear();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});
