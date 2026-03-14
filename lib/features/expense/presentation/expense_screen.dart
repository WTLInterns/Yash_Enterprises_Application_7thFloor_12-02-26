import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import 'providers/expense_providers.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Expense'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Conveyance'),
            Tab(text: 'Advance'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addExpense),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                const Text('January 2026', style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Month'),
                      SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            expensesAsync.when(
              loading: () => const SizedBox(height: 70, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const SizedBox.shrink(),
              data: (items) {
                int pending = 0;
                int approved = 0;
                int rejected = 0;
                int paid = 0;
                for (final e in items) {
                  final m = e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{};
                  final s = (m['status'] ?? '').toString().toLowerCase();
                  if (s.contains('approve')) {
                    approved++;
                  } else if (s.contains('reject')) {
                    rejected++;
                  } else if (s.contains('paid')) {
                    paid++;
                  } else {
                    pending++;
                  }
                }

                return Row(
                  children: [
                    _counter('Pending', '$pending', Colors.grey),
                    const SizedBox(width: 10),
                    _counter('Approved', '$approved', Colors.green),
                    const SizedBox(width: 10),
                    _counter('Rejected', '$rejected', Colors.red),
                    const SizedBox(width: 10),
                    _counter('Paid out', '$paid', Colors.blue),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  expensesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Center(child: Text('Failed to load')),
                    data: (items) {
                      if (items.isEmpty) return const _EmptyState();

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final raw = items[i];
                          final m = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
                          final category = (m['category'] ?? 'Expense').toString();
                          final desc = (m['description'] ?? '').toString();
                          final date = (m['expenseDate'] ?? '').toString();
                          final time = (m['expenseTime'] ?? '').toString();
                          final amount = (m['amount'] ?? 0).toString();
                          final status = (m['status'] ?? 'Pending').toString();
                          final employeeName = (m['employeeName'] ?? '').toString();
                          final departmentName = (m['departmentName'] ?? '').toString();
                          final receiptUrl = (m['receiptUrl'] ?? '').toString();

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Category + Status
                                  Row(
                                    children: [
                                      Text(category, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      const Spacer(),
                                      Text(status, style: TextStyle(color: Colors.black.withOpacity(0.6))),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  /// Employee + Department
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 6),
                                      Text(employeeName.isEmpty ? 'Unknown Employee' : employeeName),
                                      const SizedBox(width: 10),
                                      Text(
                                        departmentName.isEmpty ? '(No Department)' : '($departmentName)',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),

                                  /// Description
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(desc, style: TextStyle(color: Colors.black.withOpacity(0.65))),
                                  ],

                                  const SizedBox(height: 8),

                                  /// Date + Time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 18),
                                      const SizedBox(width: 6),
                                      Text(date.isEmpty ? '-' : date),
                                      const SizedBox(width: 10),
                                      Text(time.isEmpty ? '' : time),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Amount
                                  Text(
                                    '₹ $amount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  /// Evidence Image/File
                                  if (receiptUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        "http://localhost:8080$receiptUrl",
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const _EmptyState(),
                  const _EmptyState(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counter(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.inbox_outlined, size: 36),
          ),
          const SizedBox(height: 12),
          const Text('List is Empty', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
