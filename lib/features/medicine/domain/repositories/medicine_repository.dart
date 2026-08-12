import '../entities/dose_occurrence_entity.dart';
import '../entities/medicine_entity.dart';

abstract class MedicineRepository {
  Future<void> addMedicine(MedicineEntity medicine);

  Future<List<MedicineEntity>> getAllMedicines();

  Future<MedicineEntity?> getMedicineById(String id);

  Future<void> updateMedicine(MedicineEntity medicine);

  Future<void> deleteMedicine(String medicineId);

  Future<void> saveDoseOccurrences(List<DoseOccurrenceEntity> occurrences);

  Future<List<DoseOccurrenceEntity>> getAllDoseOccurrences();

  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByMedicineId(
    String medicineId,
  );

  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByDate(DateTime date);

  Future<void> updateDoseOccurrence(DoseOccurrenceEntity occurrence);

  Future<void> deleteFutureOccurrencesForMedicine(
    String medicineId,
    DateTime from,
  );
}
