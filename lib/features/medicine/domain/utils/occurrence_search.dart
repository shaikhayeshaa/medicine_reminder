import '../entities/dose_occurrence_entity.dart';

/// Shared case-insensitive search rule used by Dashboard and History.
///
/// Keeping it outside widgets makes the PDF search requirement directly
/// testable and avoids the two screens drifting apart over time.
bool occurrenceMatchesSearch(DoseOccurrenceEntity occurrence, String query) {
  final normalized = query.trim().toLowerCase();

  if (normalized.isEmpty) {
    return true;
  }

  return occurrence.medicineName.toLowerCase().contains(normalized) ||
      occurrence.medicineDescription.toLowerCase().contains(normalized) ||
      occurrence.medicineType.toLowerCase().contains(normalized);
}
