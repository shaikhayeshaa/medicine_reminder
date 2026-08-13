import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/add_medicine.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/generate_dose_occurrences.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  test(
    'adding bounded medicine persists medicine and all 21 occurrences',
    () async {
      final repository = FakeMedicineRepository();
      final useCase = AddMedicineUseCase(
        repository: repository,
        generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
      );

      final medicine = testMedicine(
        endDate: DateTime(2026, 8, 16),
        doses: const [
          DoseEntity(
            id: 'dose-1',
            hour: 8,
            minute: 0,
            quantity: 1,
            unit: 'Tablet',
            foodInstruction: 'After Breakfast',
          ),
          DoseEntity(
            id: 'dose-2',
            hour: 13,
            minute: 0,
            quantity: 1,
            unit: 'Tablet',
            foodInstruction: 'After Lunch',
          ),
          DoseEntity(
            id: 'dose-3',
            hour: 20,
            minute: 0,
            quantity: 1,
            unit: 'Tablet',
            foodInstruction: 'After Dinner',
          ),
        ],
      );

      final created = await useCase(medicine);

      expect(repository.medicines[medicine.id], isNotNull);
      expect(created, hasLength(21));
      expect(repository.occurrences, hasLength(21));
    },
  );

  test(
    'adding ongoing future medicine creates only a 30-day rolling window',
    () async {
      final repository = FakeMedicineRepository();
      final useCase = AddMedicineUseCase(
        repository: repository,
        generateDoseOccurrences: GenerateDoseOccurrencesUseCase(),
      );

      // Intentionally far in the future so this remains deterministic regardless
      // of the date on the machine running the test.
      final medicine = testMedicine(
        startDate: DateTime(2099, 1, 1),
        endDate: null,
      );

      final created = await useCase(medicine);

      expect(created, hasLength(30));
      expect(created.first.scheduledAt, DateTime(2099, 1, 1, 8));
      expect(created.last.scheduledAt, DateTime(2099, 1, 30, 8));
    },
  );
}
