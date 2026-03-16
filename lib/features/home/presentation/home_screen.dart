import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../app/router/route_names.dart';
import '../../../core/notifications/notifications_providers.dart';
import '../../../core/notifications/fcm_providers.dart';
import '../../../core/utils/time_format.dart';
import '../../auth/presentation/providers/session_provider.dart';
import '../../attendance/presentation/providers/attendance_providers.dart';
import '../../attendance/presentation/providers/working_timer_provider.dart';
import '../../punch/presentation/providers/punch_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _getFcmToken();
  }

  Future<void> _getFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> _logout() async {
    // Clear session and navigate to login
    await ref.read(sessionProvider.notifier).logout();
    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final punch = ref.watch(punchControllerProvider);
    final unread = ref.watch(notificationsControllerProvider).unreadCount;
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    final workingTimer = ref.watch(workingTimerProvider);
    ref.watch(attendanceAutoRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.notifications),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          IconButton(
            onPressed: () async {
              try {
                await ref.read(fcmTokenSyncProvider).sync();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('FCM Token synced successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('FCM sync failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.sync),
            tooltip: 'Sync FCM Token',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 280,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(18.5204, 73.8567),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // FCM Token Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'FCM Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _getFcmToken,
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh Token',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_fcmToken != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Loading FCM Token...',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6BFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Punch in to start work',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          punch.isPunchedIn
                              ? 'You are punched in'
                              : 'Never punched in before',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: punch.loading
                              ? null
                              : () => ref
                                    .read(punchControllerProvider.notifier)
                                    .punchOut(),
                          child: Container(
                            height: 46,
                            width: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: punch.isPunchedIn
                                  ? Colors.transparent
                                  : const Color(0xFFFF6A5E),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'OUT',
                              style: TextStyle(
                                color: punch.isPunchedIn
                                    ? Colors.black54
                                    : Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: punch.loading
                              ? null
                              : () => ref
                                    .read(punchControllerProvider.notifier)
                                    .punchIn(),
                          child: Container(
                            height: 46,
                            width: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: punch.isPunchedIn
                                  ? const Color(0xFF2ECC71) // GREEN
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'IN',
                              style: TextStyle(
                                color: punch.isPunchedIn
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Today's Status",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateTime.now().toString().substring(0, 10),
                      style: TextStyle(color: Colors.black.withOpacity(0.55)),
                    ),
                    const SizedBox(height: 12),
                    todayAttendanceAsync.when(
                      data: (today) {
                        final status =
                            (today?['status']?.toString() ?? 'ABSENT');
                        final km = today?['totalKm'];

                        final totalHoursText = workingTimer.running
                            ? formatHms(workingTimer.elapsed)
                            : (() {
                                final hoursRaw = today?['totalHours'];
                                final hours = hoursRaw is num
                                    ? hoursRaw.toDouble()
                                    : double.tryParse(
                                            hoursRaw?.toString() ?? '0',
                                          ) ??
                                          0;
                                final totalMinutes = (hours * 60).round();
                                return formatHms(
                                  Duration(minutes: totalMinutes),
                                );
                              })();

                        final kmText = km == null
                            ? '0.0 Km'
                            : (km is num
                                  ? '${km.toStringAsFixed(1)} Km'
                                  : '${double.tryParse(km.toString())?.toStringAsFixed(1) ?? '0.0'} Km');

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.calendar_today,
                                    title: status,
                                    subtitle: '',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.timer_outlined,
                                    title: totalHoursText,
                                    subtitle: 'Total hrs.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.route,
                                    title: kmText,
                                    subtitle: 'GPS',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.phone_android,
                                    title: punch.isPunchedIn
                                        ? 'Tracking'
                                        : 'Idle',
                                    subtitle: 'App setup',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.calendar_today,
                                    title: '...',
                                    subtitle: '',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.timer_outlined,
                                    title: '...',
                                    subtitle: 'Total hrs.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.route,
                                    title: '...',
                                    subtitle: 'GPS',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.phone_android,
                                    title: '...',
                                    subtitle: 'App setup',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      error: (e, _) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.calendar_today,
                                    title: 'Error',
                                    subtitle: '',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.timer_outlined,
                                    title: '00:00:00',
                                    subtitle: 'Total hrs.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.route,
                                    title: '0.0 Km',
                                    subtitle: 'GPS',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusTile(
                                    icon: Icons.phone_android,
                                    title: 'N/A',
                                    subtitle: 'App setup',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2F6BFF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
