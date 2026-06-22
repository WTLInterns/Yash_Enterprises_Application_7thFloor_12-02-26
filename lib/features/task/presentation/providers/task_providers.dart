import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/storage/secure_session_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/websocket/websocket_providers.dart';
import '../../data/datasource/task_api.dart';
import '../../data/repository/task_repository.dart';

final taskApiProvider = Provider<TaskApi>((ref) {
  return TaskApi(ref.watch(dioProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(api: ref.watch(taskApiProvider));
});

final secureStorageProvider = Provider<SecureSessionStorage>((ref) {
  return SecureSessionStorage(const FlutterSecureStorage());
});

// Current employee ID provider for real-time access
final currentEmployeeIdProvider = StateProvider<String?>((ref) => null);

const bool _taskProviderDebugLogs = true;

void _taskProviderLog(String message) {
  if (!_taskProviderDebugLogs) return;
  print('[TaskProviders] $message');
}

final tasksProvider = FutureProvider<List<dynamic>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final employeeId = await storage.readEmployeeId();

  _taskProviderLog('tasksProvider: read employeeId=$employeeId');

  if (employeeId == null) {
    throw Exception('Employee ID not found. Please login again.');
  }

  // Store employee ID in provider for real-time access
  ref.read(currentEmployeeIdProvider.notifier).state = employeeId;

  _taskProviderLog('tasksProvider: fetching tasks for employeeId=$employeeId');

  final list = await ref
      .watch(taskRepositoryProvider)
      .getTasksForEmployee(int.parse(employeeId));

  _taskProviderLog('tasksProvider: received length=${list.length}');
  if (list.isNotEmpty && list.first is Map) {
    final first = Map<String, dynamic>.from(list.first as Map);
    _taskProviderLog(
      'tasksProvider: first item sample id=${first['id']} clientId=${first['clientId']} startDate=${first['startDate']} scheduledStartTime=${first['scheduledStartTime']} taskName=${first['taskName']}',
    );
  }

  return list;
});

final tasksByClientProvider = FutureProvider.family<List<dynamic>, int>(
  (ref, clientId) async {
    final storage = ref.read(secureStorageProvider);
    final employeeIdStr = await storage.readEmployeeId();
    final employeeId = int.tryParse(employeeIdStr ?? '');

    _taskProviderLog(
      'tasksByClientProvider: clientId=$clientId employeeIdStr=$employeeIdStr parsedEmployeeId=$employeeId',
    );

    if (employeeId == null) {
      return [];
    }

    _taskProviderLog(
      'tasksByClientProvider: fetching /tasks/client/$clientId/employee/$employeeId',
    );

    final list = await ref
        .read(taskRepositoryProvider)
        .getTasksForEmployeeAndClient(employeeId, clientId);

    _taskProviderLog(
      'tasksByClientProvider: received length=${list.length} for clientId=$clientId employeeId=$employeeId',
    );
    if (list.isNotEmpty && list.first is Map) {
      final first = Map<String, dynamic>.from(list.first as Map);
      _taskProviderLog(
        'tasksByClientProvider: first item sample id=${first['id']} clientId=${first['clientId']} startDate=${first['startDate']} scheduledStartTime=${first['scheduledStartTime']} taskName=${first['taskName']}',
      );
      _taskProviderLog('tasksByClientProvider: first item keys=${first.keys.toList()}');
    }

    return list;
  },
);

// Phase-5: Task animation state provider
final taskAnimationProvider =
    StateNotifierProvider<TaskAnimationNotifier, Map<String, String>>((ref) {
      return TaskAnimationNotifier();
    });

class TaskAnimationNotifier extends StateNotifier<Map<String, String>> {
  TaskAnimationNotifier() : super({});

  void triggerAnimation(String taskId, String animationType) {
    state = {...state, taskId: animationType};

    // Remove animation after completion
    Future.delayed(const Duration(milliseconds: 500), () {
      final newState = Map<String, String>.from(state);
      newState.remove(taskId);
      state = newState;
    });
  }
}

class TaskWithDistance {
  final Map<String, dynamic> task;
  final Map<String, dynamic>? customerAddress;
  final double? distanceToCustomer;
  final bool isLoadingAddress;
  final DateTime? lastCalculated; // Cache timestamp

  TaskWithDistance({
    required this.task,
    this.customerAddress,
    this.distanceToCustomer,
    this.isLoadingAddress = false,
    this.lastCalculated,
  });

