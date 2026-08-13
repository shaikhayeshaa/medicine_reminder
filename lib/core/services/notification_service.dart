import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/medicine/domain/entities/dose_occurrence_entity.dart';
import '../constants/notification_constants.dart';

class NotificationActionEvent {
  final String occurrenceId;
  final String actionId;

  const NotificationActionEvent({
    required this.occurrenceId,
    required this.actionId,
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _notificationTapController =
      StreamController<String>.broadcast();
  final StreamController<NotificationActionEvent>
  _notificationActionController =
      StreamController<NotificationActionEvent>.broadcast();

  Stream<String> get notificationTapStream => _notificationTapController.stream;

  Stream<NotificationActionEvent> get notificationActionStream =>
      _notificationActionController.stream;

  String? _initialPayload;
  NotificationActionEvent? _initialAction;

  String? takeInitialPayload() {
    final payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }

  NotificationActionEvent? takeInitialAction() {
    final action = _initialAction;
    _initialAction = null;
    return action;
  }

  Future<void> initialize() async {
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          NotificationConstants.categoryId,
          actions: [
            DarwinNotificationAction.plain(
              NotificationConstants.takenActionId,
              'Taken',
              options: const {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationConstants.snoozeActionId,
              'Snooze',
              options: const {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationConstants.skipActionId,
              'Skip',
              options: const {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // A terminated app cannot receive the foreground callback. Preserve the
    // launch response and let MedicineReminderApp consume it after first frame.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp != true) {
      return;
    }

    final response = launchDetails?.notificationResponse;
    final payload = response?.payload?.trim();

    if (payload == null || payload.isEmpty) {
      return;
    }

    final actionId = response?.actionId;
    if (actionId == null || actionId.isEmpty) {
      _initialPayload = payload;
    } else {
      _initialAction = NotificationActionEvent(
        occurrenceId: payload,
        actionId: actionId,
      );
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();

    final timezone = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(timezone.identifier);
    tz.setLocalLocation(location);
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload?.trim();

    if (payload == null || payload.isEmpty) {
      return;
    }

    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) {
      _notificationTapController.add(payload);
      return;
    }

    _notificationActionController.add(
      NotificationActionEvent(occurrenceId: payload, actionId: actionId),
    );
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDoseReminder(
    DoseOccurrenceEntity occurrence, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    final scheduledAt = occurrence.snoozedUntil ?? occurrence.scheduledAt;

    // Never ask the OS to schedule an already expired reminder.
    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    final notificationId = _notificationIdForOccurrence(occurrence.id);
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);

    // Android 8+ stores sound/vibration on notification channels. A distinct
    // channel per preference combination allows future settings to take effect.
    final dynamicChannelId =
        '${NotificationConstants.channelId}_${soundId}_'
        '${vibrationEnabled ? 'vibration' : 'no_vibration'}';

    final androidDetails = AndroidNotificationDetails(
      dynamicChannelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      sound: RawResourceAndroidNotificationSound(soundId),
      playSound: true,
      enableVibration: vibrationEnabled,
      actions: const [
        AndroidNotificationAction(
          NotificationConstants.takenActionId,
          'Taken',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          NotificationConstants.snoozeActionId,
          'Snooze',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          NotificationConstants.skipActionId,
          'Skip',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$soundId.wav',
      categoryIdentifier: NotificationConstants.categoryId,
    );

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact = await androidPlugin
        ?.canScheduleExactNotifications();

    if (canScheduleExact == true) {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'MediTrack',
      body: _buildNotificationBody(occurrence),
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: scheduleMode,
      payload: occurrence.id,
    );
  }

  /// Repairs the OS queue to exactly match the rolling desired set.
  /// Stable IDs make this safe to call after every app restart/resume.
  Future<void> synchronizeDoseReminders(
    List<DoseOccurrenceEntity> desiredOccurrences, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    final desiredById = <int, DoseOccurrenceEntity>{
      for (final occurrence in desiredOccurrences)
        _notificationIdForOccurrence(occurrence.id): occurrence,
    };

    final pending = await _plugin.pendingNotificationRequests();
    final validPendingIds = <int>{};

    for (final request in pending) {
      final desiredOccurrence = desiredById[request.id];

      if (desiredOccurrence == null ||
          request.payload != desiredOccurrence.id) {
        await _plugin.cancel(id: request.id);
        continue;
      }

      validPendingIds.add(request.id);
    }

    for (final entry in desiredById.entries) {
      if (validPendingIds.contains(entry.key)) {
        continue;
      }

      await scheduleDoseReminder(
        entry.value,
        vibrationEnabled: vibrationEnabled,
        soundId: soundId,
      );
    }
  }

  Future<void> cancelAllDoseReminders() {
    return _plugin.cancelAll();
  }

  Future<void> cancelDoseReminder(String occurrenceId) {
    return _plugin.cancel(id: _notificationIdForOccurrence(occurrenceId));
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _plugin.pendingNotificationRequests();
  }

  String _buildNotificationBody(DoseOccurrenceEntity occurrence) {
    return '${occurrence.medicineName}\n'
        '${occurrence.medicineStrength} • '
        '${_formatQuantity(occurrence.quantity)} ${occurrence.unit}\n'
        '${occurrence.foodInstruction}';
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  int _notificationIdForOccurrence(String occurrenceId) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;

    for (final codeUnit in occurrenceId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0x7FFFFFFF;
    }

    return hash;
  }
}
