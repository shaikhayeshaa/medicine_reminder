import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../repositories/medicine_repository.dart';

class GetDoseOccurrencesByDateUseCase {
  final MedicineRepository repository;

  GetDoseOccurrencesByDateUseCase({
    required this.repository,
  });

  Future<List<DoseOccurrenceEntity>> call(
    DateTime date,
  ) async {
    final occurrences =
        await repository.getDoseOccurrencesByDate(date);

    final now = DateTime.now();

    final result = <DoseOccurrenceEntity>[];

    for (final occurrence in occurrences) {
      final effectiveTime =
          occurrence.snoozedUntil ??
          occurrence.scheduledAt;

      final shouldBeMissed =
          occurrence.status == DoseStatus.pending &&
          effectiveTime.isBefore(now);

      if (!shouldBeMissed) {
        result.add(occurrence);
        continue;
      }

      final updatedOccurrence = DoseOccurrenceEntity(
        id: occurrence.id,
        medicineId: occurrence.medicineId,
        doseId: occurrence.doseId,
        scheduledAt: occurrence.scheduledAt,
        quantity: occurrence.quantity,
        unit: occurrence.unit,
        foodInstruction: occurrence.foodInstruction,
        status: DoseStatus.missed,
        actionAt: occurrence.actionAt,
        snoozedUntil: occurrence.snoozedUntil,
        createdAt: occurrence.createdAt,
        medicineName: occurrence.medicineName,
        medicineDescription:
            occurrence.medicineDescription,
        medicineType: occurrence.medicineType,
        medicineStrength:
            occurrence.medicineStrength,
      );

      await repository.updateDoseOccurrence(
        updatedOccurrence,
      );

      result.add(updatedOccurrence);
    }

    result.sort(
      (a, b) =>
          a.scheduledAt.compareTo(b.scheduledAt),
    );

    return result;
  }
}