import 'package:medicine_reminder/features/medicine/domain/entities/dose_occurrence_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/medicine_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/repositories/medicine_repository.dart';
import 'package:medicine_reminder/features/medicine/domain/repositories/reminder_notification_repository.dart';
import 'package:medicine_reminder/features/settings/domain/entities/settings_entity.dart';
import 'package:medicine_reminder/features/settings/domain/repositories/settings_repository.dart';

/// Small in-memory repository used by domain/use-case tests.
///
/// It mirrors the production rule that deleting future schedule data removes
/// only pending occurrences, while completed history stays untouched.
class FakeMedicineRepository implements MedicineRepository {
  final Map<String, MedicineEntity> medicines = {};
  final Map<String, DoseOccurrenceEntity> occurrences = {};

  int addMedicineCalls = 0;
  int updateMedicineCalls = 0;
  int deleteMedicineCalls = 0;
  int saveDoseOccurrencesCalls = 0;
  int updateDoseOccurrenceCalls = 0;
  int deleteFutureOccurrencesCalls = 0;

  @override
  Future<void> addMedicine(MedicineEntity medicine) async {
    addMedicineCalls++;
    medicines[medicine.id] = medicine;
  }

  @override
  Future<void> deleteFutureOccurrencesForMedicine(
    String medicineId,
    DateTime from,
  ) async {
    deleteFutureOccurrencesCalls++;

    final idsToDelete = occurrences.values
        .where((occurrence) {
          final effectiveTime =
              occurrence.snoozedUntil ?? occurrence.scheduledAt;

          return occurrence.medicineId == medicineId &&
              occurrence.status == DoseStatus.pending &&
              !effectiveTime.isBefore(from);
        })
        .map((occurrence) => occurrence.id)
        .toList();

    for (final id in idsToDelete) {
      occurrences.remove(id);
    }
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    deleteMedicineCalls++;
    medicines.remove(medicineId);
  }

  @override
  Future<List<DoseOccurrenceEntity>> getAllDoseOccurrences() async {
    return occurrences.values.toList();
  }

  @override
  Future<List<MedicineEntity>> getAllMedicines() async {
    return medicines.values.toList();
  }

  @override
  Future<DoseOccurrenceEntity?> getDoseOccurrenceById(
    String occurrenceId,
  ) async {
    return occurrences[occurrenceId];
  }

  @override
  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByDate(
    DateTime date,
  ) async {
    return occurrences.values.where((occurrence) {
      final scheduled = occurrence.scheduledAt;
      return scheduled.year == date.year &&
          scheduled.month == date.month &&
          scheduled.day == date.day;
    }).toList();
  }

  @override
  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByMedicineId(
    String medicineId,
  ) async {
    return occurrences.values
        .where((occurrence) => occurrence.medicineId == medicineId)
        .toList();
  }

  @override
  Future<MedicineEntity?> getMedicineById(String id) async {
    return medicines[id];
  }

  @override
  Future<void> saveDoseOccurrences(
    List<DoseOccurrenceEntity> newOccurrences,
  ) async {
    saveDoseOccurrencesCalls++;
    for (final occurrence in newOccurrences) {
      occurrences[occurrence.id] = occurrence;
    }
  }

  @override
  Future<void> updateDoseOccurrence(DoseOccurrenceEntity occurrence) async {
    updateDoseOccurrenceCalls++;
    occurrences[occurrence.id] = occurrence;
  }

  @override
  Future<void> updateMedicine(MedicineEntity medicine) async {
    updateMedicineCalls++;
    medicines[medicine.id] = medicine;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  SettingsEntity settings;

  FakeSettingsRepository({this.settings = SettingsEntity.defaults});

  @override
  Future<SettingsEntity> getSettings() async => settings;

  @override
  Future<void> saveSettings(SettingsEntity settings) async {
    this.settings = settings;
  }
}

class FakeReminderNotificationRepository
    implements ReminderNotificationRepository {
  int requestPermissionsCalls = 0;
  int scheduleReminderCalls = 0;
  int scheduleRemindersCalls = 0;
  int synchronizeCalls = 0;
  int cancelReminderCalls = 0;
  int cancelAllCalls = 0;

  List<DoseOccurrenceEntity> lastSynchronizedOccurrences = [];
  bool? lastVibrationEnabled;
  String? lastSoundId;

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCalls++;
  }

  @override
  Future<void> cancelReminder(String occurrenceId) async {
    cancelReminderCalls++;
  }

  @override
  Future<void> requestPermissions() async {
    requestPermissionsCalls++;
  }

  @override
  Future<void> scheduleReminder(
    DoseOccurrenceEntity occurrence, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    scheduleReminderCalls++;
  }

  @override
  Future<void> scheduleReminders(
    List<DoseOccurrenceEntity> occurrences, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    scheduleRemindersCalls++;
  }

  @override
  Future<void> synchronizeReminders(
    List<DoseOccurrenceEntity> occurrences, {
    bool vibrationEnabled = true,
    String soundId = 'default_alarm',
  }) async {
    synchronizeCalls++;
    lastSynchronizedOccurrences = List.of(occurrences);
    lastVibrationEnabled = vibrationEnabled;
    lastSoundId = soundId;
  }
}
