import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';
import '../../../medicine/domain/repositories/medicine_repository.dart';

class GetHistoryOccurrencesUseCase {
  final MedicineRepository repository;
  final DateTime Function() now;

  GetHistoryOccurrencesUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<List<DoseOccurrenceEntity>> call({
    DateTime? date,
  }) async {
    final occurrences = date == null
        ? await repository.getAllDoseOccurrences()
        : await repository.getDoseOccurrencesByDate(
            date,
          );

    final currentTime = now();

    final result = <DoseOccurrenceEntity>[];

    for (final occurrence in occurrences) {
      final effectiveTime =
          occurrence.snoozedUntil ??
          occurrence.scheduledAt;

      final shouldBeMissed =
          occurrence.status ==
                  DoseStatus.pending &&
              effectiveTime.isBefore(
                currentTime,
              );

      if (shouldBeMissed) {
        final updated =
            occurrence.copyWith(
          status: DoseStatus.missed,
        );

        await repository
            .updateDoseOccurrence(
          updated,
        );

        result.add(updated);
      } else {
        result.add(occurrence);
      }
    }

    result.sort(
      (a, b) => b.scheduledAt
          .compareTo(
        a.scheduledAt,
      ),
    );

    return result;
  }
}