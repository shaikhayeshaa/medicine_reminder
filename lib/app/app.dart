import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import '../features/reminder/presentation/provider/notification_action_controller.dart';
import 'router.dart';

class MedicineReminderApp extends ConsumerStatefulWidget {
  const MedicineReminderApp({super.key});

  @override
  ConsumerState<MedicineReminderApp> createState() =>
      _MedicineReminderAppState();
}

class _MedicineReminderAppState extends ConsumerState<MedicineReminderApp> {
  StreamSubscription<String>? _notificationTapSubscription;

  StreamSubscription<NotificationActionEvent>? _notificationActionSubscription;

  String? _lastHandledPayload;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();

    _listenForNotificationTaps();
    _listenForNotificationActions();

    // Cold-start notification ko first frame ke baad handle karo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
      _handleInitialAction();
    });
  }

  // NORMAL NOTIFICATION TAP

  void _listenForNotificationTaps() {
    _notificationTapSubscription = NotificationService
        .instance
        .notificationTapStream
        .listen(_openReminderFromNotification);
  }

  // NOTIFICATION ACTIONS
  // Taken / Snooze / Skip

  void _listenForNotificationActions() {
    _notificationActionSubscription = NotificationService
        .instance
        .notificationActionStream
        .listen(_handleNotificationAction);
  }

  // COLD START - NORMAL NOTIFICATION TAP

  void _handleInitialNotification() {
    final payload = NotificationService.instance.takeInitialPayload();

    if (payload == null || payload.isEmpty) {
      return;
    }

    _openReminderFromNotification(payload);
  }

  // COLD START - NOTIFICATION ACTION

  void _handleInitialAction() {
    final action = NotificationService.instance.takeInitialAction();

    if (action == null) {
      return;
    }

    unawaited(_handleNotificationAction(action));
  }

  // HANDLE TAKEN / SKIP / SNOOZE

   Future<void> _handleNotificationAction(NotificationActionEvent event) async {
    // Taken, Skip and Snooze are all handled by
    // the dedicated Riverpod business controller.
    await ref
        .read(notificationActionControllerProvider.notifier)
        .handleAction(event);
  }

  // OPEN REMINDER PAGE

  void _openReminderFromNotification(String occurrenceId) {
    final cleanedId = occurrenceId.trim();

    if (cleanedId.isEmpty) {
      return;
    }

    // Same callback accidentally multiple times aaye
    // to duplicate Reminder pages open na hon.
    final now = DateTime.now();

    final isDuplicate =
        _lastHandledPayload == cleanedId &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 1);

    if (isDuplicate) {
      return;
    }

    _lastHandledPayload = cleanedId;
    _lastHandledAt = now;

    unawaited(appRouter.push(AppRoutes.reminderPath(cleanedId)));
  }

  // DISPOSE STREAMS

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    _notificationActionSubscription?.cancel();

    super.dispose();
  }

  // APP

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',
      routerConfig: appRouter,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    );
  }
}
