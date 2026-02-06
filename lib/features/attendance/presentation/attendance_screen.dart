import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Picker
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${_selectedDate.toString().substring(0, 10)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.edit_calendar),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Present', 'Absent', 'Leave', 'Half-day'].map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? cs.primary : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? cs.primary.withOpacity(0.6) : Colors.grey.shade300,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: cs.primary.withOpacity(0.22),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    child: Text(status),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Attendance List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceList('today'),
                _buildAttendanceList('week'),
                _buildAttendanceList('month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(String period) {
    // Mock data for demonstration
    final mockData = [
      {'name': 'John Doe', 'status': 'Present', 'time': '09:15 AM', 'avatar': 'JD'},
      {'name': 'Jane Smith', 'status': 'Absent', 'time': '-', 'avatar': 'JS'},
      {'name': 'Mike Johnson', 'status': 'Leave', 'time': '-', 'avatar': 'MJ'},
      {'name': 'Sarah Williams', 'status': 'Half-day', 'time': '02:30 PM', 'avatar': 'SW'},
      {'name': 'Tom Brown', 'status': 'Present', 'time': '08:45 AM', 'avatar': 'TB'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockData.length,
      itemBuilder: (context, index) {
        final employee = mockData[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildAttendanceCard(employee),
        );
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> employee) {
    final status = employee['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBgColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                employee['avatar'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Employee Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check-in: ${employee['time']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green.shade600;
      case 'Absent':
        return Colors.red.shade600;
      case 'Leave':
        return Colors.orange.shade600;
      case 'Half-day':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green.withOpacity(0.1);
      case 'Absent':
        return Colors.red.withOpacity(0.1);
      case 'Leave':
        return Colors.orange.withOpacity(0.1);
      case 'Half-day':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Leave':
        return Icons.event_busy;
      case 'Half-day':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }
}
