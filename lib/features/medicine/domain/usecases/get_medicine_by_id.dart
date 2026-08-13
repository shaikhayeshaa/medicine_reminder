import '../entities/medicine_entity.dart';
import '../repositories/medicine_repository.dart';

/// Loads one medicine without exposing Hive to the presentation layer.
class GetMedicineByIdUseCase {
  final MedicineRepository repository;

  const GetMedicineByIdUseCase({required this.repository});

  Future<MedicineEntity?> call(String medicineId) {
    return repository.getMedicineById(medicineId);
  }
}
