import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/location/robust_location_provider.dart';
import '../../../core/location/robustbg_location_service.dart';

class RobustLocationScreen extends ConsumerStatefulWidget {
  const RobustLocationScreen({super.key});

  @override
  ConsumerState<RobustLocationScreen> createState() =>
      _RobustLocationScreenState();
}

class _RobustLocationScreenState extends ConsumerState<RobustLocationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize robust location tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(robustLocationTrackingProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(robustLocationTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robust Location Tracking'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(robustLocationTrackingProvider.notifier).updateStatus();
            },
          ),
        ],
      ),
      body: locationState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Initializing robust tracking...'),
                ],
              ),
            )
          : locationState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${locationState.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(robustLocationTrackingProvider.notifier)
                          .clearError();
                      ref
                          .read(robustLocationTrackingProvider.notifier)
                          .initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                locationState.isTracking
                                    ? Icons.location_on
                                    : Icons.location_off,
                                color: locationState.isTracking
                                    ? Colors.red
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Robust Tracking Status',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locationState.isTracking
                                ? '🚀 ROBUST TRACKING ACTIVE'
                                : '⏸️ Tracking inactive',
                            style: TextStyle(
                              color: locationState.isTracking
                                  ? Colors.red
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Method: ${locationState.trackingMethod}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (locationState.consecutiveFailures > 0)
                            Text(
                              'Failures: ${locationState.consecutiveFailures}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: locationState.isTracking
                                      ? null
                                      : () async {
                                          await ref
                                              .read(
                                                robustLocationTrackingProvider
                                                    .notifier,
                                              )
                                              .startTracking();
                                        },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Robust Tracking'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: locationState.isTracking
                                      ? () async {
                                          await ref
                                              .read(
                                                robustLocationTrackingProvider
                                                    .notifier,
                                              )
                                              .stopTracking();
                                        }
                                      : null,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📍 Test Location Button
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧪 Test Location',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final position =
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );
                                print(
                                  '🧪 Manual location test: ${position.latitude}, ${position.longitude}',
                                );

                                // Send to server
                                await RobustBgLocationService.instance.tick(
                                  trigger: RobustBgTickTrigger.manual,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Location sent to server!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                print('❌ Manual location test failed: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('Send Location Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Robust Features Card
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛡️ Robust Features',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const RobustFeatureItem(
                            icon: Icons.phone_android,
                            title: 'Works when app removed from recent tabs',
                            description:
                                'Continues tracking even when app is closed',
                            color: Colors.green,
                          ),
                          const RobustFeatureItem(
                            icon: Icons.lock,
                            title: 'Works when phone is locked',
                            description:
                                'Background service runs with screen off',
                            color: Colors.green,
                          ),
                          const RobustFeatureItem(
                            icon: Icons.power_settings_new,
                            title: 'Works until phone is switched off',
                            description:
                                'Persistent tracking with auto-restart',
                            color: Colors.green,
                          ),
                          const RobustFeatureItem(
                            icon: Icons.timer,
                            title: '2-minute updates',
                            description:
                                'Frequent location updates for accuracy',
                            color: Colors.blue,
                          ),
                          const RobustFeatureItem(
                            icon: Icons.cloud_upload,
                            title: 'Multiple sync methods',
                            description:
                                'Background service + Background fetch + Firebase',
                            color: Colors.blue,
                          ),
                          const RobustFeatureItem(
                            icon: Icons.notifications_active,
                            title: 'Idle detection',
                            description:
                                'Alerts when employee is idle for 15+ minutes',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Location Card
                  if (locationState.lastKnownPosition != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📍 Current Location',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Latitude: ${locationState.lastKnownPosition!['latitude']?.toStringAsFixed(6)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              'Longitude: ${locationState.lastKnownPosition!['longitude']?.toStringAsFixed(6)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            if (locationState.lastKnownPosition!['speed'] !=
                                null)
                              Text(
                                'Speed: ${(locationState.lastKnownPosition!['speed'] as double).toStringAsFixed(2)} m/s',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            if (locationState.lastKnownPosition!['heading'] !=
                                null)
                              Text(
                                'Heading: ${(locationState.lastKnownPosition!['heading'] as double).toStringAsFixed(0)}°',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            if (locationState.lastKnownPosition!['accuracy'] !=
                                null)
                              Text(
                                'Accuracy: ±${(locationState.lastKnownPosition!['accuracy'] as double).toStringAsFixed(0)}m',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            if (locationState.lastUpdateTime != null)
                              Text(
                                'Last Update: ${locationState.lastUpdateTime}',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Permissions Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔐 Permissions Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder(
                            future: _checkPermissions(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final permissions = snapshot.data!;
                                return Column(
                                  children: [
                                    PermissionItem(
                                      title: 'Location',
                                      granted: permissions['location'] ?? false,
                                    ),
                                    PermissionItem(
                                      title: 'Background Location',
                                      granted:
                                          permissions['backgroundLocation'] ??
                                          false,
                                    ),
                                    PermissionItem(
                                      title: 'Notifications',
                                      granted:
                                          permissions['notification'] ?? false,
                                    ),
                                    PermissionItem(
                                      title: 'Battery Optimization',
                                      granted: permissions['battery'] ?? false,
                                    ),
                                    PermissionItem(
                                      title: 'System Alert',
                                      granted:
                                          permissions['systemAlert'] ?? false,
                                    ),
                                  ],
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Instructions',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Grant all permissions for robust tracking\n'
                            '2. Start tracking to enable background service\n'
                            '3. Tracking continues even when app is closed\n'
                            '4. Location updates every 2 minutes\n'
                            '5. Idle alerts sent after 15 minutes of inactivity\n'
                            '6. Works until phone is switched off',
                            style: TextStyle(fontSize: 14),
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

  Future<Map<String, bool>> _checkPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'backgroundLocation': await Permission.locationAlways.isGranted,
      'notification': await Permission.notification.isGranted,
      'battery': await Permission.ignoreBatteryOptimizations.isGranted,
      'systemAlert': await Permission.systemAlertWindow.isGranted,
    };
  }
}

class RobustFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const RobustFeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionItem extends StatelessWidget {
  final String title;
  final bool granted;

  const PermissionItem({super.key, required this.title, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.error,
            color: granted ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: granted ? Colors.black : Colors.grey,
            ),
          ),
          if (!granted) ...[
            const SizedBox(width: 8),
            const Text(
              '(Required)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
