import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/tracking/background_tracking_service.dart';
import '../../../../core/websocket/websocket_providers.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../task/presentation/providers/task_providers.dart';
import '../../data/datasource/punch_api.dart';
import '../../data/repository/punch_repository.dart';

final punchApiProvider = Provider<PunchApi>((ref) {
  return PunchApi(ref.watch(dioProvider));
});

final punchRepositoryProvider = Provider<PunchRepository>((ref) {
  return PunchRepository(
    api: ref.watch(punchApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});

class PunchState {
  const PunchState({
    required this.isPunchedIn,
    required this.loading,
    this.sessionId,
    this.punchInTime,
    this.taskId,
  });

  final bool isPunchedIn;
  final bool loading;
  final String? sessionId;
  final DateTime? punchInTime;
  final int? taskId;

  PunchState copyWith({
    bool? isPunchedIn,
    bool? loading,
    String? sessionId,
    DateTime? punchInTime,
    int? taskId,
  }) {
    return PunchState(
      isPunchedIn: isPunchedIn ?? this.isPunchedIn,
      loading: loading ?? this.loading,
      sessionId: sessionId ?? this.sessionId,
      punchInTime: punchInTime ?? this.punchInTime,
      taskId: taskId ?? this.taskId,
    );
  }

  PunchState clearSession() {
    return PunchState(
      isPunchedIn: false,
      loading: loading,
      sessionId: null,
      punchInTime: null,
      taskId: null,
    );
  }
}

class PunchController extends StateNotifier<PunchState> {
  PunchController(this._ref)
    : super(const PunchState(isPunchedIn: false, loading: false)) {
    _init();
    _startRealTimeListening();
  }

  final Ref _ref;
  bool _isListening = false;

  static const _kSessionIdKey = 'session_id';
  static const _kPunchInTimeKey = 'punch_in_time';
  static const _secureStorage = FlutterSecureStorage();

  void _startRealTimeListening() {
    if (_isListening) return;
    _isListening = true;
    _ref.listen(punchEventsProvider, (previous, next) {
      next.when(
        data: (event) => _handlePunchEvent(event),
        loading: () {},
        error: (error, stack) {},
      );
    });

    _ref.listen(attendanceEventsProvider, (previous, next) {
      next.when(
        data: (event) => _handleAttendanceEvent(event),
        loading: () {},
        error: (error, stack) {},
      );
    });
  }

  void _handlePunchEvent(Map<String, dynamic> event) {
    final eventType = event['type'];
    if (eventType == 'PUNCH_IN') {
      state = state.copyWith(isPunchedIn: true);
    } else if (eventType == 'PUNCH_OUT') {
      state = state.clearSession();
    }
  }

  void _handleAttendanceEvent(Map<String, dynamic> event) {
    final eventType = event['type'];
    if (eventType == 'ATTENDANCE_MARKED') {
      state = state.copyWith(isPunchedIn: true);
    } else if (eventType == 'ATTENDANCE_CLOSED') {
      state = state.clearSession();
    }
  }

  Future<void> _init() async {
    // Fetch active session from backend
    try {
      final session = await _ref
          .read(punchRepositoryProvider)
          .getActiveSession();
      if (session != null) {
        state = state.copyWith(
          isPunchedIn: true,
          sessionId: session.sessionId,
          punchInTime: session.punchInTime,
          taskId: session.taskId,
        );
        await _secureStorage.write(
          key: _kSessionIdKey,
          value: session.sessionId,
        );
        await _secureStorage.write(
          key: _kPunchInTimeKey,
          value: session.punchInTime.toIso8601String(),
        );
        await BackgroundTrackingService.start();
      }
    } catch (e) {
      final storedSessionId = await _secureStorage.read(key: _kSessionIdKey);
      final storedPunchInTimeRaw = await _secureStorage.read(
        key: _kPunchInTimeKey,
      );

      DateTime? storedPunchInTime;
      if (storedPunchInTimeRaw != null) {
        storedPunchInTime = DateTime.tryParse(storedPunchInTimeRaw);
      }

      if (storedSessionId != null && storedSessionId.isNotEmpty) {
        state = state.copyWith(
          isPunchedIn: true,
          sessionId: storedSessionId,
          punchInTime: storedPunchInTime,
        );
        await BackgroundTrackingService.start();
      }
    }
  }

  Future<void> punchIn({int? taskId}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      await _ensurePermission();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      var tasksWithDistance = _ref.read(tasksWithDistanceProvider);
      final eligibleStatuses = {'INQUIRY', 'IN_PROGRESS', 'DELAYED'};

      int? matchedTaskId;

      double? _readDouble(Map<String, dynamic> map, String key) {
        final v = map[key];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }

      if (tasksWithDistance.isNotEmpty) {
        for (final t in tasksWithDistance) {
          final status = t.task['status']?.toString();
          if (status == null || !eligibleStatuses.contains(status)) continue;

          final id = t.task['id'];
          final candidateTaskId = id is int
              ? id
              : int.tryParse(id?.toString() ?? '');
          if (candidateTaskId == null) continue;

          final customerAddress = t.customerAddress;
          final taskLat = customerAddress != null
              ? _readDouble(customerAddress, 'latitude')
              : null;
          final taskLng = customerAddress != null
              ? _readDouble(customerAddress, 'longitude')
              : null;
          if (taskLat == null || taskLng == null) continue;

          final distance = DistanceCalculator.calculateDistance(
            pos.latitude,
            pos.longitude,
            taskLat,
            taskLng,
          );

          if (distance <= 200.0) {
            matchedTaskId = candidateTaskId;
            break;
          }
        }
      } else {
        final tasks = await _ref.read(tasksProvider.future);
        if (tasks.isEmpty) {
          throw Exception('No active task found');
        }

        for (final raw in tasks) {
          final t = Map<String, dynamic>.from(raw as Map);

          final status = t['status']?.toString();
          if (status == null || !eligibleStatuses.contains(status)) continue;

          final id = t['id'];
          final candidateTaskId = id is int
              ? id
              : int.tryParse(id?.toString() ?? '');
          if (candidateTaskId == null) continue;

          final taskLat =
              _readDouble(t, 'latitude') ??
              _readDouble(t, 'customerLatitude') ??
              _readDouble(t, 'customer_latitude');
          final taskLng =
              _readDouble(t, 'longitude') ??
              _readDouble(t, 'customerLongitude') ??
              _readDouble(t, 'customer_longitude');

          if (taskLat == null || taskLng == null) continue;

          final distance = DistanceCalculator.calculateDistance(
            pos.latitude,
            pos.longitude,
            taskLat,
            taskLng,
          );

          if (distance <= 200.0) {
            matchedTaskId = candidateTaskId;
            break;
          }
        }
      }

      if (matchedTaskId == null) {
        throw Exception(
          'You must be within 200 meters of a task location to punch in',
        );
      }

      final now = DateTime.now();
      final tenAM = DateTime(now.year, now.month, now.day, 10, 0);
      final attendanceStatus = now.isAfter(tenAM) ? 'LATE' : 'PRESENT';

      final response = await _ref
          .read(punchRepositoryProvider)
          .punchIn(
            position: pos,
            taskId: matchedTaskId,
            attendanceStatus: attendanceStatus,
          );

      final sessionId = (response['sessionId'] ?? response['id'])?.toString();
      final dynamic rawPunchInTime = response['punchInTime'];
      final DateTime punchInTime = rawPunchInTime is String
          ? DateTime.tryParse(rawPunchInTime) ?? DateTime.now()
          : DateTime.now();

      state = state.copyWith(
        isPunchedIn: true,
        sessionId: sessionId,
        punchInTime: punchInTime,
        taskId: matchedTaskId,
      );

      await _secureStorage.write(key: _kSessionIdKey, value: sessionId);
      await _secureStorage.write(
        key: _kPunchInTimeKey,
        value: punchInTime.toIso8601String(),
      );
      await BackgroundTrackingService.start();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> punchOut() async {
    if (state.loading || state.sessionId == null) return;
    state = state.copyWith(loading: true);
    try {
      await _ensurePermission();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _ref
          .read(punchRepositoryProvider)
          .punchOut(sessionId: state.sessionId!, position: pos);

      await _secureStorage.delete(key: _kSessionIdKey);
      await _secureStorage.delete(key: _kPunchInTimeKey);
      state = state.clearSession();
      await BackgroundTrackingService.stop();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw StateError('Location permission denied forever');
    }
  }

  @override
  void dispose() {
    _isListening = false;
    super.dispose();
  }
}

final punchControllerProvider =
    StateNotifierProvider<PunchController, PunchState>((ref) {
      return PunchController(ref);
    });

// Phase-5: Punch animation provider
final punchAnimationProvider =
    StateNotifierProvider<PunchAnimationNotifier, String>((ref) {
      return PunchAnimationNotifier();
    });

class PunchAnimationNotifier extends StateNotifier<String> {
  PunchAnimationNotifier() : super('');

  void triggerPunchAnimation(String type) {
    state = type;

    // Reset animation after completion
    Future.delayed(const Duration(milliseconds: 600), () {
      state = '';
    });
  }
}
