import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';

class DashboardStats {
  final int total;
  final int pending;
  final int taken;
  final int missed;
  final int skipped;

  const DashboardStats({
    required this.total,
    required this.pending,
    required this.taken,
    required this.missed,
    required this.skipped,
  });

  factory DashboardStats.fromOccurrences(
    List<DoseOccurrenceEntity> occurrences,
  ) {
    var pending = 0;
    var taken = 0;
    var missed = 0;
    var skipped = 0;

    for (final occurrence in occurrences) {
      switch (occurrence.status) {
        case DoseStatus.pending:
          pending++;

        case DoseStatus.taken:
          taken++;

        case DoseStatus.missed:
          missed++;

        case DoseStatus.skipped:
          skipped++;
      }
    }

    return DashboardStats(
      total: occurrences.length,
      pending: pending,
      taken: taken,
      missed: missed,
      skipped: skipped,
    );
  }
}
