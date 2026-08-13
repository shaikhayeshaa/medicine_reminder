import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../repositories/medicine_repository.dart';

class GetDoseOccurrenceByIdUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  GetDoseOccurrenceByIdUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DoseOccurrenceEntity?> call(String occurrenceId) async {
    final occurrence = await repository.getDoseOccurrenceById(occurrenceId);

    if (occurrence == null) {
      return null;
    }

    final effectiveTime = occurrence.snoozedUntil ?? occurrence.scheduledAt;

    final shouldBeMissed =
        occurrence.status == DoseStatus.pending &&
        effectiveTime.isBefore(now());

    if (!shouldBeMissed) {
      return occurrence;
    }

    final updated = occurrence.copyWith(status: DoseStatus.missed);

    await repository.updateDoseOccurrence(updated);

    return updated;
  }
}
