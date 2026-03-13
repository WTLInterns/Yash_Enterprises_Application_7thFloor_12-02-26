import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/storage_providers.dart';

Dio createConfiguredDio({
  required Future<String?> Function() readToken,
  Future<void> Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (kDebugMode) {
          print('🌐 Dio Request: ${options.method} ${options.path}');
          if (options.data != null) {
            print('🌐 Dio Data: ${options.data}');
          }
        }

        final token = await readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },

      onResponse: (response, handler) {
        if (kDebugMode) {
          print(
            '🌐 Dio Response: ${response.statusCode} ${response.requestOptions.path}',
          );
        }
        handler.next(response);
      },

      onError: (e, handler) async {
        if (kDebugMode) {
          print(
            '🌐 Dio Error: ${e.response?.statusCode} ${e.requestOptions.path}',
          );
          print('🌐 Dio Error Body: ${e.response?.data}');
        }

        if (e.response?.statusCode == 401) {
          await onUnauthorized?.call();
        }

        handler.next(e);
      },
    ),
  );

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  return createConfiguredDio(
    readToken: () => ref.read(secureSessionStorageProvider).readToken(),
    onUnauthorized: () => ref.read(secureSessionStorageProvider).clear(),
  );
});