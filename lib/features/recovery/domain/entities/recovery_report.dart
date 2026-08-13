class RecoveryReport {
  final int markedMissed;
  final int createdOccurrences;
  final int activeMedicines;

  const RecoveryReport({
    required this.markedMissed,
    required this.createdOccurrences,
    required this.activeMedicines,
  });

  static const empty = RecoveryReport(
    markedMissed: 0,
    createdOccurrences: 0,
    activeMedicines: 0,
  );
}
