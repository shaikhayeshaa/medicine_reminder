import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/snooze_option.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/mark_dose_taken.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/skip_dose.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/snooze_dose.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  group('Dose actions', () {
    late FakeMedicineRepository repository;
    final actionTime = DateTime(2026, 8, 10, 8, 7);

    setUp(() {
      repository = FakeMedicineRepository();
    });

    test('Taken stores taken status and actual action time', () async {
      final occurrence = testOccurrence();
      repository.occurrences[occurrence.id] = occurrence;

      final useCase = MarkDoseTakenUseCase(
        repository: repository,
        now: () => actionTime,
      );

      final updated = await useCase(occurrence);

      expect(updated.status, DoseStatus.taken);
      expect(updated.actionAt, actionTime);
      expect(repository.occurrences[occurrence.id]?.status, DoseStatus.taken);
      expect(repository.updateDoseOccurrenceCalls, 1);
    });

    test('Skip stores skipped status and actual action time', () async {
      final occurrence = testOccurrence();
      repository.occurrences[occurrence.id] = occurrence;

      final useCase = SkipDoseUseCase(
        repository: repository,
        now: () => actionTime,
      );

      final updated = await useCase(occurrence);

      expect(updated.status, DoseStatus.skipped);
      expect(updated.actionAt, actionTime);
      expect(repository.occurrences[occurrence.id]?.status, DoseStatus.skipped);
    });

    for (final option in SnoozeOption.values) {
      test(
        'Snooze ${option.minutes} minutes changes only one occurrence',
        () async {
          final first = testOccurrence(id: 'occurrence-1');
          final second = testOccurrence(
            id: 'occurrence-2',
            doseId: 'dose-2',
            scheduledAt: DateTime(2026, 8, 10, 13),
          );
          repository.occurrences[first.id] = first;
          repository.occurrences[second.id] = second;

          final useCase = SnoozeDoseUseCase(
            repository: repository,
            now: () => actionTime,
          );

          final updated = await useCase(occurrence: first, option: option);

          expect(updated.status, DoseStatus.pending);
          expect(
            updated.snoozedUntil,
            actionTime.add(Duration(minutes: option.minutes)),
          );
          expect(repository.occurrences[second.id]?.snoozedUntil, isNull);
        },
      );
    }

    test('a just-missed dose can be snoozed back to pending', () async {
      final missed = testOccurrence(status: DoseStatus.missed);

      final useCase = SnoozeDoseUseCase(
        repository: repository,
        now: () => actionTime,
      );

      final updated = await useCase(
        occurrence: missed,
        option: SnoozeOption.tenMinutes,
      );

      expect(updated.status, DoseStatus.pending);
      expect(updated.snoozedUntil, DateTime(2026, 8, 10, 8, 17));
    });

    test('completed dose cannot be snoozed', () async {
      final taken = testOccurrence(status: DoseStatus.taken);
      final useCase = SnoozeDoseUseCase(
        repository: repository,
        now: () => actionTime,
      );

      await expectLater(
        useCase(occurrence: taken, option: SnoozeOption.fiveMinutes),
        throwsStateError,
      );
    });
  });
}
