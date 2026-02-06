import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/fcm_runtime.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class UnoloApp extends ConsumerWidget {
  const UnoloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(fcmRuntimeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'UnoLo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
