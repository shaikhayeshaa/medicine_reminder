import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';
import '../../../medicine/domain/entities/medicine_entity.dart';
import '../../../medicine/domain/repositories/medicine_repository.dart';
import '../../../medicine/domain/repositories/reminder_notification_repository.dart';
import '../../../medicine/domain/usecases/generate_dose_occurrences.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../entities/recovery_report.dart';

/// Repairs the local schedule whenever the app starts or returns to foreground.
///
/// It intentionally keeps all logic deterministic and offline-first:
/// 1. overdue pending doses become Missed,
/// 2. active medicines get a bounded rolling occurrence window,
/// 3. OS notifications are synchronized with the repaired Hive state.
class RunAppRecoveryUseCase {
  final MedicineRepository medicineRepository;
  final ReminderNotificationRepository reminderNotificationRepository;
  final SettingsRepository settingsRepository;
  final GenerateDoseOccurrencesUseCase generateDoseOccurrences;
  final DateTime Function() now;

  RunAppRecoveryUseCase({
    required this.medicineRepository,
    required this.reminderNotificationRepository,
    required this.settingsRepository,
    required this.generateDoseOccurrences,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<RecoveryReport> call() async {
    final currentTime = now();
    final medicines = await medicineRepository.getAllMedicines();
    final activeMedicines = <MedicineEntity>[];

    // Automatically close treatments whose end date is already over.
    for (final medicine in medicines) {
      if (!medicine.isActive) {
        continue;
      }

      if (_hasTreatmentEnded(medicine, currentTime)) {
        await medicineRepository.updateMedicine(
          _copyMedicine(
            medicine,
            isActive: false,
            updatedAt: currentTime,
          ),
        );
        continue;
      }

      activeMedicines.add(medicine);
    }

    var occurrences = await medicineRepository.getAllDoseOccurrences();
    var markedMissed = 0;

    // Reconcile every overdue occurrence, not only the currently visible day.
    for (final occurrence in occurrences) {
      if (!_shouldBecomeMissed(occurrence, currentTime)) {
        continue;
      }

      await medicineRepository.updateDoseOccurrence(
        occurrence.copyWith(
          status: DoseStatus.missed,
        ),
      );
      markedMissed++;
    }

    // Remove any future pending schedule belonging to paused/stopped medicines.
    final activeIds = activeMedicines.map((item) => item.id).toSet();
    for (final medicine in medicines) {
      if (activeIds.contains(medicine.id)) {
        continue;
      }

      await medicineRepository.deleteFutureOccurrencesForMedicine(
        medicine.id,
        currentTime,
      );
    }

    // Reload after reconciliation/deletions before computing missing rolling data.
    occurrences = await medicineRepository.getAllDoseOccurrences();
    final existingIds = occurrences.map((item) => item.id).toSet();
    final generatedToSave = <DoseOccurrenceEntity>[];

    for (final medicine in activeMedicines) {
      final rollingEnd = _rollingEndFor(
        medicine: medicine,
        currentTime: currentTime,
      );

      if (rollingEnd == null) {
        continue;
      }

      final generated = generateDoseOccurrences(
        medicine: medicine,
        from: currentTime,
        until: rollingEnd,
      );

      for (final occurrence in generated) {
        // Deterministic occurrence IDs make recovery idempotent.
        if (existingIds.add(occurrence.id)) {
          generatedToSave.add(occurrence);
        }
      }
    }

    if (generatedToSave.isNotEmpty) {
      await medicineRepository.saveDoseOccurrences(
        generatedToSave,
      );
    }

    final repairedOccurrences =
        await medicineRepository.getAllDoseOccurrences();
    final settings = await settingsRepository.getSettings();

    try {
      if (!settings.notificationsEnabled) {
        await reminderNotificationRepository.cancelAllReminders();
      } else {
        // Synchronize rather than blindly append notifications. This removes
        // stale requests and prevents duplicates after app/device recovery.
        await reminderNotificationRepository.synchronizeReminders(
          repairedOccurrences.where((occurrence) {
            return activeIds.contains(occurrence.medicineId);
          }).toList(),
          vibrationEnabled: settings.vibrationEnabled,
          soundId: settings.reminderSoundId,
        );
      }
    } catch (_) {
      // Hive recovery is still valid if the OS rejects notification work
      // because of permissions or platform-specific scheduling limits.
    }

    return RecoveryReport(
      markedMissed: markedMissed,
      createdOccurrences: generatedToSave.length,
      activeMedicines: activeMedicines.length,
    );
  }

  bool _shouldBecomeMissed(
    DoseOccurrenceEntity occurrence,
    DateTime currentTime,
  ) {
    if (occurrence.status != DoseStatus.pending) {
      return false;
    }

    final effectiveTime =
        occurrence.snoozedUntil ?? occurrence.scheduledAt;

    return effectiveTime.isBefore(currentTime);
  }

  bool _hasTreatmentEnded(
    MedicineEntity medicine,
    DateTime currentTime,
  ) {
    if (medicine.endDate == null) {
      return false;
    }

    final endOfDay = DateTime(
      medicine.endDate!.year,
      medicine.endDate!.month,
      medicine.endDate!.day,
      23,
      59,
      59,
      999,
    );

    return endOfDay.isBefore(currentTime);
  }

  DateTime? _rollingEndFor({
    required MedicineEntity medicine,
    required DateTime currentTime,
  }) {
    final rollingEnd = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    ).add(const Duration(days: 29));

    if (medicine.endDate == null) {
      return rollingEnd;
    }

    final treatmentEnd = DateTime(
      medicine.endDate!.year,
      medicine.endDate!.month,
      medicine.endDate!.day,
    );

    if (treatmentEnd.isBefore(
      DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
      ),
    )) {
      return null;
    }

    return treatmentEnd.isBefore(rollingEnd)
        ? treatmentEnd
        : rollingEnd;
  }

  MedicineEntity _copyMedicine(
    MedicineEntity medicine, {
    required bool isActive,
    required DateTime updatedAt,
  }) {
    return MedicineEntity(
      id: medicine.id,
      name: medicine.name,
      description: medicine.description,
      type: medicine.type,
      strength: medicine.strength,
      startDate: medicine.startDate,
      endDate: medicine.endDate,
      doses: medicine.doses,
      isActive: isActive,
      createdAt: medicine.createdAt,
      updatedAt: updatedAt,
    );
  }
}
