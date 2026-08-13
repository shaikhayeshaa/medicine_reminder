import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medicine_reminder/features/medicine/presentation/pages/edit_medicine_page.dart';
import 'package:medicine_reminder/features/medicine/presentation/pages/medicine_management_page.dart';
import 'package:medicine_reminder/features/reminder/presentation/pages/reminder_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/medicine/presentation/pages/add_medicine_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String addMedicine = '/add-medicine';

  static const String reminderRoute = '/reminder/:occurrenceId';
  static String reminderPath(String occurrenceId) {
    return '/reminder/${Uri.encodeComponent(occurrenceId)}';
  }

  static const String manageMedicines = '/medicines/manage';

  static const String editMedicineRoute = '/medicines/:medicineId/edit';

  static String editMedicinePath(String medicineId) {
    return '/medicines/'
        '${Uri.encodeComponent(medicineId)}'
        '/edit';
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final _dashboardNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'dashboard',
);

final _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');

final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.dashboard,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _dashboardNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) {
                return const DashboardPage();
              },
            ),
          ],
        ),

        StatefulShellBranch(
          navigatorKey: _historyNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, state) {
                return const HistoryPage();
              },
            ),
          ],
        ),

        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) {
                return const SettingsPage();
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.manageMedicines,
      builder: (context, state) {
        return const MedicineManagementPage();
      },
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.editMedicineRoute,
      builder: (context, state) {
        final medicineId = state.pathParameters['medicineId']!;

        return EditMedicinePage(medicineId: medicineId);
      },
    ),

    // Outside bottom navigation shell.
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.addMedicine,
      builder: (context, state) {
        return const AddMedicinePage();
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.reminderRoute,
      builder: (context, state) {
        final occurrenceId = state.pathParameters['occurrenceId']!;

        return ReminderPage(occurrenceId: occurrenceId);
      },
    ),
  ],
);
