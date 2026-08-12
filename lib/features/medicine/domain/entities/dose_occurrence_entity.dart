import 'dose_status.dart';

class DoseOccurrenceEntity {
  final String id;

  final String medicineId;
  final String doseId;

  final DateTime scheduledAt;

  final double quantity;
  final String unit;
  final String foodInstruction;

  final DoseStatus status;

  final DateTime? actionAt;
  final DateTime? snoozedUntil;

  final DateTime createdAt;

  // Historical snapshot
  final String medicineName;
  final String medicineDescription;
  final String medicineType;
  final String medicineStrength;

  const DoseOccurrenceEntity({
    required this.id,
    required this.medicineId,
    required this.doseId,
    required this.scheduledAt,
    required this.quantity,
    required this.unit,
    required this.foodInstruction,
    required this.status,
    this.actionAt,
    this.snoozedUntil,
    required this.createdAt,
    required this.medicineName,
    required this.medicineDescription,
    required this.medicineType,
    required this.medicineStrength,
  });
}