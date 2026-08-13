import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../entities/medicine_entity.dart';
import '../repositories/medicine_repository.dart';

/// Pauses a medicine without changing its treatment dates.
///
/// Future pending occurrences are removed. Resume can regenerate them later.
class PauseMedicineUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  PauseMedicineUseCase({required this.repository, DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<List<DoseOccurrenceEntity>> call(String medicineId) async {
    final medicine = await repository.getMedicineById(medicineId);

    if (medicine == null) {
      throw StateError('Medicine not found.');
    }

    if (!medicine.isActive) {
      return const [];
    }

    final currentTime = now();

    final occurrences = await repository.getDoseOccurrencesByMedicineId(
      medicineId,
    );

    final futurePending = occurrences
        .where(
          (occurrence) =>
              occurrence.status == DoseStatus.pending &&
              !(occurrence.snoozedUntil ?? occurrence.scheduledAt).isBefore(
                currentTime,
              ),
        )
        .toList();

    final pausedMedicine = _copyMedicine(
      medicine,
      isActive: false,
      updatedAt: currentTime,
    );

    await repository.updateMedicine(pausedMedicine);

    await repository.deleteFutureOccurrencesForMedicine(
      medicineId,
      currentTime,
    );

    return futurePending;
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
