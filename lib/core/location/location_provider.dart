import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'background_location_service.dart';

class LocationTrackingState {
  final bool isTracking;
  final bool isInitialized;
  final Map<String, dynamic>? lastKnownPosition;
  final String? lastUpdateTime;
  final bool isLoading;
  final String? error;

  // Add getter for compatibility
  Map<String, dynamic>? get currentPosition => lastKnownPosition;

  LocationTrackingState({
    this.isTracking = false,
    this.isInitialized = false,
    this.lastKnownPosition,
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
  });

  LocationTrackingState copyWith({
    bool? isTracking,
    bool? isInitialized,
    Map<String, dynamic>? lastKnownPosition,
    String? lastUpdateTime,
    bool? isLoading,
    String? error,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      isInitialized: isInitialized ?? this.isInitialized,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  final BackgroundLocationService _service;

  LocationTrackingNotifier(this._service) : super(LocationTrackingState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.initialize();
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> startTracking() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.startTracking();
      state = state.copyWith(
        isTracking: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> stopTracking() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.stopTracking();
      state = state.copyWith(
        isTracking: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateStatus() async {
    try {
      final status = _service.getTrackingStatus();
      state = state.copyWith(
        isInitialized: status['isInitialized'] ?? false,
        isTracking: status['isTracking'] ?? false,
        lastKnownPosition: status['lastKnownPosition'],
        lastUpdateTime: status['lastUpdateTime'],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final locationTrackingServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService();
});

final locationTrackingProvider = StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>((ref) {
  final service = ref.watch(locationTrackingServiceProvider);
  return LocationTrackingNotifier(service);
});

// Stream provider for real-time updates
final locationStatusStreamProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final service = ref.watch(locationTrackingServiceProvider);
  
  while (true) {
    await Future.delayed(Duration(seconds: 10));
    final status = service.getTrackingStatus();
    yield status;
  }
});
