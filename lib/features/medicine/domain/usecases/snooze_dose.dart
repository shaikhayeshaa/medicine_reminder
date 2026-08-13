import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../entities/snooze_option.dart';
import '../repositories/medicine_repository.dart';

class SnoozeDoseUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  SnoozeDoseUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DoseOccurrenceEntity> call({
    required DoseOccurrenceEntity occurrence,
    required SnoozeOption option,
  }) async {
    if (occurrence.status != DoseStatus.pending) {
      throw StateError(
        'Only pending doses can be snoozed.',
      );
    }

    final snoozedUntil = now().add(
      Duration(
        minutes: option.minutes,
      ),
    );

    final updated = occurrence.copyWith(
      snoozedUntil: snoozedUntil,
    );

    await repository.updateDoseOccurrence(
      updated,
    );

    return updated;
  }
}