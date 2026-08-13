import '../../../../core/services/notification_service.dart';
import '../../domain/entities/dose_occurrence_entity.dart';
import '../../domain/entities/dose_status.dart';
import '../../domain/repositories/reminder_notification_repository.dart';

class ReminderNotificationRepositoryImpl
    implements ReminderNotificationRepository {
  final NotificationService notificationService;

  ReminderNotificationRepositoryImpl({
    required this.notificationService,
  });

  @override
  Future<void> requestPermissions() {
    return notificationService.requestPermissions();
  }

  @override
  Future<void> scheduleReminder(
    DoseOccurrenceEntity occurrence, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) {
    return notificationService.scheduleDoseReminder(
      occurrence,
      vibrationEnabled: vibrationEnabled,
      soundId: soundId,
    );
  }

  @override
  Future<void> scheduleReminders(
    List<DoseOccurrenceEntity> occurrences, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    final now = DateTime.now();

    // Only pending future occurrences should create notifications.
    final futureOccurrences =
        occurrences.where((occurrence) {
      if (occurrence.status != DoseStatus.pending) {
        return false;
      }

      final reminderTime =
          occurrence.snoozedUntil ??
          occurrence.scheduledAt;

      return reminderTime.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final aTime =
            a.snoozedUntil ??
            a.scheduledAt;

        final bTime =
            b.snoozedUntil ??
            b.scheduledAt;

        return aTime.compareTo(bTime);
      });

    // Safe rolling queue instead of scheduling unlimited reminders.
    for (final occurrence
        in futureOccurrences.take(50)) {
      await notificationService.scheduleDoseReminder(
        occurrence,
        vibrationEnabled: vibrationEnabled,
        soundId: soundId,
      );
    }
  }

  @override
  Future<void> cancelReminder(
    String occurrenceId,
  ) {
    return notificationService.cancelDoseReminder(
      occurrenceId,
    );
  }

  @override
  Future<void> cancelAllReminders() {
    return notificationService
        .cancelAllDoseReminders();
  }
}