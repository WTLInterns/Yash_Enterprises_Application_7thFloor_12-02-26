import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../address/presentation/address_edit_request_screen.dart';
import 'providers/task_providers.dart';
import '../data/repository/task_repository.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/location/simple_location_service.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _search = TextEditingController();
  bool _isListeningStarted = false;

  @override
  void initState() {
    super.initState();
    ref.read(tasksProvider.future).then((items) {
      final tasksList = items.cast<Map<String, dynamic>>();
      ref.read(tasksWithDistanceProvider.notifier).loadCustomerAddresses(tasksList);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isListeningStarted) {
        _isListeningStarted = true;
        ref.read(realTimeTaskNotifierProvider.notifier).startListening();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _navigateToAddressEdit(BuildContext context, TaskWithDistance taskWithDistance) {
    final address = taskWithDistance.customerAddress;
    
    // Safe navigation with null checks
    if (address == null || address['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer address not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressEditRequestScreen(
          addressId: address['id'] as int,
          currentAddress: address['address'] ?? '',
          currentLatitude: (address['latitude'] ?? 0).toDouble(),
          currentLongitude: (address['longitude'] ?? 0).toDouble(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Task'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.list_alt, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'task_screen_fab',
        onPressed: () {},
        backgroundColor: cs.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign, color: cs.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'How to Edit/Add Clients [Updated] -\nWatch Quick Video Guide.',
                      style: TextStyle(color: Color(0xFF2F6FED), fontWeight: FontWeight.w600, height: 1.15),
                    ),
                  ),
                  const Icon(Icons.play_circle_outline, color: Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 6),
                const Text('Today', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: const Text('1 Task', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                _iconBtn(Icons.tune),
                const SizedBox(width: 10),
                _iconBtn(Icons.refresh, onTap: () => ref.read(realTimeTaskNotifierProvider.notifier).startListening())
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: 8),
                const Text('Desc', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(height: 18, width: 1, color: Colors.black.withOpacity(0.18)),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: tasksAsync.when(
                loading: () => _buildLoadingState(),
                error: (e, _) => _buildErrorState(e),
                data: (items) {
                  final tasksWithDistance = ref.watch(tasksWithDistanceProvider);
                  
                  final q = _search.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? tasksWithDistance
                      : tasksWithDistance.where((e) {
                          final title = (e.task['title'] ?? e.task['name'] ?? '').toString();
                          final client = (e.task['clientName'] ?? '').toString();
                          return (title + client).toLowerCase().contains(q);
                        }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final taskWithDistance = filtered[index];
                      final task = taskWithDistance.task;

                      final title = (task['title'] ?? task['name'] ?? 'Task').toString();
                      final assignedBy = (task['createdByEmployeeName'] ?? 'Admin Assigned').toString();
                      final status = (task['status'] ?? 'Pending').toString();
                      final date = (task['startDate'] ?? task['taskDate'] ?? '').toString();
                      final time = (task['startTime'] ?? '').toString();
                      final time2 = (task['endTime'] ?? '').toString();
                      final assignee = (task['assignedToEmployeeName'] ?? '').toString();

                      final statusBg = status.toLowerCase().contains('complete')
                          ? Colors.green.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.14);
                      final statusFg = status.toLowerCase().contains('complete')
                          ? Colors.green.shade700
                          : Colors.orange.shade800;

                      return AnimatedTaskCard(
                        taskWithDistance: taskWithDistance,
                        task: task,
                        title: title,
                        assignedBy: assignedBy,
                        status: status,
                        date: date,
                        time: time,
                        time2: time2,
                        assignee: assignee,
                        statusBg: statusBg,
                        statusFg: statusFg,
                        cs: cs,
                        onUpdateTask: () => _showUpdateTaskDialog(context, task),
                        onLocationRestriction: () => _showLocationRestrictionDialog(context, taskWithDistance),
                        onAddressEdit: () => _navigateToAddressEdit(context, taskWithDistance),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTaskSkeleton(),
        )),
      ],
    );
  }

  Widget _buildTaskSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSkeleton(width: 80, height: 24),
                const Spacer(),
                _buildSkeleton(width: 60, height: 20),
                const SizedBox(width: 8),
                _buildSkeleton(width: 40, height: 32),
              ],
            ),
            const SizedBox(height: 10),
            _buildSkeleton(width: 150, height: 20),
            const SizedBox(height: 10),
            _buildSkeleton(width: 100, height: 16),
            const SizedBox(height: 6),
            _buildSkeleton(width: 120, height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade100, Colors.grey.shade300],
            stops: [0.0, 0.5, 1.0],
            tileMode: TileMode.clamp,
          ).createShader(bounds);
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(realTimeTaskNotifierProvider.notifier).startListening(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final statusController = TextEditingController(text: task['status'] ?? 'INQUIRY');
    final titleController = TextEditingController(text: task['title'] ?? '');
    String selectedStatus = task['status'] ?? 'INQUIRY';
    
    // Backend enum values - must match exactly
    final statusOptions = [
      'INQUIRY',
      'IN_PROGRESS', 
      'COMPLETED',
      'DELAYED',
      'CANCELLED'
    ];
    
    // Ensure current status is in the list, add if not present
    if (!statusOptions.contains(selectedStatus)) {
      statusOptions.add(selectedStatus);
    }
    
    showDialog(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: AlertDialog(
          title: Text('Update Task: ${task['title'] ?? ''}'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
              try {
                // Get current employee ID from session
                final storage = ref.read(secureSessionStorageProvider);
                final employeeIdStr = await storage.readEmployeeId();
                final currentEmployeeId = employeeIdStr != null ? int.tryParse(employeeIdStr) ?? 1 : 1;
                
                // Get current location from existing provider
                final locationState = ref.read(locationTrackingProvider);
                final currentPosition = locationState.currentPosition;
                
                if (currentPosition == null) {
                  throw Exception('Location not available. Please enable GPS.');
                }
                
                final latitude = currentPosition['latitude'] as double?;
                final longitude = currentPosition['longitude'] as double?;
                
                if (latitude == null || longitude == null) {
                  throw Exception('Invalid location data.');
                }
                
                await ref.read(taskRepositoryProvider).updateTaskStatus(
                  task['id'],
                  selectedStatus,
                  currentEmployeeId,
                  latitude: latitude,
                  longitude: longitude,
                );
                
                // Refresh tasks
                await ref.read(tasksProvider.future);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task status updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = 'Failed to update task';
                  
                  // Handle backend location restriction error
                  if (e.toString().contains('LOCATION_RESTRICTION')) {
                    errorMessage = 'Task update blocked - You are outside the 200m customer area';
                  } else if (e.toString().contains('MISSING_LOCATION')) {
                    errorMessage = 'Location information required for task update';
                  } else if (e.toString().contains('Location not available')) {
                    errorMessage = 'GPS location required. Please enable location services.';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
        ),
      ),
    );
  }

  void _showLocationRestrictionDialog(BuildContext context, TaskWithDistance taskWithDistance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Restriction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You must be within 200m of the customer location to update this task.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current distance: ${DistanceCalculator.formatDistance(taskWithDistance.distanceToCustomer!)} from customer',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please move closer to the customer location and try again.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: IconButton(onPressed: onTap ?? () {}, icon: Icon(icon)),
    );
  }
}

class AnimatedTaskCard extends ConsumerWidget {
  const AnimatedTaskCard({
    super.key,
    required this.taskWithDistance,
    required this.task,
    required this.title,
    required this.assignedBy,
    required this.status,
    required this.date,
    required this.time,
    required this.time2,
    required this.assignee,
    required this.statusBg,
    required this.statusFg,
    required this.cs,
    required this.onUpdateTask,
    required this.onLocationRestriction,
    required this.onAddressEdit,
  });

  final TaskWithDistance taskWithDistance;
  final Map<String, dynamic> task;
  final String title;
  final String assignedBy;
  final String status;
  final String date;
  final String time;
  final String time2;
  final String assignee;
  final Color statusBg;
  final Color statusFg;
  final ColorScheme cs;
  final VoidCallback onUpdateTask;
  final VoidCallback onLocationRestriction;
  final VoidCallback onAddressEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskId = task['id']?.toString() ?? '';
    final animationType = ref.watch(taskAnimationProvider)[taskId];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..translate(animationType == 'status_change' ? 5.0 : 0.0, 0.0, 0.0),
      child: Card(
        color: Colors.white,
        elevation: animationType == 'status_change' ? 8 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: animationType == 'status_change' 
                ? cs.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            width: animationType == 'status_change' ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(assignedBy, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  // Distance display with animation
                  if (taskWithDistance.isLoadingAddress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const SizedBox(
                        width: 60,
                        height: 16,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                  else if (taskWithDistance.distanceToCustomer != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: taskWithDistance.distanceToCustomer! <= 200 
                              ? [Colors.green.shade50, Colors.green.shade100]
                              : [Colors.red.shade50, Colors.red.shade100],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: taskWithDistance.distanceToCustomer! <= 200 
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: taskWithDistance.distanceToCustomer! <= 200 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              taskWithDistance.distanceToCustomer! <= 200 
                                  ? Icons.location_on_rounded
                                  : Icons.location_off_rounded,
                              key: ValueKey(taskWithDistance.distanceToCustomer! <= 200),
                              size: 18,
                              color: taskWithDistance.distanceToCustomer! <= 200 
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DistanceCalculator.formatDistance(taskWithDistance.distanceToCustomer!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: taskWithDistance.distanceToCustomer! <= 200 
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              Text(
                                taskWithDistance.distanceToCustomer! <= 200 
                                    ? 'In Range'
                                    : 'Out of Range',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: taskWithDistance.distanceToCustomer! <= 200 
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Animated update button
                  if (task['id'] != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: taskWithDistance.canUpdateTask() 
                            ? onUpdateTask
                            : onLocationRestriction,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.edit,
                            key: ValueKey(taskWithDistance.canUpdateTask()),
                            color: taskWithDistance.canUpdateTask() 
                                ? Color(0xFF2F6BFF) 
                                : Colors.grey,
                          ),
                        ),
                        tooltip: taskWithDistance.canUpdateTask() 
                            ? 'Update Task' 
                            : 'Outside customer area - Cannot update',
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Animated status badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        style: TextStyle(color: statusFg, fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              if (date.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(date),
                  ],
                ),
              if (time.isNotEmpty || time2.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text(time2.isNotEmpty ? '$time – $time2' : time),
                  ],
                ),
              ],
              if (assignee.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(assignee),
                  ],
                ),
              ],
              // Customer address display with animation
              if (taskWithDistance.customerAddress != null) ...[
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.indigo.shade50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.store, size: 16, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Location',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              taskWithDistance.customerAddress!['address'] ?? 'Customer Location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Request Address Change button
              if (taskWithDistance.customerAddress != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      final address = taskWithDistance.customerAddress;
                        
                      // Safe navigation with null checks
                      if (address == null || address['id'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer address not available')),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressEditRequestScreen(
                            addressId: address['id'] as int,
                            currentAddress: address['address'] ?? '',
                            currentLatitude: (address['latitude'] ?? 0).toDouble(),
                            currentLongitude: (address['longitude'] ?? 0).toDouble(),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_location, size: 18, color: Colors.orange.shade600),
                    label: Text(
                      'Request Address Change',
                      style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      backgroundColor: Colors.orange.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                  ),
                ),
              ],
              if (taskWithDistance.distanceToCustomer != null) ...[
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: taskWithDistance.distanceToCustomer! <= 200 
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.orange.shade50, Colors.amber.shade50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: taskWithDistance.distanceToCustomer! <= 200 
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: taskWithDistance.distanceToCustomer! <= 200 
                            ? Colors.green.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          taskWithDistance.distanceToCustomer! <= 200 
                              ? Icons.check_circle_rounded
                              : Icons.info_rounded,
                          key: ValueKey(taskWithDistance.distanceToCustomer! <= 200),
                          size: 20,
                          color: taskWithDistance.distanceToCustomer! <= 200 
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            taskWithDistance.distanceToCustomer! <= 200 
                                ? '✨ You are at customer location'
                                : '📍 You are outside customer area',
                            key: ValueKey(taskWithDistance.distanceToCustomer! <= 200),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: taskWithDistance.distanceToCustomer! <= 200 
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
