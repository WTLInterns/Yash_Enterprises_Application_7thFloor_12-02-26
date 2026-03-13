import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../tracking/background_tracking_service.dart';
import 'robustbg_location_service.dart';

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

class RobustLocationTrackingNotifier
    extends StateNotifier<RobustLocationTrackingState> {
  RobustLocationTrackingNotifier() : super(RobustLocationTrackingState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RobustBgLocationService.instance.initialize();
      state = state.copyWith(isInitialized: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startTracking() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await BackgroundTrackingService.start();
      await RobustBgLocationService.instance.tick(
        trigger: RobustBgTickTrigger.manual,
      );
      state = state.copyWith(isTracking: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> stopTracking() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await BackgroundTrackingService.stop();
      state = state.copyWith(isTracking: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus() async {
    try {
      Map<String, dynamic>? lastKnown;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        lastKnown = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
        };
      } catch (_) {
        lastKnown = state.lastKnownPosition;
      }
      state = state.copyWith(
        isInitialized: true,
        isTracking: state.isTracking,
        lastKnownPosition: lastKnown,
        lastUpdateTime: DateTime.now().toIso8601String(),
        consecutiveFailures: state.consecutiveFailures,
        trackingMethod: 'robustbg_engine',
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
final robustLocationTrackingProvider =
    StateNotifierProvider<
      RobustLocationTrackingNotifier,
      RobustLocationTrackingState
    >((ref) {
      return RobustLocationTrackingNotifier();
    });
