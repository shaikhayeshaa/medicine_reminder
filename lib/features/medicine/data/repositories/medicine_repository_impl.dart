import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';

import '../../domain/entities/dose_occurrence_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/medicine_local_datasource.dart';
import '../models/dose_occurrence_model.dart';
import '../models/medicine_model.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  final MedicineLocalDataSource localDataSource;

  MedicineRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addMedicine(MedicineEntity medicine) async {
    final model = MedicineModel.fromEntity(medicine);

    await localDataSource.addMedicine(model);
  }

  @override
  Future<List<MedicineEntity>> getAllMedicines() async {
    final models = await localDataSource.getAllMedicines();

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<MedicineEntity?> getMedicineById(String id) async {
    final model = await localDataSource.getMedicineById(id);

    return model?.toEntity();
  }

  @override
  Future<void> updateMedicine(MedicineEntity medicine) async {
    final model = MedicineModel.fromEntity(medicine);

    await localDataSource.updateMedicine(model);
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    await localDataSource.deleteMedicine(medicineId);
  }

  @override
  Future<void> saveDoseOccurrences(
    List<DoseOccurrenceEntity> occurrences,
  ) async {
    final models = occurrences
        .map((occurrence) => DoseOccurrenceModel.fromEntity(occurrence))
        .toList();

    await localDataSource.saveDoseOccurrences(models);
  }

  @override
  Future<List<DoseOccurrenceEntity>> getAllDoseOccurrences() async {
    final models = await localDataSource.getAllDoseOccurrences();

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByMedicineId(
    String medicineId,
  ) async {
    final models = await localDataSource.getDoseOccurrencesByMedicineId(
      medicineId,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<DoseOccurrenceEntity>> getDoseOccurrencesByDate(
    DateTime date,
  ) async {
    final models = await localDataSource.getDoseOccurrencesByDate(date);

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateDoseOccurrence(DoseOccurrenceEntity occurrence) async {
    final model = DoseOccurrenceModel.fromEntity(occurrence);

    await localDataSource.updateDoseOccurrence(model);
  }

  @override
  Future<void> deleteFutureOccurrencesForMedicine(
    String medicineId,
    DateTime from,
  ) async {
    // Repository Hive ko directly access nahi karta.
    // Actual deletion logic local datasource handle karega.
    await localDataSource.deleteFutureOccurrencesForMedicine(medicineId, from);
  }

  @override
  Future<DoseOccurrenceEntity?> getDoseOccurrenceById(
    String occurrenceId,
  ) async {
    final model = await localDataSource.getDoseOccurrenceById(occurrenceId);

    return model?.toEntity();
  }
}
