import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../tracking/background_tracking_service.dart';
import 'robustbg_location_service.dart';

class SimpleLocationTrackingState {
  final bool isTracking;
  final bool isInitialized;
  final Map<String, dynamic>? lastKnownPosition;
  final String? lastUpdateTime;
  final bool isLoading;
  final String? error;

  SimpleLocationTrackingState({
    this.isTracking = false,
    this.isInitialized = false,
    this.lastKnownPosition,
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
  });

  SimpleLocationTrackingState copyWith({
    bool? isTracking,
    bool? isInitialized,
    Map<String, dynamic>? lastKnownPosition,
    String? lastUpdateTime,
    bool? isLoading,
    String? error,
  }) {
    return SimpleLocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      isInitialized: isInitialized ?? this.isInitialized,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SimpleLocationTrackingNotifier
    extends StateNotifier<SimpleLocationTrackingState> {
  SimpleLocationTrackingNotifier() : super(SimpleLocationTrackingState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RobustBgLocationService.instance.initialize();
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
        lastKnown = null;
      }
      state = state.copyWith(
        isInitialized: true,
        lastKnownPosition: lastKnown,
        lastUpdateTime: DateTime.now().toIso8601String(),
        isLoading: false,
      );
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
        isInitialized: state.isInitialized,
        isTracking: state.isTracking,
        lastKnownPosition: lastKnown,
        lastUpdateTime: DateTime.now().toIso8601String(),
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
final simpleLocationTrackingProvider =
    StateNotifierProvider<
      SimpleLocationTrackingNotifier,
      SimpleLocationTrackingState
    >((ref) {
      return SimpleLocationTrackingNotifier();
    });
