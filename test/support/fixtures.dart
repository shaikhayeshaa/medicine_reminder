import 'package:medicine_reminder/features/medicine/domain/entities/dose_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_occurrence_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/medicine_entity.dart';

MedicineEntity testMedicine({
  String id = 'medicine-1',
  String name = 'Paracetamol',
  String description = 'For fever and pain',
  String type = 'Tablet',
  String strength = '500 mg',
  DateTime? startDate,
  DateTime? endDate,
  List<DoseEntity>? doses,
  bool isActive = true,
}) {
  final start = startDate ?? DateTime(2026, 8, 10);

  return MedicineEntity(
    id: id,
    name: name,
    description: description,
    type: type,
    strength: strength,
    startDate: start,
    endDate: endDate,
    doses:
        doses ??
        const [
          DoseEntity(
            id: 'dose-1',
            hour: 8,
            minute: 0,
            quantity: 1,
            unit: 'Tablet',
            foodInstruction: 'After Breakfast',
          ),
        ],
    isActive: isActive,
    createdAt: start,
    updatedAt: start,
  );
}

DoseOccurrenceEntity testOccurrence({
  String id = 'occurrence-1',
  String medicineId = 'medicine-1',
  String doseId = 'dose-1',
  DateTime? scheduledAt,
  double quantity = 1,
  String unit = 'Tablet',
  String foodInstruction = 'After Food',
  DoseStatus status = DoseStatus.pending,
  DateTime? actionAt,
  DateTime? snoozedUntil,
  String medicineName = 'Paracetamol',
  String medicineDescription = 'For fever and pain',
  String medicineType = 'Tablet',
  String medicineStrength = '500 mg',
}) {
  final scheduled = scheduledAt ?? DateTime(2026, 8, 10, 8);

  return DoseOccurrenceEntity(
    id: id,
    medicineId: medicineId,
    doseId: doseId,
    scheduledAt: scheduled,
    quantity: quantity,
    unit: unit,
    foodInstruction: foodInstruction,
    status: status,
    actionAt: actionAt,
    snoozedUntil: snoozedUntil,
    createdAt: DateTime(2026, 8, 1),
    medicineName: medicineName,
    medicineDescription: medicineDescription,
    medicineType: medicineType,
    medicineStrength: medicineStrength,
  );
}
