import 'package:hive/hive.dart';
import '../../../../core/constants/hive_constants.dart';
import '../../domain/entities/dose_status.dart';
import '../models/dose_occurrence_model.dart';
import '../models/medicine_model.dart';

abstract class MedicineLocalDataSource {
  Future<void> addMedicine(MedicineModel medicine);

  Future<List<MedicineModel>> getAllMedicines();

  Future<MedicineModel?> getMedicineById(String id);

  Future<void> updateMedicine(MedicineModel medicine);

  Future<void> deleteMedicine(String medicineId);

  Future<void> saveDoseOccurrences(List<DoseOccurrenceModel> occurrences);

  Future<List<DoseOccurrenceModel>> getAllDoseOccurrences();

  Future<List<DoseOccurrenceModel>> getDoseOccurrencesByMedicineId(
    String medicineId,
  );

  Future<List<DoseOccurrenceModel>> getDoseOccurrencesByDate(DateTime date);

  Future<void> updateDoseOccurrence(DoseOccurrenceModel occurrence);

  Future<void> deleteFutureOccurrencesForMedicine(
    String medicineId,
    DateTime from,
  );
  Future<DoseOccurrenceModel?> getDoseOccurrenceById(String occurrenceId);
}

class MedicineLocalDataSourceImpl implements MedicineLocalDataSource {
  Box<MedicineModel> get _medicinesBox =>
      Hive.box<MedicineModel>(HiveConstants.medicinesBox);

  Box<DoseOccurrenceModel> get _occurrencesBox =>
      Hive.box<DoseOccurrenceModel>(HiveConstants.doseOccurrencesBox);

  @override
  Future<void> addMedicine(MedicineModel medicine) async {
    await _medicinesBox.put(medicine.id, medicine);
  }

  @override
  Future<List<MedicineModel>> getAllMedicines() async {
    return _medicinesBox.values.toList();
  }

  @override
  Future<MedicineModel?> getMedicineById(String id) async {
    return _medicinesBox.get(id);
  }

  @override
  Future<void> updateMedicine(MedicineModel medicine) async {
    await _medicinesBox.put(medicine.id, medicine);
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    await _medicinesBox.delete(medicineId);
  }

  @override
  Future<void> saveDoseOccurrences(
    List<DoseOccurrenceModel> occurrences,
  ) async {
    final data = <String, DoseOccurrenceModel>{
      for (final occurrence in occurrences) occurrence.id: occurrence,
    };

    await _occurrencesBox.putAll(data);
  }

  @override
  Future<List<DoseOccurrenceModel>> getAllDoseOccurrences() async {
    return _occurrencesBox.values.toList();
  }

  @override
  Future<List<DoseOccurrenceModel>> getDoseOccurrencesByMedicineId(
    String medicineId,
  ) async {
    return _occurrencesBox.values
        .where((occurrence) => occurrence.medicineId == medicineId)
        .toList();
  }

  @override
  Future<List<DoseOccurrenceModel>> getDoseOccurrencesByDate(
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _occurrencesBox.values.where((occurrence) {
      final scheduledAt = occurrence.scheduledAt;

      return !scheduledAt.isBefore(startOfDay) &&
          scheduledAt.isBefore(endOfDay);
    }).toList();
  }

  @override
  Future<void> updateDoseOccurrence(DoseOccurrenceModel occurrence) async {
    await _occurrencesBox.put(occurrence.id, occurrence);
  }

  @override
  Future<void> deleteFutureOccurrencesForMedicine(
    String medicineId,
    DateTime from,
  ) async {
    final keysToDelete = <dynamic>[];

    for (final key in _occurrencesBox.keys) {
      final occurrence = _occurrencesBox.get(key);

      if (occurrence == null) {
        continue;
      }

      final isSameMedicine = occurrence.medicineId == medicineId;

      final isFuture = !occurrence.scheduledAt.isBefore(from);

      final isPending = occurrence.status == DoseStatus.pending;

      if (isSameMedicine && isFuture && isPending) {
        keysToDelete.add(key);
      }
    }

    await _occurrencesBox.deleteAll(keysToDelete);
  }

  @override
  Future<DoseOccurrenceModel?> getDoseOccurrenceById(
    String occurrenceId,
  ) async {
    return _occurrencesBox.get(occurrenceId);
  }
}
