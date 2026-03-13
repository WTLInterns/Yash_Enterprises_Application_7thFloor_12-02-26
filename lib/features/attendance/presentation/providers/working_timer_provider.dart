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
  DateTime? _startedAt;

  void _listenToPunchState() {
    _ref.listen<PunchState>(punchControllerProvider, (prev, next) {
      if (next.isPunchedIn && !state.running) {
        start();
      } else if (!next.isPunchedIn && state.running) {
        stop();
      }
    });
  }

  void start() {
    _startedAt ??= DateTime.now();
    state = state.copyWith(running: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _startedAt;
      if (startedAt == null) return;
      state = state.copyWith(elapsed: DateTime.now().difference(startedAt));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;

    _startedAt = null;
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
