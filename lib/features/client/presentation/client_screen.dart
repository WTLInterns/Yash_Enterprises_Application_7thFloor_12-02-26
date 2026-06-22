import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/client_providers.dart';
import '../../task/presentation/task_screen.dart';

const bool _clientScreenLogs = true;

void _clientScreenLog(String message) {
  if (!_clientScreenLogs) return;
  print('[ClientScreen] $message');
}

class ClientScreen extends ConsumerStatefulWidget {
  const ClientScreen({super.key});

  @override
  ConsumerState<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends ConsumerState<ClientScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientScreenLog('initState');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final clientsAsync = ref.watch(assignedClientsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Center(child: Text('Assigned Clients')),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8),
        //     child: Row(
        //       children: [
        //         InkWell(
        //           onTap: () {
        //             ref.invalidate(clientsProvider);
        //             ref.invalidate(sitesProvider);
        //           },
        //           borderRadius: BorderRadius.circular(999),
        //           child: Container(
        //             height: 36,
        //             width: 36,
        //             decoration: BoxDecoration(
        //               color: cs.primary,
        //               borderRadius: BorderRadius.circular(999),
        //             ),
        //             child: const Icon(Icons.list_alt, color: Colors.white, size: 20),
        //           ),
        //         ),
        //         const SizedBox(width: 10),
        //         InkWell(
        //           onTap: () {},
        //           borderRadius: BorderRadius.circular(999),
        //           child: Container(
        //             height: 36,
        //             width: 36,
        //             decoration: BoxDecoration(
        //               color: Colors.black,
        //               borderRadius: BorderRadius.circular(999),
        //             ),
        //             child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.tune, color: cs.primary),
                  ),
                ),
              ],
            ),
            Expanded(child: _asyncList(cs, clientsAsync: clientsAsync)),
          ],
        ),
      ),
    );
  }

  Widget _asyncList(
    ColorScheme cs, {
    required AsyncValue<List<dynamic>> clientsAsync,
  }) {
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load')),
      data: (items) {
        final q = _search.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? items
            : items.where((e) {
                final m = e is Map
                    ? Map<String, dynamic>.from(e as Map)
                    : <String, dynamic>{};
                final name = _str(m, [
                  'name',
                  'clientName',
                  'siteName',
                  'title',
                ]);
                final addr = _str(m, [
                  'address',
                  'location',
                  'city',
                  'billingAddress',
                  'shippingAddress',
                ]);
                final phone = _str(m, [
                  'phone',
                  'mobile',
                  'contactNumber',
                  'phoneNumber',
                ]);
                return (name + addr + phone).toLowerCase().contains(q);
              }).toList();

        _clientScreenLog(
          'items=${items.length} filtered=${filtered.length} query="${_search.text}"',
        );

        if (items.isEmpty) {
          return const Center(child: Text('No assigned clients'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _clientScreenLog('refresh: invalidating assignedClientsProvider');
            ref.invalidate(assignedClientsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 6),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final raw = filtered[i];
              final m = raw is Map
                  ? Map<String, dynamic>.from(raw as Map)
                  : <String, dynamic>{};
              final clientIdRaw = m['id'];
              final clientId = clientIdRaw is int
                  ? clientIdRaw
                  : (clientIdRaw is num ? clientIdRaw.toInt() : null);
              final name = _str(m, [
                'name',
                'clientName',
                'siteName',
                'title',
              ], fallback: '—');
              final addr = _str(m, [
                'address',
                'location',
                'city',
                'billingAddress',
                'shippingAddress',
              ], fallback: '');
              final phone = _str(m, [
                'phone',
                'mobile',
                'contactNumber',
                'phoneNumber',
              ], fallback: '');

              return InkWell(
                onTap: clientId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskScreen(clientId: clientId),
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_outlined, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (addr.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      addr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.65),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.call, size: 18, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _str(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return fallback;
  }
}
