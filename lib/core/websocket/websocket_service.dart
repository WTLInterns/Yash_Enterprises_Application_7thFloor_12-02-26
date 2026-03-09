import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  WebSocketService._();

  final _secureStorage = const FlutterSecureStorage();
  StompClient? _stompClient;
  bool _isConnected = false;
  bool _isConnecting = false;
  final Map<String, dynamic> _subscriptions = {};
  
  // Stream controllers for real-time updates
  final _attendanceController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskController = StreamController<Map<String, dynamic>>.broadcast();
  final _punchController = StreamController<Map<String, dynamic>>.broadcast();
  final _adminNotificationController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get attendanceEvents => _attendanceController.stream;
  Stream<Map<String, dynamic>> get taskEvents => _taskController.stream;
  Stream<Map<String, dynamic>> get punchEvents => _punchController.stream;
  Stream<Map<String, dynamic>> get adminNotificationStream => _adminNotificationController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;

    try {
      // Get JWT token from secure storage
      final token = await _secureStorage.read(key: 'jwt_token');
      
      // Prepare headers with JWT authentication
      final stompHeaders = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
      final webSocketHeaders = token != null ? {'Authorization': 'Bearer $token'} : <String, dynamic>{};

      _stompClient = StompClient(
        config: StompConfig(
          url: 'ws://localhost:8080/ws',
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onStompError,
          stompConnectHeaders: stompHeaders,
          webSocketConnectHeaders: webSocketHeaders,
        ),
      );

      _stompClient!.activate();
      print('WebSocket connecting with JWT authentication...');
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnecting = false;
    }
  }

  void _onStompError(StompFrame frame) {
    print('WebSocket STOMP error: ${frame.body}');
    _isConnecting = false;
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _isConnecting = false;
    print('WebSocket connected');

    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    if (_stompClient == null || !_isConnected) return;

    _cleanupSubscriptions();

    try {
      final attendanceSub = _stompClient!.subscribe(
        destination: '/topic/attendance-events',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!) as Map<String, dynamic>;
              _attendanceController.add(data);
            } catch (e) {
              print('Error parsing attendance event: $e');
            }
          }
        },
      );
      _subscriptions['attendance'] = attendanceSub;

      final taskSub = _stompClient!.subscribe(
        destination: '/topic/task-events',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!) as Map<String, dynamic>;
              _taskController.add(data);
            } catch (e) {
              print('Error parsing task event: $e');
            }
          }
        },
      );
      _subscriptions['task'] = taskSub;

      final punchSub = _stompClient!.subscribe(
        destination: '/topic/punch-events',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!) as Map<String, dynamic>;
              _punchController.add(data);
            } catch (e) {
              print('Error parsing punch event: $e');
            }
          }
        },
      );
      _subscriptions['punch'] = punchSub;

      // ADD THIS: Subscribe to admin notifications
      final adminSub = _stompClient!.subscribe(
        destination: '/topic/admin-notifications',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!) as Map<String, dynamic>;
              _adminNotificationController.add(data);
            } catch (e) {
              print('Error parsing admin notification: $e');
            }
          }
        },
      );
      _subscriptions['adminNotification'] = adminSub;

    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  void _cleanupSubscriptions() {
    _subscriptions.forEach((key, subscription) {
      try {
        subscription.unsubscribe();
      } catch (e) {
        print('Error unsubscribing from $key: $e');
      }
    });
    _subscriptions.clear();
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
    _isConnecting = false;
    print('WebSocket disconnected');
    _cleanupSubscriptions();
  }

  void _onError(StompFrame frame) {
    _isConnected = false;
    _isConnecting = false;
    print('WebSocket error: ${frame.body}');
    _cleanupSubscriptions();
  }

  void disconnect() {
    _cleanupSubscriptions();
    _stompClient?.deactivate();
    _isConnected = false;
    _isConnecting = false;
  }

  void dispose() {
    _attendanceController.close();
    _taskController.close();
    _punchController.close();
    disconnect();
  }
}
