import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/generate_dose_occurrences.dart';

import 'support/fixtures.dart';

void main() {
  late GenerateDoseOccurrencesUseCase useCase;

  setUp(() {
    useCase = GenerateDoseOccurrencesUseCase();
  });

  test('generates 21 occurrences for 10-16 Aug with 3 doses per day', () {
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

    final result = useCase(medicine: medicine);

    expect(result, hasLength(21));
    expect(result.first.scheduledAt, DateTime(2026, 8, 10, 8));
    expect(result.last.scheduledAt, DateTime(2026, 8, 16, 20));
    expect(
      result.every((occurrence) => occurrence.status == DoseStatus.pending),
      isTrue,
    );
  });

  test('generates every configured dose when start and end date are same', () {
    final medicine = testMedicine(
      endDate: DateTime(2026, 8, 10),
      doses: const [
        DoseEntity(
          id: 'dose-1',
          hour: 8,
          minute: 0,
          quantity: 1,
          unit: 'Tablet',
          foodInstruction: 'After Food',
        ),
        DoseEntity(
          id: 'dose-2',
          hour: 13,
          minute: 15,
          quantity: 2,
          unit: 'Tablet',
          foodInstruction: 'Before Food',
        ),
        DoseEntity(
          id: 'dose-3',
          hour: 20,
          minute: 45,
          quantity: 5,
          unit: 'ml',
          foodInstruction: 'After Dinner',
        ),
      ],
    );

    final result = useCase(medicine: medicine);

    expect(result, hasLength(3));
    expect(result.map((item) => item.scheduledAt.minute), [0, 15, 45]);
    expect(result[2].quantity, 5);
    expect(result[2].unit, 'ml');
  });

  test('ongoing medicine requires a bounded until date', () {
    final medicine = testMedicine(endDate: null);

    expect(() => useCase(medicine: medicine), throwsArgumentError);
  });

  test('ongoing medicine can generate a safe 30-day rolling window', () {
    final medicine = testMedicine(endDate: null);

    final result = useCase(
      medicine: medicine,
      from: DateTime(2026, 8, 10),
      until: DateTime(2026, 9, 8),
    );

    expect(result, hasLength(30));
    expect(result.first.scheduledAt, DateTime(2026, 8, 10, 8));
    expect(result.last.scheduledAt, DateTime(2026, 9, 8, 8));
  });

  test(
    'occurrence IDs are deterministic so recovery does not duplicate doses',
    () {
      final medicine = testMedicine(endDate: DateTime(2026, 8, 11));

      final first = useCase(medicine: medicine);
      final second = useCase(medicine: medicine);

      expect(first.map((item) => item.id), second.map((item) => item.id));
    },
  );

  test('historical snapshot is copied from medicine at generation time', () {
    final medicine = testMedicine(
      strength: '500 mg',
      endDate: DateTime(2026, 8, 10),
    );

    final result = useCase(medicine: medicine);

    expect(result.single.medicineName, 'Paracetamol');
    expect(result.single.medicineDescription, 'For fever and pain');
    expect(result.single.medicineType, 'Tablet');
    expect(result.single.medicineStrength, '500 mg');
  });
}
