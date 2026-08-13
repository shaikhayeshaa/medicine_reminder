import '../entities/dose_occurrence_entity.dart';
import '../entities/dose_status.dart';
import '../entities/medicine_entity.dart';

class GenerateDoseOccurrencesUseCase {
  List<DoseOccurrenceEntity> call({
    required MedicineEntity medicine,
    DateTime? from,
    DateTime? until,
  }) {
    if (!medicine.isActive || medicine.doses.isEmpty) {
      return [];
    }

    final treatmentStart = _dateOnly(medicine.startDate);

    final treatmentEnd = medicine.endDate != null
        ? _dateOnly(medicine.endDate!)
        : null;

    if (treatmentEnd != null && treatmentEnd.isBefore(treatmentStart)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    // For ongoing medicine we MUST provide a safe future limit.
    if (treatmentEnd == null && until == null) {
      throw ArgumentError('until is required for an ongoing medicine.');
    }

    final requestedStart = from != null ? _dateOnly(from) : treatmentStart;

    final generationStart = requestedStart.isAfter(treatmentStart)
        ? requestedStart
        : treatmentStart;

    DateTime generationEnd;

    if (treatmentEnd != null && until != null) {
      final requestedEnd = _dateOnly(until);

      generationEnd = requestedEnd.isBefore(treatmentEnd)
          ? requestedEnd
          : treatmentEnd;
    } else {
      generationEnd = treatmentEnd ?? _dateOnly(until!);
    }

    if (generationEnd.isBefore(generationStart)) {
      return [];
    }

    final occurrences = <DoseOccurrenceEntity>[];
    final createdAt = DateTime.now();

    var currentDate = generationStart;

    while (!currentDate.isAfter(generationEnd)) {
      for (final dose in medicine.doses) {
        final scheduledAt = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          dose.hour,
          dose.minute,
        );

        // Useful when regenerating future occurrences
        // after a medicine edit.
        if (from != null && scheduledAt.isBefore(from)) {
          continue;
        }

        final occurrenceId =
            '${medicine.id}_${dose.id}_${scheduledAt.millisecondsSinceEpoch}';

        occurrences.add(
          DoseOccurrenceEntity(
            id: occurrenceId,
            medicineId: medicine.id,
            doseId: dose.id,
            scheduledAt: scheduledAt,
            quantity: dose.quantity,
            unit: dose.unit,
            foodInstruction: dose.foodInstruction,
            status: DoseStatus.pending,
            actionAt: null,
            snoozedUntil: null,
            createdAt: createdAt,

            // Historical snapshot
            medicineName: medicine.name,
            medicineDescription: medicine.description,
            medicineType: medicine.type,
            medicineStrength: medicine.strength,
          ),
        );
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    occurrences.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return occurrences;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
