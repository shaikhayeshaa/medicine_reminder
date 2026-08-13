import '../entities/dose_occurrence_entity.dart';

abstract class ReminderNotificationRepository {
  /// Requests notification/exact-alarm permissions where required.
  Future<void> requestPermissions();

  /// Schedules one individual dose occurrence.
  Future<void> scheduleReminder(
    DoseOccurrenceEntity occurrence, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  });

  /// Schedules a safe rolling batch of future occurrences.
  Future<void> scheduleReminders(
    List<DoseOccurrenceEntity> occurrences, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  });

  /// Cancels one occurrence reminder.
  Future<void> cancelReminder(String occurrenceId);

  /// Cancels every notification scheduled by this application.
  Future<void> cancelAllReminders();
}
