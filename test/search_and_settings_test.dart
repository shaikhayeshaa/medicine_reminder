import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/utils/occurrence_search.dart';
import 'package:medicine_reminder/features/settings/domain/entities/settings_entity.dart';
import 'package:medicine_reminder/features/settings/domain/usecases/save_and_apply_settings.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  group('Case-insensitive occurrence search', () {
    final occurrence = testOccurrence(
      medicineName: 'Paracetamol',
      medicineDescription: 'For Severe Fever',
      medicineType: 'TABLET',
    );

    test('matches medicine name regardless of case', () {
      expect(occurrenceMatchesSearch(occurrence, 'para'), isTrue);
      expect(occurrenceMatchesSearch(occurrence, 'PARACETAMOL'), isTrue);
    });

    test('matches description and type regardless of case', () {
      expect(occurrenceMatchesSearch(occurrence, 'severe fever'), isTrue);
      expect(occurrenceMatchesSearch(occurrence, 'tablet'), isTrue);
    });

    test('trims query and rejects unrelated text', () {
      expect(occurrenceMatchesSearch(occurrence, '  PARA  '), isTrue);
      expect(occurrenceMatchesSearch(occurrence, 'ibuprofen'), isFalse);
    });
  });

  group('Settings application', () {
    test(
      'turning notifications off persists settings and cancels reminders',
      () async {
        final settingsRepository = FakeSettingsRepository();
        final medicineRepository = FakeMedicineRepository();
        final notificationRepository = FakeReminderNotificationRepository();

        final useCase = SaveAndApplySettingsUseCase(
          settingsRepository: settingsRepository,
          medicineRepository: medicineRepository,
          reminderNotificationRepository: notificationRepository,
        );

        final settings = SettingsEntity.defaults.copyWith(
          notificationsEnabled: false,
        );

        await useCase(settings, rescheduleNotifications: true);

        expect(settingsRepository.settings.notificationsEnabled, isFalse);
        expect(notificationRepository.cancelAllCalls, 1);
        expect(notificationRepository.scheduleRemindersCalls, 0);
      },
    );

    test('sound/vibration changes rebuild future notification queue', () async {
      final settingsRepository = FakeSettingsRepository();
      final medicineRepository = FakeMedicineRepository();
      final notificationRepository = FakeReminderNotificationRepository();

      medicineRepository.occurrences['future'] = testOccurrence(
        id: 'future',
        scheduledAt: DateTime(2099, 1, 1, 8),
        status: DoseStatus.pending,
      );

      final useCase = SaveAndApplySettingsUseCase(
        settingsRepository: settingsRepository,
        medicineRepository: medicineRepository,
        reminderNotificationRepository: notificationRepository,
      );

      const settings = SettingsEntity(
        reminderSoundId: 'alarm_3',
        vibrationEnabled: false,
        defaultSnoozeMinutes: 15,
        notificationsEnabled: true,
      );

      await useCase(settings, rescheduleNotifications: true);

      expect(settingsRepository.settings.reminderSoundId, 'alarm_3');
      expect(notificationRepository.requestPermissionsCalls, 1);
      expect(notificationRepository.cancelAllCalls, 1);
      expect(notificationRepository.scheduleRemindersCalls, 1);
    });

    test(
      'default snooze-only change can save without rescheduling notifications',
      () async {
        final settingsRepository = FakeSettingsRepository();
        final medicineRepository = FakeMedicineRepository();
        final notificationRepository = FakeReminderNotificationRepository();

        final useCase = SaveAndApplySettingsUseCase(
          settingsRepository: settingsRepository,
          medicineRepository: medicineRepository,
          reminderNotificationRepository: notificationRepository,
        );

        final settings = SettingsEntity.defaults.copyWith(
          defaultSnoozeMinutes: 30,
        );

        await useCase(settings, rescheduleNotifications: false);

        expect(settingsRepository.settings.defaultSnoozeMinutes, 30);
        expect(notificationRepository.requestPermissionsCalls, 0);
        expect(notificationRepository.cancelAllCalls, 0);
        expect(notificationRepository.scheduleRemindersCalls, 0);
      },
    );
  });
}
