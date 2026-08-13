import '../entities/medicine_entity.dart';
import '../repositories/medicine_repository.dart';
import 'generate_dose_occurrences.dart';
import '../entities/dose_occurrence_entity.dart';

class AddMedicineUseCase {
  final MedicineRepository repository;
  final GenerateDoseOccurrencesUseCase generateDoseOccurrences;

  AddMedicineUseCase({
    required this.repository,
    required this.generateDoseOccurrences,
  });

  Future<List<DoseOccurrenceEntity>> call(MedicineEntity medicine) async {
    final occurrences = _generateOccurrences(medicine);

    try {
      await repository.addMedicine(medicine);

      await repository.saveDoseOccurrences(occurrences);

      return occurrences;
    } catch (_) {
      await repository.deleteFutureOccurrencesForMedicine(
        medicine.id,
        medicine.startDate,
      );

      await repository.deleteMedicine(medicine.id);

      rethrow;
    }
  }

  List<DoseOccurrenceEntity> _generateOccurrences(MedicineEntity medicine) {
    if (medicine.endDate != null) {
      return generateDoseOccurrences(medicine: medicine);
    }

    final today = _dateOnly(DateTime.now());

    final medicineStart = _dateOnly(medicine.startDate);

    final generationStart = medicineStart.isAfter(today)
        ? medicineStart
        : today;

    // Rolling window for ongoing medicines.
    // 30 days including generationStart.
    final generationEnd = generationStart.add(const Duration(days: 29));

    return generateDoseOccurrences(
      medicine: medicine,
      from: generationStart,
      until: generationEnd,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
