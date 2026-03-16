import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../tracking/background_tracking_service.dart';
import 'robustbg_location_service.dart';

class LocationTrackingState {
  final bool isTracking;
  final bool isInitialized;
  final Map<String, dynamic>? lastKnownPosition;
  final String? lastUpdateTime;
  final bool isLoading;
  final String? error;

  // Add getter for compatibility
  Map<String, dynamic>? get currentPosition => lastKnownPosition;

  // Add helper method to check if location is fresh
  bool get isLocationFresh {
    if (lastUpdateTime == null || lastKnownPosition == null) return false;

    final lastUpdate = DateTime.tryParse(lastUpdateTime!);
    if (lastUpdate == null) return false;

    // Consider location fresh if updated within last 2 minutes
    return DateTime.now().difference(lastUpdate).inMinutes < 2;
  }

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
  LocationTrackingNotifier() : super(LocationTrackingState());

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
        isInitialized: true,
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

  // Ensure location is available and fresh before API calls
  Future<Map<String, dynamic>?> ensureLocationAvailable() async {
    // If location is fresh, return it immediately
    if (state.isLocationFresh && state.currentPosition != null) {
      return state.currentPosition;
    }

    // Otherwise, update location
    await updateStatus();

    // Return updated location
    return state.currentPosition;
  }
}

// Provider
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>((
      ref,
    ) {
      return LocationTrackingNotifier();
    });

// Stream provider for real-time updates
final locationStatusStreamProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) async* {
  // No longer backed by a legacy service. Emit best-effort snapshots for UI.

  while (true) {
    await Future.delayed(Duration(seconds: 10));
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

    yield {
      'isInitialized': true,
      'isTracking': ref.read(locationTrackingProvider).isTracking,
      'lastKnownPosition': lastKnown,
      'lastUpdateTime': DateTime.now().toIso8601String(),
    };
  }
});
