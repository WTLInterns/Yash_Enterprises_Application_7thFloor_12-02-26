import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/location/simple_location_provider.dart';

class SimpleLocationScreen extends ConsumerStatefulWidget {
  const SimpleLocationScreen({super.key});

  @override
  ConsumerState<SimpleLocationScreen> createState() => _SimpleLocationScreenState();
}

class _SimpleLocationScreenState extends ConsumerState<SimpleLocationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize location tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simpleLocationTrackingProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(simpleLocationTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(simpleLocationTrackingProvider.notifier).updateStatus();
            },
          ),
        ],
      ),
      body: locationState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing location tracking...'),
                ],
              ),
            )
          : locationState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${locationState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(simpleLocationTrackingProvider.notifier).clearError();
                          ref.read(simpleLocationTrackingProvider.notifier).initialize();
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
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tracking Status',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                locationState.isTracking
                                    ? 'Location tracking is active'
                                    : 'Location tracking is inactive',
                                style: TextStyle(
                                  color: locationState.isTracking
                                      ? Colors.green
                                      : Colors.grey,
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
                                                  .read(simpleLocationTrackingProvider.notifier)
                                                  .startTracking();
                                            },
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Start Tracking'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: locationState.isTracking
                                          ? () async {
                                              await ref
                                                  .read(simpleLocationTrackingProvider.notifier)
                                                  .stopTracking();
                                            }
                                          : null,
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Stop Tracking'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
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

                      // Current Location Card
                      if (locationState.lastKnownPosition != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
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
                                if (locationState.lastKnownPosition!['speed'] != null)
                                  Text(
                                    'Speed: ${(locationState.lastKnownPosition!['speed'] as double).toStringAsFixed(2)} m/s',
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                if (locationState.lastKnownPosition!['heading'] != null)
                                  Text(
                                    'Heading: ${(locationState.lastKnownPosition!['heading'] as double).toStringAsFixed(0)}°',
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                if (locationState.lastKnownPosition!['accuracy'] != null)
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

                      // Features Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location Tracking Features',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const FeatureItem(
                                icon: Icons.location_on,
                                title: 'Real-time tracking',
                                description:
                                    'Updates location every 5 minutes',
                              ),
                              const FeatureItem(
                                icon: Icons.cloud_upload,
                                title: 'Server sync',
                                description:
                                    'Location data is synced to backend server',
                              ),
                              const FeatureItem(
                                icon: Icons.speed,
                                title: 'Movement tracking',
                                description:
                                    'Tracks speed and heading of employee',
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
                                'Permissions Status',
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
                                          title: 'Notifications',
                                          granted: permissions['notification'] ?? false,
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
                    ],
                  ),
                ),
    );
  }

  Future<Map<String, bool>> _checkPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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

  const PermissionItem({
    super.key,
    required this.title,
    required this.granted,
  });

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
        ],
      ),
    );
  }
}
