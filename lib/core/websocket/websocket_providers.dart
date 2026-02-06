import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/websocket/websocket_service.dart';

// WebSocket service provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService.instance;
});

// Real-time event providers
final attendanceEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.attendanceEvents;
});

final taskEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.taskEvents;
});

final punchEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.punchEvents;
});

// Connection status provider
final webSocketConnectionProvider = Provider<bool>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.isConnected;
});
