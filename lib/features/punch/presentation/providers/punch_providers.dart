import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/location/robust_location_service.dart';
import '../../../../core/websocket/websocket_providers.dart';
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
  const PunchState({required this.isPunchedIn, required this.loading});

  final bool isPunchedIn;
  final bool loading;

  PunchState copyWith({bool? isPunchedIn, bool? loading}) {
    return PunchState(
      isPunchedIn: isPunchedIn ?? this.isPunchedIn,
      loading: loading ?? this.loading,
    );
  }
}

class PunchController extends StateNotifier<PunchState> {
  PunchController(this._ref) : super(const PunchState(isPunchedIn: false, loading: false)) {
    _init();
    _startRealTimeListening();
  }

  final Ref _ref;
  bool _isListening = false;

  static const _kPunchedInKey = 'punched_in';
  static const _secureStorage = FlutterSecureStorage();

  void _startRealTimeListening() {
    if (_isListening) return;
    _isListening = true;
    // Listen for punch events from WebSocket
    _ref.listen(punchEventsProvider, (previous, next) {
      next.when(
        data: (event) {
          // Update punch state based on real-time events
          _handlePunchEvent(event);
        },
        loading: () {},
        error: (error, stack) {},
      );
    });

    // Listen for attendance events that might affect punch status
    _ref.listen(attendanceEventsProvider, (previous, next) {
      next.when(
        data: (event) {
          // Update punch state based on attendance events
          _handleAttendanceEvent(event);
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
  }

  void _handlePunchEvent(Map<String, dynamic> event) {
    // Handle real-time punch events
    final eventType = event['type'];
    final employeeId = event['employeeId'];
    
    // Update local punch state based on event
    if (eventType == 'PUNCH_IN') {
      state = state.copyWith(isPunchedIn: true);
    } else if (eventType == 'PUNCH_OUT') {
      state = state.copyWith(isPunchedIn: false);
    }
  }

  void _handleAttendanceEvent(Map<String, dynamic> event) {
    // Handle real-time attendance events that might affect punch status
    final eventType = event['type'];
    
    // Update punch state based on attendance events
    if (eventType == 'ATTENDANCE_MARKED') {
      // Could indicate punch-in
      state = state.copyWith(isPunchedIn: true);
    } else if (eventType == 'ATTENDANCE_CLOSED') {
      // Could indicate punch-out
      state = state.copyWith(isPunchedIn: false);
    }
  }

  Future<void> _init() async {
    final store = _ref.read(rawKeyValueStorageProvider);
    final flag = await store.readBool(_kPunchedInKey) ?? false;
    state = state.copyWith(isPunchedIn: flag);

    // If user was already punched-in, ensure background tracking is running.
    if (flag) {
      await _secureStorage.write(key: _kPunchedInKey, value: '1');
      await RobustLocationService().startTracking();
    }
  }

  Future<void> punchIn() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      await _ensurePermission();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _ref.read(punchRepositoryProvider).punchIn(position: pos);
      await _ref.read(rawKeyValueStorageProvider).writeBool(_kPunchedInKey, true);
      await _secureStorage.write(key: _kPunchedInKey, value: '1');
      state = state.copyWith(isPunchedIn: true);
      await RobustLocationService().startTracking();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> punchOut() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      await _ensurePermission();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _ref.read(punchRepositoryProvider).punchOut(position: pos);
      await _ref.read(rawKeyValueStorageProvider).writeBool(_kPunchedInKey, false);
      await _secureStorage.write(key: _kPunchedInKey, value: '0');
      state = state.copyWith(isPunchedIn: false);
      await RobustLocationService().stopTracking();
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

final punchControllerProvider = StateNotifierProvider<PunchController, PunchState>((ref) {
  return PunchController(ref);
});

// Phase-5: Punch animation provider
final punchAnimationProvider = StateNotifierProvider<PunchAnimationNotifier, String>((ref) {
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
