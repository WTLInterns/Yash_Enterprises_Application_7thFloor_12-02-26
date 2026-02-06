import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _ExpenseItem {
  _ExpenseItem({required this.type, required this.amount, required this.remarks});

  String type;
  String amount;
  String remarks;
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _desc = TextEditingController();
  DateTime? _date;
  final List<_ExpenseItem> _items = [
    _ExpenseItem(type: 'Accommodation', amount: '', remarks: ''),
  ];

  File? _evidence;
  bool _submitting = false;

  double get total {
    double sum = 0;
    for (final i in _items) {
      sum += double.tryParse(i.amount.trim()) ?? 0;
    }
    return sum;
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _evidence = File(path));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _desc,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _date == null ? 'Select date' : '${_date!.day}/${_date!.month}/${_date!.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_month, color: cs.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Expense items', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: item.type,
                          items: const [
                            'Accommodation',
                            'DM Order',
                            'Meals',
                            'Others',
                            'Out Of Pocket',
                            'Traveling'
                          ]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => item.type = v ?? item.type),
                          decoration: const InputDecoration(labelText: 'Type'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: item.amount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount'),
                          onChanged: (v) => setState(() => item.amount = v),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: item.remarks,
                          decoration: const InputDecoration(labelText: 'Remarks (optional)'),
                          onChanged: (v) => setState(() => item.remarks = v),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() => _items.add(_ExpenseItem(type: 'Accommodation', amount: '', remarks: ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add another item'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Text('Total Expense', style: TextStyle(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('₹${total.toStringAsFixed(2)}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickEvidence,
                icon: const Icon(Icons.attach_file),
                label: Text(_evidence == null ? 'Add Evidence' : 'Evidence Selected'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final employeeIdRaw = await ref.read(secureSessionStorageProvider).readEmployeeId();
    final employeeId = int.tryParse(employeeIdRaw ?? '');
    if (employeeId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee not found. Please login again.')));
      return;
    }

    if (_date == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date')));
      return;
    }

    if (total <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'employeeId': employeeId,
        'amount': total,
        'category': _items.isNotEmpty ? _items.first.type : 'Expense',
        'description': _desc.text.trim(),
        'expenseDate': '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
        'status': 'PENDING',
      };

      final created = await ref.read(expenseRepositoryProvider).createExpense(payload);
      final createdId = created['id'] is num ? (created['id'] as num).toInt() : int.tryParse('${created['id']}');

      if (createdId != null && _evidence != null) {
        await ref.read(expenseRepositoryProvider).uploadEvidence(createdId, _evidence!.path);
      }

      ref.invalidate(expensesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit expense')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
