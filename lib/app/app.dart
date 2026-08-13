import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/recovery/presentation/providers/app_recovery_provider.dart';
import '../features/reminder/presentation/provider/notification_action_controller.dart';
import 'router.dart';

class MedicineReminderApp extends ConsumerStatefulWidget {
  const MedicineReminderApp({super.key});

  @override
  ConsumerState<MedicineReminderApp> createState() =>
      _MedicineReminderAppState();
}

class _MedicineReminderAppState extends ConsumerState<MedicineReminderApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationTapSubscription;
  StreamSubscription<NotificationActionEvent>? _notificationActionSubscription;

  String? _lastHandledPayload;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _listenForNotificationTaps();
    _listenForNotificationActions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
      _handleInitialAction();

      // Repair missed statuses, rolling occurrences and notification queue
      // after Hive + notification plugin initialization has completed.
      unawaited(
        ref.read(appRecoveryControllerProvider.notifier).recover(force: true),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    // Returning from background is another opportunity to reconcile doses
    // whose reminder time passed while Flutter was not running.
    unawaited(ref.read(appRecoveryControllerProvider.notifier).recover());
  }

  void _listenForNotificationTaps() {
    _notificationTapSubscription = NotificationService
        .instance
        .notificationTapStream
        .listen(_openReminderFromNotification);
  }

  void _listenForNotificationActions() {
    _notificationActionSubscription = NotificationService
        .instance
        .notificationActionStream
        .listen(_handleNotificationAction);
  }

  void _handleInitialNotification() {
    final payload = NotificationService.instance.takeInitialPayload();

    if (payload == null || payload.isEmpty) {
      return;
    }

    _openReminderFromNotification(payload);
  }

  void _handleInitialAction() {
    final action = NotificationService.instance.takeInitialAction();

    if (action == null) {
      return;
    }

    unawaited(_handleNotificationAction(action));
  }

  Future<void> _handleNotificationAction(NotificationActionEvent event) async {
    await ref
        .read(notificationActionControllerProvider.notifier)
        .handleAction(event);
  }

  void _openReminderFromNotification(String occurrenceId) {
    final cleanedId = occurrenceId.trim();

    if (cleanedId.isEmpty) {
      return;
    }

    // Some platforms can deliver both a launch response and a foreground
    // callback very close together. Avoid stacking the same page twice.
    final currentTime = DateTime.now();
    final isDuplicate =
        _lastHandledPayload == cleanedId &&
        _lastHandledAt != null &&
        currentTime.difference(_lastHandledAt!) < const Duration(seconds: 1);

    if (isDuplicate) {
      return;
    }

    _lastHandledPayload = cleanedId;
    _lastHandledAt = currentTime;

    unawaited(appRouter.push(AppRoutes.reminderPath(cleanedId)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTapSubscription?.cancel();
    _notificationActionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Meditrake',
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
    );
  }
}
