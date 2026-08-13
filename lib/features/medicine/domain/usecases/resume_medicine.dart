import '../entities/medicine_entity.dart';
import '../entities/medicine_schedule_change_result.dart';
import '../repositories/medicine_repository.dart';
import 'generate_dose_occurrences.dart';

/// Resumes a paused medicine and rebuilds a safe future schedule.
class ResumeMedicineUseCase {
  final MedicineRepository repository;
  final GenerateDoseOccurrencesUseCase generateOccurrences;
  final DateTime Function() now;

  ResumeMedicineUseCase({
    required this.repository,
    required this.generateOccurrences,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<MedicineScheduleChangeResult> call(
    String medicineId,
  ) async {
    final medicine =
        await repository.getMedicineById(medicineId);

    if (medicine == null) {
      throw StateError('Medicine not found.');
    }

    final currentTime = now();

    // A stopped/completed medicine cannot be resumed.
    if (medicine.endDate != null) {
      final endOfDay = DateTime(
        medicine.endDate!.year,
        medicine.endDate!.month,
        medicine.endDate!.day,
        23,
        59,
        59,
      );

      if (!endOfDay.isAfter(currentTime)) {
        throw StateError(
          'Stopped or completed medicine cannot be resumed.',
        );
      }
    }

    final resumedMedicine = _copyMedicine(
      medicine,
      isActive: true,
      updatedAt: currentTime,
    );

    await repository.updateMedicine(resumedMedicine);

    final generationEnd = medicine.endDate ??
        DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
        ).add(
          const Duration(days: 29),
        );

    final generated = generateOccurrences(
      medicine: resumedMedicine,
      from: currentTime,
      until: generationEnd,
    );

    await repository.saveDoseOccurrences(generated);

    return MedicineScheduleChangeResult(
      createdOccurrences: generated,
    );
  }

  MedicineEntity _copyMedicine(
    MedicineEntity medicine, {
    required bool isActive,
    required DateTime updatedAt,
  }) {
    return MedicineEntity(
      id: medicine.id,
      name: medicine.name,
      description: medicine.description,
      type: medicine.type,
      strength: medicine.strength,
      startDate: medicine.startDate,
      endDate: medicine.endDate,
      doses: medicine.doses,
      isActive: isActive,
      createdAt: medicine.createdAt,
      updatedAt: updatedAt,
    );
  }
}
