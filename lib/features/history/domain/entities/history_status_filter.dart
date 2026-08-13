import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';

enum HistoryStatusFilter { all, taken, missed, skipped }

/// Pure filter rule shared by the provider and unit tests.
bool matchesHistoryStatus(
  DoseOccurrenceEntity occurrence,
  HistoryStatusFilter filter,
) {
  return switch (filter) {
    HistoryStatusFilter.all => true,
    HistoryStatusFilter.taken => occurrence.status == DoseStatus.taken,
    HistoryStatusFilter.missed => occurrence.status == DoseStatus.missed,
    HistoryStatusFilter.skipped => occurrence.status == DoseStatus.skipped,
  };
}