  TaskWithDistance copyWith({
    Map<String, dynamic>? task,
    Map<String, dynamic>? customerAddress,
    double? distanceToCustomer,
    bool? isLoadingAddress,
    DateTime? lastCalculated,
  }) {
    return TaskWithDistance(
      task: task ?? this.task,
      customerAddress: customerAddress ?? this.customerAddress,
      distanceToCustomer: distanceToCustomer ?? this.distanceToCustomer,
      isLoadingAddress: isLoadingAddress ?? this.isLoadingAddress,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }

  bool get shouldRecalculate {
    if (lastCalculated == null) return true;
    return DateTime.now().difference(lastCalculated!).inMinutes >
        5; // 5-min cache
  }

  // Task validation method
  bool canUpdateTask() {
    if (distanceToCustomer == null) {
      return true; // Allow if no distance data
    }

    if (distanceToCustomer! > 200.0) {
      return false; // Block if >200m
    }

    return true; // Allow if ≤200m
  }
}

class TaskWithDistanceNotifier extends StateNotifier<List<TaskWithDistance>> {
  TaskWithDistanceNotifier(this._ref) : super([]);

  final Ref _ref;
  final Map<int, TaskWithDistance> _cache = {};

  Future<void> loadCustomerAddresses(List<Map<String, dynamic>> tasks) async {
    final taskRepo = _ref.read(taskRepositoryProvider);

    // Get current location from existing provider (if available)
    Position? currentPos;
    try {
      // Try to use existing location provider first
      final locationState = _ref.read(locationTrackingProvider);
      final currentPosition = locationState.currentPosition;

      if (currentPosition != null) {
        final latitude = currentPosition['latitude'] as double?;
        final longitude = currentPosition['longitude'] as double?;
        if (latitude != null && longitude != null) {
          currentPos = Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } catch (e) {
      // Fallback to direct GPS call if provider not available
      try {
        currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error getting current location: $e');
      }
    }

    final finalTasks = <TaskWithDistance>[];
    for (final task in tasks) {
      final taskId = task['id'];

      // Check cache first
      TaskWithDistance? cachedTask = _cache[taskId];

      if (cachedTask == null || cachedTask.shouldRecalculate) {
        // Fetch customer address
        final customerAddress = await taskRepo.getCustomerAddressForTask(
          taskId,
        );

        double? distance;
        if (currentPos != null && customerAddress != null) {
          final customerLat = customerAddress['latitude']?.toDouble();
          final customerLng = customerAddress['longitude']?.toDouble();

          if (customerLat != null && customerLng != null) {
            distance = DistanceCalculator.calculateDistance(
              currentPos.latitude,
              currentPos.longitude,
              customerLat,
              customerLng,
            );
          }
        }

        cachedTask = TaskWithDistance(
          task: task,
          customerAddress: customerAddress,
          distanceToCustomer: distance,
          isLoadingAddress: false,
          lastCalculated: DateTime.now(),
        );

        // Update cache
        _cache[taskId] = cachedTask;
      }

      finalTasks.add(cachedTask);
    }

    state = finalTasks;
  }

  // Update task status for real-time updates
  void updateTaskStatus(String taskId, String status) {
    final taskIndex = state.indexWhere(
      (taskWithDistance) => taskWithDistance.task['id']?.toString() == taskId,
    );

    if (taskIndex != -1) {
      final updatedTaskWithDistance = state[taskIndex].copyWith(
        task: Map<String, dynamic>.from(state[taskIndex].task)
          ..['status'] = status,
      );

      final newState = List<TaskWithDistance>.from(state);
      newState[taskIndex] = updatedTaskWithDistance;
      state = newState;
    }
  }

  // Handle real-time task status updates from WebSocket
  void handleTaskStatusUpdate(Map<String, dynamic> event) {
    final taskId = event['taskId']?.toString();
    final status = event['status']?.toString();

    if (taskId != null && status != null) {
      updateTaskStatus(taskId, status);
    }
  }
}

final tasksWithDistanceProvider =
    StateNotifierProvider<TaskWithDistanceNotifier, List<TaskWithDistance>>((
      ref,
    ) {
      return TaskWithDistanceNotifier(ref);
    });

// Real-time task update provider - PHASE-4 FIXED
final realTimeTaskNotifierProvider =
    StateNotifierProvider<RealTimeTaskNotifier, List<Map<String, dynamic>>>((
      ref,
    ) {
      return RealTimeTaskNotifier(ref);
    });

class RealTimeTaskNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  RealTimeTaskNotifier(this._ref) : super([]);

  final Ref _ref;
  bool _isListening = false;

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    // Primary: task status updates broadcast by backend on PUT /api/tasks/{id}/status
    _ref.listen(taskStatusUpdatesProvider, (previous, next) {
      next.when(
        data: (event) {
          final taskId = event['taskId']?.toString();
          final status = event['status']?.toString();
          if (taskId != null && status != null) {
            _ref
                .read(tasksWithDistanceProvider.notifier)
                .updateTaskStatus(taskId, status);
            _ref
                .read(taskAnimationProvider.notifier)
                .triggerAnimation(taskId, 'status_change');
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  @override
  void dispose() {
    _isListening = false;
    super.dispose();
  }
}
