import 'package:dio/dio.dart';

String handleDioError(DioException e) {
  try {
    final data = e.response?.data;

    String? backendMessage;
    if (data is Map) {
      final raw = data['message'];
      if (raw != null) {
        backendMessage = raw.toString();
      }
    }

    final msg = backendMessage ?? '';

    if (msg.contains('Already punched in')) {
      return 'You are already checked in.';
    }

    if (msg.contains('200 meters') || msg.contains('200')) {
      return 'You are not within the task location range (200m).';
    }

    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Network timeout. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }

    return 'Something went wrong. Please try again.';
  } catch (_) {
    return 'Something went wrong. Please try again.';
  }
}
