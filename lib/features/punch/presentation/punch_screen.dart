import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:yashenterprisesapp/features/punch/presentation/providers/punch_providers.dart';

import '../../attendance/presentation/providers/attendance_providers.dart';
import '../../attendance/presentation/providers/working_timer_provider.dart';
import '../../../core/utils/time_format.dart';

class PunchScreen extends ConsumerStatefulWidget {
  const PunchScreen({super.key});

  @override
  ConsumerState<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends ConsumerState<PunchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handlePunchIn() async {
    HapticFeedback.lightImpact();
    await _scaleController.forward();
    try {
      await ref.read(punchControllerProvider.notifier).punchIn();
      await _scaleController.reverse();
      _showSuccessToast('Punched In Successfully!');
    } catch (e) {
      await _scaleController.reverse();
      _showErrorToast(e.toString().replaceAll('Exception: ', '').trim());
    }
  }

  Future<void> _handlePunchOut() async {
    HapticFeedback.heavyImpact();
    await _scaleController.forward();
    await ref.read(punchControllerProvider.notifier).punchOut();
    await _scaleController.reverse();
    _showSuccessToast('Punched Out Successfully!');
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final punchState = ref.watch(punchControllerProvider);
    final animationType = ref.watch(punchAnimationProvider);
    final cs = Theme.of(context).colorScheme;

    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    final workingTimer = ref.watch(workingTimerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Punch In/Out',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(punchState.isPunchedIn),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: punchState.isPunchedIn
                                  ? Colors.green.shade500
                                  : Colors.red.shade500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            punchState.isPunchedIn
                                ? 'Punched In'
                                : 'Punched Out',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: punchState.isPunchedIn
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last updated: ${DateTime.now().toString().substring(11, 16)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Punch Button
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseController,
                  _scaleController,
                ]),
                builder: (context, child) {
                  final isActionAnim =
                      animationType == 'punch_in' ||
                      animationType == 'punch_out';
                  final pulse = isActionAnim ? 1.0 : _pulseAnimation.value;
                  final scale = pulse * _scaleAnimation.value;
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: punchState.isPunchedIn
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: punchState.isPunchedIn
                                ? Colors.red.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: cs.primary.withOpacity(
                              punchState.isPunchedIn ? 0.08 : 0.06,
                            ),
                            blurRadius: 36,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: punchState.isPunchedIn
                              ? _handlePunchOut
                              : _handlePunchIn,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    punchState.isPunchedIn
                                        ? Icons.logout_rounded
                                        : Icons.login_rounded,
                                    key: ValueKey(punchState.isPunchedIn),
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    punchState.isPunchedIn
                                        ? 'Punch Out'
                                        : 'Punch In',
                                    key: ValueKey(punchState.isPunchedIn),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              // Info Cards
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Total Hours Today',
                      workingTimer.running
                          ? formatHms(workingTimer.elapsed)
                          : todayAttendanceAsync.when(
                              data: (today) {
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
                              },
                              loading: () => '...',
                              error: (e, _) => '00:00:00',
                            ),
                      Icons.access_time,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      'This Week',
                      '42h 15m',
                      Icons.date_range,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
