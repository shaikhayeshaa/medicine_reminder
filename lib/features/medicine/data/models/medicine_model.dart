import '../../domain/entities/medicine_entity.dart';
import 'dose_model.dart';

class MedicineModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final String strength;
  final DateTime startDate;
  final DateTime? endDate;
  final List<DoseModel> doses;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.strength,
    required this.startDate,
    this.endDate,
    required this.doses,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicineModel.fromEntity(MedicineEntity entity) {
    return MedicineModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      type: entity.type,
      strength: entity.strength,
      startDate: entity.startDate,
      endDate: entity.endDate,
      doses: entity.doses.map((dose) => DoseModel.fromEntity(dose)).toList(),
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MedicineEntity toEntity() {
    return MedicineEntity(
      id: id,
      name: name,
      description: description,
      type: type,
      strength: strength,
      startDate: startDate,
      endDate: endDate,
      doses: doses.map((dose) => dose.toEntity()).toList(),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
