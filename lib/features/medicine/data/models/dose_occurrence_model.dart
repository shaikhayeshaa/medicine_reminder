import '../../domain/entities/dose_occurrence_entity.dart';
import '../../domain/entities/dose_status.dart';

class DoseOccurrenceModel {
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

  const DoseOccurrenceModel({
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

  factory DoseOccurrenceModel.fromEntity(DoseOccurrenceEntity entity) {
    return DoseOccurrenceModel(
      id: entity.id,
      medicineId: entity.medicineId,
      doseId: entity.doseId,
      scheduledAt: entity.scheduledAt,
      quantity: entity.quantity,
      unit: entity.unit,
      foodInstruction: entity.foodInstruction,
      status: entity.status,
      actionAt: entity.actionAt,
      snoozedUntil: entity.snoozedUntil,
      createdAt: entity.createdAt,
      medicineName: entity.medicineName,
      medicineDescription: entity.medicineDescription,
      medicineType: entity.medicineType,
      medicineStrength: entity.medicineStrength,
    );
  }

  DoseOccurrenceEntity toEntity() {
    return DoseOccurrenceEntity(
      id: id,
      medicineId: medicineId,
      doseId: doseId,
      scheduledAt: scheduledAt,
      quantity: quantity,
      unit: unit,
      foodInstruction: foodInstruction,
      status: status,
      actionAt: actionAt,
      snoozedUntil: snoozedUntil,
      createdAt: createdAt,
      medicineName: medicineName,
      medicineDescription: medicineDescription,
      medicineType: medicineType,
      medicineStrength: medicineStrength,
    );
  }
}
