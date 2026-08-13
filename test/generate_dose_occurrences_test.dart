import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/medicine_entity.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/generate_dose_occurrences.dart';

void main() {
  late GenerateDoseOccurrencesUseCase useCase;

  setUp(() {
    useCase = GenerateDoseOccurrencesUseCase();
  });

  test('generates 21 occurrences for 7 days with 3 doses per day', () {
    final medicine = MedicineEntity(
      id: 'medicine-1',
      name: 'Paracetamol',
      description: 'For fever',
      type: 'Tablet',
      strength: '500 mg',
      startDate: DateTime(2026, 8, 10),
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
      isActive: true,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

    final result = useCase(medicine: medicine);

    expect(result.length, 21);

    expect(result.first.scheduledAt, DateTime(2026, 8, 10, 8));

    expect(result.last.scheduledAt, DateTime(2026, 8, 16, 20));

    expect(
      result.every((occurrence) => occurrence.status == DoseStatus.pending),
      isTrue,
    );
  });

  test('generates all doses when start and end date are same', () {
    final medicine = MedicineEntity(
      id: 'medicine-1',
      name: 'Paracetamol',
      description: '',
      type: 'Tablet',
      strength: '500 mg',
      startDate: DateTime(2026, 8, 10),
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
          minute: 0,
          quantity: 1,
          unit: 'Tablet',
          foodInstruction: 'After Food',
        ),
        DoseEntity(
          id: 'dose-3',
          hour: 20,
          minute: 0,
          quantity: 1,
          unit: 'Tablet',
          foodInstruction: 'After Food',
        ),
      ],
      isActive: true,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );

    final result = useCase(medicine: medicine);

    expect(result.length, 3);
  });
}
