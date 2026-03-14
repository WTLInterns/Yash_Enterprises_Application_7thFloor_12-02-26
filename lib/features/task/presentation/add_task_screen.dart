import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../client/presentation/providers/client_providers.dart';
import 'providers/task_providers.dart';
import '../../../../core/network/dio_client.dart';

final employeesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/employees');
  return (res.data as List).cast();
});

final customerAddressesByClientProvider =
    FutureProvider.family<List<dynamic>, int>((ref, clientId) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get('/clients/$clientId/addresses');
      return (res.data as List).cast();
    });

class AddTaskScreen extends ConsumerStatefulWidget {
  final int? clientId;

  const AddTaskScreen({super.key, this.clientId});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _taskName = TextEditingController();
  final _taskDescription = TextEditingController();

  String _selectedStatus = 'INQUIRY';
  int? _selectedClientId;
  int? _selectedEmployeeId;
  int? _selectedAddressId;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
  }

  @override
  void dispose() {
    _taskName.dispose();
    _taskDescription.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final err = data['error']?.toString().trim();
        if (err != null && err.isNotEmpty) return err;
        final msg = data['message']?.toString().trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return 'Request failed (${e.response?.statusCode ?? 'unknown'})';
    }
    return e.toString();
  }

  Future<void> _submit() async {
    final taskName = _taskName.text.trim();
    final clientId = _selectedClientId;

    if (taskName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task name is required')));
      return;
    }

    if (clientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client is required')));
      return;
    }

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assigned employee is required')),
      );
      return;
    }

    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer address is required')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final payload = <String, dynamic>{
        'taskName': taskName,
        'status': _selectedStatus,
        'clientId': clientId,
        'assignedToEmployeeId': _selectedEmployeeId,
        'customerAddressId': _selectedAddressId,
        'taskAgainst': 'CLIENT',
      };

      final desc = _taskDescription.text.trim();
      if (desc.isNotEmpty) {
        payload['taskDescription'] = desc;
      }

      if (_startDate != null) {
        payload['startDate'] = _formatDate(_startDate);
      }
      if (_endDate != null) {
        payload['endDate'] = _formatDate(_endDate);
      }

      await ref.read(taskRepositoryProvider).createTask(payload);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    final addressesAsync = _selectedClientId == null
        ? const AsyncValue<List<dynamic>>.data([])
        : ref.watch(customerAddressesByClientProvider(_selectedClientId!));

    final statusOptions = const [
      'INQUIRY',
      'IN_PROGRESS',
      'COMPLETED',
      'DELAYED',
      'CANCELLED',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _taskName,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescription,
                decoration: const InputDecoration(
                  labelText: 'Task Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedStatus,
                    items: statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedStatus = v;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.clientId == null)
                clientsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => const Text('Failed to load clients'),
                  data: (items) {
                    final clients = items
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();

                    return InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Client',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedClientId,
                          items: clients
                              .map((c) {
                                final id = c['id'];
                                if (id is! int) return null;
                                final name =
                                    (c['name'] ??
                                            c['clientName'] ??
                                            'Client $id')
                                        .toString();
                                return DropdownMenuItem(
                                  value: id,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedClientId = v;
                              _selectedAddressId = null;
                            });
                          },
                        ),
                      ),
                    );
                  },
                )
              else
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(),
                  ),
                  child: Text('Client #${widget.clientId}'),
                ),
              const SizedBox(height: 12),
              employeesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => const Text('Failed to load employees'),
                data: (items) {
                  final employees = items
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Assign Employee',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedEmployeeId,
                        items: employees
                            .map((emp) {
                              final id = emp['id'];
                              if (id is! int) return null;
                              final first = (emp['firstName'] ?? '').toString();
                              final last = (emp['lastName'] ?? '').toString();
                              final name = (first + ' ' + last).trim();
                              return DropdownMenuItem(
                                value: id,
                                child: Text(
                                  name.isEmpty ? 'Employee #$id' : name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedEmployeeId = v;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              addressesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) =>
                    const Text('Failed to load customer addresses'),
                data: (items) {
                  final addresses = items
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Customer Address',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedAddressId,
                        items: addresses
                            .map((a) {
                              final id = a['id'];
                              if (id is! int) return null;
                              final type = (a['addressType'] ?? '').toString();
                              final line =
                                  (a['addressLine'] ?? a['address'] ?? '')
                                      .toString();
                              final city = (a['city'] ?? '').toString();
                              final label = [
                                type,
                                line,
                                city,
                              ].where((s) => s.trim().isNotEmpty).join(' - ');
                              return DropdownMenuItem(
                                value: id,
                                child: Text(
                                  label.isEmpty ? 'Address #$id' : label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedAddressId = v;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text('Start Date: ${_formatDate(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text('End Date: ${_formatDate(_endDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
