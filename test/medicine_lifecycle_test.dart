import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/delete_medicine.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/generate_dose_occurrences.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/pause_medicine.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/resume_medicine.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/stop_medicine.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/update_medicine.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 10, 10);

  group('Medicine lifecycle', () {
    late FakeMedicineRepository repository;

    setUp(() {
      repository = FakeMedicineRepository();
    });

    test(
      'editing medicine preserves historical snapshot and regenerates future pending schedule',
      () async {
        final originalMedicine = testMedicine(
          strength: '500 mg',
          endDate: DateTime(2026, 8, 11),
        );
        repository.medicines[originalMedicine.id] = originalMedicine;

        final takenHistory = testOccurrence(
          id: 'history-taken',
          scheduledAt: DateTime(2026, 8, 10, 8),
          status: DoseStatus.taken,
          actionAt: DateTime(2026, 8, 10, 8, 3),
          medicineStrength: '500 mg',
        );
        final futurePending = testOccurrence(
          id: 'future-pending',
          scheduledAt: DateTime(2026, 8, 11, 8),
          medicineStrength: '500 mg',
        );
        repository.occurrences[takenHistory.id] = takenHistory;
        repository.occurrences[futurePending.id] = futurePending;

        final editedMedicine = testMedicine(
          strength: '1000 mg',
          endDate: DateTime(2026, 8, 11),
        );

        final useCase = UpdateMedicineUseCase(
          repository: repository,
          generateOccurrences: GenerateDoseOccurrencesUseCase(),
          now: () => now,
        );

        final result = await useCase(editedMedicine);

        final preserved = repository.occurrences[takenHistory.id];
        expect(preserved, isNotNull);
        expect(preserved?.status, DoseStatus.taken);
        expect(preserved?.medicineStrength, '500 mg');
        expect(repository.occurrences.containsKey(futurePending.id), isFalse);
        expect(
          result.cancelledOccurrences.map((item) => item.id),
          contains(futurePending.id),
        );
        expect(result.createdOccurrences, isNotEmpty);
        expect(
          result.createdOccurrences.every(
            (item) => item.medicineStrength == '1000 mg',
          ),
          isTrue,
        );
      },
    );

    test(
      'delete removes medicine and future pending doses but preserves history',
      () async {
        final medicine = testMedicine(endDate: null);
        repository.medicines[medicine.id] = medicine;

        final history = testOccurrence(
          id: 'history',
          scheduledAt: DateTime(2026, 8, 10, 8),
          status: DoseStatus.skipped,
          actionAt: DateTime(2026, 8, 10, 8, 1),
        );
        final future = testOccurrence(
          id: 'future',
          scheduledAt: DateTime(2026, 8, 10, 13),
        );
        repository.occurrences[history.id] = history;
        repository.occurrences[future.id] = future;

        final useCase = DeleteMedicineUseCase(
          repository: repository,
          now: () => now,
        );

        final cancelled = await useCase(medicine.id);

        expect(repository.medicines.containsKey(medicine.id), isFalse);
        expect(repository.occurrences[history.id]?.status, DoseStatus.skipped);
        expect(repository.occurrences.containsKey(future.id), isFalse);
        expect(cancelled.map((item) => item.id), ['future']);
      },
    );

    test(
      'pause makes medicine inactive and removes only future pending doses',
      () async {
        final medicine = testMedicine(endDate: null);
        repository.medicines[medicine.id] = medicine;
        repository.occurrences['history'] = testOccurrence(
          id: 'history',
          scheduledAt: DateTime(2026, 8, 10, 8),
          status: DoseStatus.taken,
        );
        repository.occurrences['future'] = testOccurrence(
          id: 'future',
          scheduledAt: DateTime(2026, 8, 10, 13),
        );

        final useCase = PauseMedicineUseCase(
          repository: repository,
          now: () => now,
        );

        await useCase(medicine.id);

        expect(repository.medicines[medicine.id]?.isActive, isFalse);
        expect(repository.occurrences.containsKey('history'), isTrue);
        expect(repository.occurrences.containsKey('future'), isFalse);
      },
    );

    test(
      'resume regenerates a bounded future schedule for ongoing medicine',
      () async {
        final paused = testMedicine(endDate: null, isActive: false);
        repository.medicines[paused.id] = paused;

        final useCase = ResumeMedicineUseCase(
          repository: repository,
          generateOccurrences: GenerateDoseOccurrencesUseCase(),
          now: () => now,
        );

        final result = await useCase(paused.id);

        expect(repository.medicines[paused.id]?.isActive, isTrue);
        expect(result.createdOccurrences, hasLength(29));
        expect(
          result.createdOccurrences.first.scheduledAt,
          DateTime(2026, 8, 11, 8),
        );
        expect(
          result.createdOccurrences.last.scheduledAt,
          DateTime(2026, 9, 8, 8),
        );
      },
    );

    test(
      'stop closes treatment today, deactivates it and preserves history',
      () async {
        final medicine = testMedicine(endDate: null);
        repository.medicines[medicine.id] = medicine;
        repository.occurrences['history'] = testOccurrence(
          id: 'history',
          scheduledAt: DateTime(2026, 8, 10, 8),
          status: DoseStatus.taken,
        );
        repository.occurrences['future'] = testOccurrence(
          id: 'future',
          scheduledAt: DateTime(2026, 8, 10, 13),
        );

        final useCase = StopMedicineUseCase(
          repository: repository,
          now: () => now,
        );

        await useCase(medicine.id);

        final stopped = repository.medicines[medicine.id];
        expect(stopped?.isActive, isFalse);
        expect(stopped?.endDate, DateTime(2026, 8, 10));
        expect(repository.occurrences.containsKey('history'), isTrue);
        expect(repository.occurrences.containsKey('future'), isFalse);
      },
    );
  });
}
