import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../punch/presentation/providers/punch_providers.dart';

class WorkingTimerState {
  const WorkingTimerState({
    required this.running,
    required this.elapsed,
  });

  final bool running;
  final Duration elapsed;

  WorkingTimerState copyWith({bool? running, Duration? elapsed}) {
    return WorkingTimerState(
      running: running ?? this.running,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class WorkingTimerController extends StateNotifier<WorkingTimerState> {
  WorkingTimerController(this._ref)
      : super(const WorkingTimerState(running: false, elapsed: Duration.zero)) {
    _listenToPunchState();
  }

  final Ref _ref;
  Timer? _timer;

  void _listenToPunchState() {
    _ref.listen<PunchState>(punchControllerProvider, (prev, next) {
      if (next.isPunchedIn && next.punchInTime != null && !state.running) {
        startFromBackendTime(next.punchInTime!);
      } else if (!next.isPunchedIn && state.running) {
        stop();
      }
    });
  }

  void startFromBackendTime(DateTime punchInTime) {
    state = state.copyWith(running: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Calculate elapsed time from backend punchInTime
      final elapsed = DateTime.now().difference(punchInTime);
      state = state.copyWith(elapsed: elapsed);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(running: false, elapsed: Duration.zero);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workingTimerProvider =
    StateNotifierProvider<WorkingTimerController, WorkingTimerState>((ref) {
  return WorkingTimerController(ref);
});
