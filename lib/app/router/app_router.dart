import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/language_screen.dart';
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
      // Only redirect if session is initialized
      if (!session.initialized) return null;

      final loggedIn = session.isLoggedIn;
      final goingToLogin = state.matchedLocation == RouteNames.login;
      final goingToOnboarding =
          // state.matchedLocation == RouteNames.language ||
          state.matchedLocation == RouteNames.permissions;

      if (!loggedIn) {
        // allow onboarding + login
        if (goingToOnboarding || goingToLogin) return null;
        return RouteNames.login;
      }

      // logged in
      if (goingToLogin || goingToOnboarding) return RouteNames.shell;
      return null;
    },
    routes: [
      // GoRoute(
      //   path: RouteNames.language,
      //   builder: (context, state) => const LanguageScreen(),
      // ),
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
