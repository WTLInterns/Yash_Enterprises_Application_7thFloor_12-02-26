import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'robust_location_service.dart';

class RobustLocationTrackingState {
  final bool isInitialized;
  final bool isTracking;
  final Map<String, dynamic>? lastKnownPosition;
  final String? lastUpdateTime;
  final bool isLoading;
  final String? error;
  final int consecutiveFailures;
  final String trackingMethod;

  RobustLocationTrackingState({
    this.isInitialized = false,
    this.isTracking = false,
    this.lastKnownPosition,
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
    this.consecutiveFailures = 0,
    this.trackingMethod = 'robust_background',
  });

  RobustLocationTrackingState copyWith({
    bool? isInitialized,
    bool? isTracking,
    Map<String, dynamic>? lastKnownPosition,
    String? lastUpdateTime,
    bool? isLoading,
    String? error,
    int? consecutiveFailures,
    String? trackingMethod,
  }) {
    return RobustLocationTrackingState(
      isInitialized: isInitialized ?? this.isInitialized,
      isTracking: isTracking ?? this.isTracking,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      trackingMethod: trackingMethod ?? this.trackingMethod,
    );
  }
}

class RobustLocationTrackingNotifier extends StateNotifier<RobustLocationTrackingState> {
  final RobustLocationService _service;

  RobustLocationTrackingNotifier(this._service) : super(RobustLocationTrackingState());

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
        consecutiveFailures: status['consecutiveFailures'] ?? 0,
        trackingMethod: status['trackingMethod'] ?? 'robust_background',
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
final robustLocationTrackingServiceProvider = Provider<RobustLocationService>((ref) {
  return RobustLocationService();
});

final robustLocationTrackingProvider = StateNotifierProvider<RobustLocationTrackingNotifier, RobustLocationTrackingState>((ref) {
  final service = ref.watch(robustLocationTrackingServiceProvider);
  return RobustLocationTrackingNotifier(service);
});
