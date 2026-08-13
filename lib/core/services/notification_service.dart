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

  Stream<String> get notificationTapStream => _notificationTapController.stream;

  final StreamController<NotificationActionEvent>
  _notificationActionController =
      StreamController<NotificationActionEvent>.broadcast();

  Stream<NotificationActionEvent> get notificationActionStream =>
      _notificationActionController.stream;
  String? _initialPayload;

  String? get initialPayload => _initialPayload;

  NotificationActionEvent? _initialAction;

  NotificationActionEvent? takeInitialAction() {
    final action = _initialAction;

    _initialAction = null;

    return action;
  }

  String? takeInitialPayload() {
    final payload = _initialPayload;

    _initialPayload = null;

    return payload;
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
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationConstants.skipActionId,
              'Skip',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp == true) {
      final response = launchDetails?.notificationResponse;

      final payload = response?.payload?.trim();

      if (payload != null && payload.isNotEmpty) {
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
      // Normal notification body tap
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

    // Never schedule reminders in the past.
    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    final notificationId = _notificationIdForOccurrence(occurrence.id);

    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);

/* Android 8+ stores sound/vibration on the notification channel.
Therefore we use a different channel id for each sound/vibration combination. 
Reusing one channel would make later Settings changes ineffective on Android. */

    final dynamicChannelId =
        '${NotificationConstants.channelId}'
        '_${soundId}_'
        '${vibrationEnabled ? 'vibration' : 'no_vibration'}';

    final androidDetails = AndroidNotificationDetails(
      dynamicChannelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDescription,

      importance: Importance.max,
      priority: Priority.high,

      category: AndroidNotificationCategory.alarm,

      // Selected custom raw sound.
      sound: RawResourceAndroidNotificationSound(soundId),

      playSound: true,

      // Settings-controlled vibration.
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

      // Native iOS bundle sound.
      sound: '$soundId.wav',

      categoryIdentifier: NotificationConstants.categoryId,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Inexact is our safe fallback.
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
      title: 'Medicine Reminder',
      body: _buildNotificationBody(occurrence),
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: scheduleMode,
      payload: occurrence.id,
    );
  }
  // Android 8+ mein sound vibration notification channel behavior hota hai 
  // aur existing channel ke behavior ko app baad mein simply change nahi kar sakti, 
  //isliye different setting combinations ke liye distinct channel IDs use karna zaroori hai. 
  //AndroidNotificationDetails custom sound aur vibration configuration support karta hai.

  Future<void> cancelAllDoseReminders() async {
    // Used when Notifications are disabled or when we rebuild
    // the complete future reminder queue after Settings change.
    await _plugin.cancelAll();
  }

  Future<void> cancelDoseReminder(String occurrenceId) async {
    await _plugin.cancel(id: _notificationIdForOccurrence(occurrenceId));
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _plugin.pendingNotificationRequests();
  }

  String _buildNotificationBody(DoseOccurrenceEntity occurrence) {
    return '${occurrence.medicineName}\n'
        '${occurrence.medicineStrength} • '
        '${_formatQuantity(occurrence.quantity)} '
        '${occurrence.unit}\n'
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
