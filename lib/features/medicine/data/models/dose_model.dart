import '../../domain/entities/dose_entity.dart';

class DoseModel {
  final String id;
  final int hour;
  final int minute;
  final double quantity;
  final String unit;
  final String foodInstruction;

  const DoseModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.quantity,
    required this.unit,
    required this.foodInstruction,
  });

  factory DoseModel.fromEntity(DoseEntity entity) {
    return DoseModel(
      id: entity.id,
      hour: entity.hour,
      minute: entity.minute,
      quantity: entity.quantity,
      unit: entity.unit,
      foodInstruction: entity.foodInstruction,
    );
  }

  DoseEntity toEntity() {
    return DoseEntity(
      id: id,
      hour: hour,
      minute: minute,
      quantity: quantity,
      unit: unit,
      foodInstruction: foodInstruction,
    );
  }
}