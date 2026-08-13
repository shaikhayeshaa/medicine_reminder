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
    // A notification can be acted on a moment after its scheduled time.
    // Recovery may already have reconciled that dose as Missed, so allow a
    // missed dose to be snoozed back into Pending instead of rejecting the
    // user's notification action.
    if (occurrence.status != DoseStatus.pending &&
        occurrence.status != DoseStatus.missed) {
      throw StateError(
        'Only pending or missed doses can be snoozed.',
      );
    }

    final snoozedUntil = now().add(
      Duration(
        minutes: option.minutes,
      ),
    );

    final updated = occurrence.copyWith(
      status: DoseStatus.pending,
      snoozedUntil: snoozedUntil,
    );

    await repository.updateDoseOccurrence(
      updated,
    );

    return updated;
  }
}