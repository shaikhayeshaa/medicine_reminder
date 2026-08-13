import '../../../medicine/domain/repositories/medicine_repository.dart';
import '../../../medicine/domain/repositories/reminder_notification_repository.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

/// Saves app settings and, when required, immediately synchronizes
/// future medicine reminders with the new notification preferences.
///
/// Keeping this orchestration in a use case prevents notification/storage
/// business rules from leaking into the Settings UI.
class SaveAndApplySettingsUseCase {
  final SettingsRepository settingsRepository;
  final MedicineRepository medicineRepository;
  final ReminderNotificationRepository reminderNotificationRepository;

  SaveAndApplySettingsUseCase({
    required this.settingsRepository,
    required this.medicineRepository,
    required this.reminderNotificationRepository,
  });

  Future<void> call(
    SettingsEntity settings, {
    required bool rescheduleNotifications,
  }) async {
    // Settings persistence is the primary operation.
    await settingsRepository.saveSettings(settings);

    // Default snooze changes do not affect reminders that are already
    // scheduled, so notification work can be skipped for that case.
    if (!rescheduleNotifications) {
      return;
    }

    try {
      // Turning reminders off should immediately remove all notifications
      // scheduled by this app.
      if (!settings.notificationsEnabled) {
        await reminderNotificationRepository.cancelAllReminders();
        return;
      }

      // If reminders are enabled, request platform permission where needed.
      await reminderNotificationRepository.requestPermissions();

      // Rebuild the future notification queue so sound/vibration changes
      // apply to reminders that were scheduled using older preferences.
      await reminderNotificationRepository.cancelAllReminders();

      final occurrences =
          await medicineRepository.getAllDoseOccurrences();

      await reminderNotificationRepository.scheduleReminders(
        occurrences,
        vibrationEnabled: settings.vibrationEnabled,
        soundId: settings.reminderSoundId,
      );
    } catch (_) {
      // The settings themselves are already safely persisted. A platform
      // notification limitation/permission failure must not undo them.
      // Startup/recovery synchronization can retry scheduling later.
    }
  }
}
