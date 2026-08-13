import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../entities/medicine_entity.dart';
import '../repositories/medicine_repository.dart';

/// Permanently stops an ongoing/active medicine.
///
/// Stop differs from Pause by closing the treatment at today's date.
/// Historical records remain untouched.
class StopMedicineUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  StopMedicineUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<List<DoseOccurrenceEntity>> call(
    String medicineId,
  ) async {
    final medicine =
        await repository.getMedicineById(medicineId);

    if (medicine == null) {
      throw StateError('Medicine not found.');
    }

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

    final stoppedMedicine = MedicineEntity(
      id: medicine.id,
      name: medicine.name,
      description: medicine.description,
      type: medicine.type,
      strength: medicine.strength,
      startDate: medicine.startDate,

      // Mark today as the treatment's final date.
      endDate: DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
      ),

      doses: medicine.doses,
      isActive: false,
      createdAt: medicine.createdAt,
      updatedAt: currentTime,
    );

    await repository.updateMedicine(stoppedMedicine);

    await repository.deleteFutureOccurrencesForMedicine(
      medicineId,
      currentTime,
    );

    return futurePending;
  }
}
