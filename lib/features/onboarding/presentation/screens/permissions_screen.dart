import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/router/route_names.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _loading = false;

  Future<void> _request() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await Permission.locationWhenInUse.request();
      await Permission.locationAlways.request();

      if (mounted) context.go(RouteNames.login);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Background location',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We need background location permission in order to monitor your location while you are punched in and calculate your travel properly.',
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: _loading ? null : _request,
                      backgroundColor: cs.primary,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background location\npermission',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Click "Allow all the time" to allow UNOLO to run properly.',
                                style: TextStyle(height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'PROCEED',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
