import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../repositories/medicine_repository.dart';

class MarkDoseTakenUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  MarkDoseTakenUseCase({required this.repository, DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<DoseOccurrenceEntity> call(DoseOccurrenceEntity occurrence) async {
    final updated = occurrence.copyWith(
      status: DoseStatus.taken,
      actionAt: now(),
    );

    await repository.updateDoseOccurrence(updated);

    return updated;
  }
}
