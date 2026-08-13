import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../entities/medicine_entity.dart';
import '../entities/medicine_schedule_change_result.dart';
import '../repositories/medicine_repository.dart';
import 'generate_dose_occurrences.dart';

/// Updates a medicine while preserving immutable historical occurrences.
///
/// Only FUTURE PENDING occurrences are removed and regenerated. Taken,
/// skipped and missed history is never rewritten.
class UpdateMedicineUseCase {
  final MedicineRepository repository;
  final GenerateDoseOccurrencesUseCase generateOccurrences;
  final DateTime Function() now;

  UpdateMedicineUseCase({
    required this.repository,
    required this.generateOccurrences,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<MedicineScheduleChangeResult> call(
    MedicineEntity updatedMedicine,
  ) async {
    final currentTime = now();

    // Read the old schedule before changing anything so its OS notifications
    // can be cancelled by the presentation/application layer.
    final existingOccurrences =
        await repository.getDoseOccurrencesByMedicineId(
      updatedMedicine.id,
    );

    final futurePending = existingOccurrences
        .where(
          (occurrence) =>
              occurrence.status == DoseStatus.pending &&
              !_effectiveTime(occurrence)
                  .isBefore(currentTime),
        )
        .toList();

    // Persist the new medicine definition.
    await repository.updateMedicine(updatedMedicine);

    // Remove only future pending occurrences.
    // Historical Taken/Missed/Skipped records remain untouched.
    await repository.deleteFutureOccurrencesForMedicine(
      updatedMedicine.id,
      currentTime,
    );

    if (!updatedMedicine.isActive) {
      return MedicineScheduleChangeResult(
        cancelledOccurrences: futurePending,
      );
    }

    final generationEnd = _generationEnd(
      medicine: updatedMedicine,
      from: currentTime,
    );

    // Treatment already completed.
    if (generationEnd == null) {
      return MedicineScheduleChangeResult(
        cancelledOccurrences: futurePending,
      );
    }

    final generated = generateOccurrences(
      medicine: updatedMedicine,
      from: currentTime,
      until: generationEnd,
    );

    await repository.saveDoseOccurrences(generated);

    return MedicineScheduleChangeResult(
      cancelledOccurrences: futurePending,
      createdOccurrences: generated,
    );
  }

  DateTime _effectiveTime(
    DoseOccurrenceEntity occurrence,
  ) {
    return occurrence.snoozedUntil ??
        occurrence.scheduledAt;
  }

  /// Bounded medicines generate only until their end date.
  /// Ongoing medicines use the same safe 30-day rolling window used by
  /// medicine creation.
  DateTime? _generationEnd({
    required MedicineEntity medicine,
    required DateTime from,
  }) {
    if (medicine.endDate != null) {
      final end = DateTime(
        medicine.endDate!.year,
        medicine.endDate!.month,
        medicine.endDate!.day,
        23,
        59,
        59,
      );

      if (end.isBefore(from)) {
        return null;
      }

      return end;
    }

    return DateTime(
      from.year,
      from.month,
      from.day,
    ).add(
      const Duration(days: 29),
    );
  }
}
