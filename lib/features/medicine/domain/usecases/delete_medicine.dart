import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../repositories/medicine_repository.dart';

/// Deletes the medicine definition and its future pending schedule.
///
/// Historical occurrences are intentionally preserved so History remains
/// accurate after medicine deletion.
class DeleteMedicineUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  DeleteMedicineUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<List<DoseOccurrenceEntity>> call(
    String medicineId,
  ) async {
    final currentTime = now();

    final occurrences =
        await repository.getDoseOccurrencesByMedicineId(
      medicineId,
    );

    final futurePending = occurrences
        .where(
          (occurrence) =>
              occurrence.status == DoseStatus.pending &&
              !(occurrence.snoozedUntil ??
                      occurrence.scheduledAt)
                  .isBefore(currentTime),
        )
        .toList();

    // Remove future pending schedule first.
    await repository.deleteFutureOccurrencesForMedicine(
      medicineId,
      currentTime,
    );

    // Historical occurrence snapshots remain in Hive.
    await repository.deleteMedicine(medicineId);

    return futurePending;
  }
}
