import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_screen.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/expense/presentation/screens/add_expense_screen.dart';
import '../../features/leave/presentation/screens/apply_leave_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: session,
    redirect: (context, state) {
      final initialized = session.initialized;
      final loggedIn = session.isLoggedIn;
      final location = state.matchedLocation;

      print(
        '📡 ROUTER: initialized=$initialized, loggedIn=$loggedIn, location=$location',
      );

      // Wait for session initialization
      if (!initialized) {
        print('📡 ROUTER: Waiting for session init...');
        return null;
      }

      final goingToLogin = location == RouteNames.login;
      final goingToOnboarding = location == RouteNames.permissions;
      // NOTE: protected routes are enforced via redirect rules below.

      // Not logged in - redirect to login
      if (!loggedIn) {
        if (goingToLogin || goingToOnboarding) {
          print('📡 ROUTER: Allowing access to public route');
          return null;
        }
        print('📡 ROUTER: Not logged in - redirecting to login');
        return RouteNames.login;
      }

      // Logged in - redirect away from login/onboarding
      if (goingToLogin || goingToOnboarding) {
        print('📡 ROUTER: Logged in - redirecting to shell');
        return RouteNames.shell;
      }

      print('📡 ROUTER: No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.addExpense,
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: RouteNames.applyLeave,
        builder: (context, state) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: RouteNames.shell,
        builder: (context, state) => const ShellScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
