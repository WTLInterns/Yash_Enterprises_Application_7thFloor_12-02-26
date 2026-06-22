import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/leave_providers.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _reason = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  String _type = 'CASUAL';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applyLeaveControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Apply Leave')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _FieldCard(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'SICK', child: Text('Sick')),
                    DropdownMenuItem(value: 'CASUAL', child: Text('Casual')),
                    DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid')),
                  ],
                  onChanged: state.loading
                      ? null
                      : (v) => setState(() => _type = v ?? 'CASUAL'),
                  decoration: const InputDecoration(
                    labelText: 'Leave Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'From Date',
                icon: Icons.calendar_month,
                value: _from,
                enabled: !state.loading,
                onPick: (d) => setState(() => _from = d),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'To Date',
                icon: Icons.event,
                value: _to,
                enabled: !state.loading,
                onPick: (d) => setState(() => _to = d),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                child: TextField(
                  controller: _reason,
                  enabled: !state.loading,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () async {
                          if (_from == null || _to == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select dates')),
                            );
                            return;
                          }
                          await ref
                              .read(applyLeaveControllerProvider.notifier)
                              .submit(
                                leaveType: _type,
                                fromDate: _from!,
                                toDate: _to!,
                                reason: _reason.text.trim(),
                              );
                          final next = ref.read(applyLeaveControllerProvider);
                          if (next.error == null && mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: state.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';

    return _FieldCard(
      child: InkWell(
        onTap: enabled
            ? () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? now,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(2035, 12, 31),
                );
                if (picked != null) onPick(picked);
              }
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Select',
            prefixIcon: Icon(icon),
            enabled: enabled,
          ),
          child: Text(text.isEmpty ? 'Select' : text),
        ),
      ),
    );
  }
}
