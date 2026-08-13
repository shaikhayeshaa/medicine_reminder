import 'dose_occurrence_entity.dart';

/// Result returned by edit/resume operations.
///
/// [cancelledOccurrences] are old future pending reminders that must be
/// removed from the operating system.
/// [createdOccurrences] are the newly generated future reminders.
class MedicineScheduleChangeResult {
  final List<DoseOccurrenceEntity> cancelledOccurrences;
  final List<DoseOccurrenceEntity> createdOccurrences;

  const MedicineScheduleChangeResult({
    this.cancelledOccurrences = const [],
    this.createdOccurrences = const [],
  });
}
