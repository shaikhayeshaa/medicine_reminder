import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/generate_dose_occurrences.dart';
import 'package:medicine_reminder/features/recovery/domain/usecases/run_app_recovery.dart';
import 'package:medicine_reminder/features/settings/domain/entities/settings_entity.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 10, 12);

  test(
    'recovery marks overdue pending doses missed and synchronizes reminders',
    () async {
      final medicineRepository = FakeMedicineRepository();
      final notificationRepository = FakeReminderNotificationRepository();
      final settingsRepository = FakeSettingsRepository(
        settings: const SettingsEntity(
          reminderSoundId: 'alarm_2',
          vibrationEnabled: false,
          defaultSnoozeMinutes: 10,
          notificationsEnabled: true,
        ),
      );

      final medicine = testMedicine(endDate: DateTime(2026, 8, 11));
      medicineRepository.medicines[medicine.id] = medicine;

      final overdue = testOccurrence(
        id: 'overdue',
        scheduledAt: DateTime(2026, 8, 10, 8),
      );
      medicineRepository.occurrences[overdue.id] = overdue;

      final useCase = RunAppRecoveryUseCase(
        medicineRepository: medicineRepository,
        reminderNotificationRepository: notificationRepository,
        settingsRepository: settingsRepository,
        generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
        now: () => now,
      );

      final report = await useCase();

      expect(report.markedMissed, 1);
      expect(
        medicineRepository.occurrences[overdue.id]?.status,
        DoseStatus.missed,
      );
      expect(notificationRepository.synchronizeCalls, 1);
      expect(notificationRepository.lastVibrationEnabled, isFalse);
      expect(notificationRepository.lastSoundId, 'alarm_2');
    },
  );

  test(
    'running recovery twice does not create duplicate occurrence IDs',
    () async {
      final medicineRepository = FakeMedicineRepository();
      final notificationRepository = FakeReminderNotificationRepository();
      final settingsRepository = FakeSettingsRepository();

      final medicine = testMedicine(endDate: null);
      medicineRepository.medicines[medicine.id] = medicine;

      final useCase = RunAppRecoveryUseCase(
        medicineRepository: medicineRepository,
        reminderNotificationRepository: notificationRepository,
        settingsRepository: settingsRepository,
        generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
        now: () => now,
      );

      final firstReport = await useCase();
      final countAfterFirst = medicineRepository.occurrences.length;
      final secondReport = await useCase();
      final countAfterSecond = medicineRepository.occurrences.length;

      expect(firstReport.createdOccurrences, greaterThan(0));
      expect(secondReport.createdOccurrences, 0);
      expect(countAfterSecond, countAfterFirst);
      expect(
        medicineRepository.occurrences.keys.toSet().length,
        medicineRepository.occurrences.length,
      );
    },
  );

  test(
    'notifications off cancels OS reminders instead of synchronizing',
    () async {
      final medicineRepository = FakeMedicineRepository();
      final notificationRepository = FakeReminderNotificationRepository();
      final settingsRepository = FakeSettingsRepository(
        settings: SettingsEntity.defaults.copyWith(notificationsEnabled: false),
      );

      medicineRepository.medicines['medicine-1'] = testMedicine(endDate: null);

      final useCase = RunAppRecoveryUseCase(
        medicineRepository: medicineRepository,
        reminderNotificationRepository: notificationRepository,
        settingsRepository: settingsRepository,
        generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
        now: () => now,
      );

      await useCase();

      expect(notificationRepository.cancelAllCalls, 1);
      expect(notificationRepository.synchronizeCalls, 0);
    },
  );

  test('completed bounded medicine is deactivated during recovery', () async {
    final medicineRepository = FakeMedicineRepository();
    final notificationRepository = FakeReminderNotificationRepository();
    final settingsRepository = FakeSettingsRepository();

    final completed = testMedicine(
      endDate: DateTime(2026, 8, 9),
      isActive: true,
    );
    medicineRepository.medicines[completed.id] = completed;

    final useCase = RunAppRecoveryUseCase(
      medicineRepository: medicineRepository,
      reminderNotificationRepository: notificationRepository,
      settingsRepository: settingsRepository,
      generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
      now: () => now,
    );

    final report = await useCase();

    expect(medicineRepository.medicines[completed.id]?.isActive, isFalse);
    expect(report.activeMedicines, 0);
  });
}
