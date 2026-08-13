import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:medicine_reminder/features/history/domain/entities/history_status_filter.dart';
import 'package:medicine_reminder/features/history/domain/usecases/get_history_occurrences.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';

import 'support/fakes.dart';
import 'support/fixtures.dart';

void main() {
  test('dashboard statistics are calculated from individual occurrences', () {
    final occurrences = [
      testOccurrence(id: 'pending', status: DoseStatus.pending),
      testOccurrence(id: 'taken-1', status: DoseStatus.taken),
      testOccurrence(id: 'taken-2', status: DoseStatus.taken),
      testOccurrence(id: 'missed', status: DoseStatus.missed),
      testOccurrence(id: 'skipped', status: DoseStatus.skipped),
    ];

    final stats = DashboardStats.fromOccurrences(occurrences);

    expect(stats.total, 5);
    expect(stats.pending, 1);
    expect(stats.taken, 2);
    expect(stats.missed, 1);
    expect(stats.skipped, 1);
  });

  test('history status filters match All/Taken/Missed/Skipped correctly', () {
    final taken = testOccurrence(status: DoseStatus.taken);
    final missed = testOccurrence(status: DoseStatus.missed);
    final skipped = testOccurrence(status: DoseStatus.skipped);

    expect(matchesHistoryStatus(taken, HistoryStatusFilter.all), isTrue);
    expect(matchesHistoryStatus(taken, HistoryStatusFilter.taken), isTrue);
    expect(matchesHistoryStatus(taken, HistoryStatusFilter.missed), isFalse);
    expect(matchesHistoryStatus(missed, HistoryStatusFilter.missed), isTrue);
    expect(matchesHistoryStatus(skipped, HistoryStatusFilter.skipped), isTrue);
  });

  group('History', () {
    late FakeMedicineRepository repository;
    final now = DateTime(2026, 8, 10, 12);

    setUp(() {
      repository = FakeMedicineRepository();
    });

    test('past pending occurrence automatically becomes missed', () async {
      final overdue = testOccurrence(
        id: 'overdue',
        scheduledAt: DateTime(2026, 8, 10, 8),
      );
      repository.occurrences[overdue.id] = overdue;

      final useCase = GetHistoryOccurrencesUseCase(
        repository: repository,
        now: () => now,
      );

      final history = await useCase();

      expect(history, hasLength(1));
      expect(history.single.status, DoseStatus.missed);
      expect(repository.occurrences[overdue.id]?.status, DoseStatus.missed);
    });

    test('snoozed pending dose is not missed before snoozedUntil', () async {
      final snoozed = testOccurrence(
        id: 'snoozed',
        scheduledAt: DateTime(2026, 8, 10, 8),
        snoozedUntil: DateTime(2026, 8, 10, 12, 10),
      );
      repository.occurrences[snoozed.id] = snoozed;

      final useCase = GetHistoryOccurrencesUseCase(
        repository: repository,
        now: () => now,
      );

      final history = await useCase();

      expect(history, isEmpty);
      expect(repository.occurrences[snoozed.id]?.status, DoseStatus.pending);
    });

    test('future pending occurrences stay out of history', () async {
      final future = testOccurrence(
        id: 'future',
        scheduledAt: DateTime(2026, 8, 10, 13),
      );
      repository.occurrences[future.id] = future;

      final useCase = GetHistoryOccurrencesUseCase(
        repository: repository,
        now: () => now,
      );

      final history = await useCase();

      expect(history, isEmpty);
    });

    test('completed history is returned newest first', () async {
      repository.occurrences.addAll({
        'taken': testOccurrence(
          id: 'taken',
          scheduledAt: DateTime(2026, 8, 9, 8),
          status: DoseStatus.taken,
        ),
        'skipped': testOccurrence(
          id: 'skipped',
          scheduledAt: DateTime(2026, 8, 10, 9),
          status: DoseStatus.skipped,
        ),
      });

      final useCase = GetHistoryOccurrencesUseCase(
        repository: repository,
        now: () => now,
      );

      final history = await useCase();

      expect(history.map((item) => item.id), ['skipped', 'taken']);
    });

    test(
      'history date filter returns only occurrences for the selected day',
      () async {
        repository.occurrences.addAll({
          'aug-10': testOccurrence(
            id: 'aug-10',
            scheduledAt: DateTime(2026, 8, 10, 8),
            status: DoseStatus.taken,
          ),
          'aug-11': testOccurrence(
            id: 'aug-11',
            scheduledAt: DateTime(2026, 8, 11, 8),
            status: DoseStatus.taken,
          ),
        });

        final useCase = GetHistoryOccurrencesUseCase(
          repository: repository,
          now: () => DateTime(2026, 8, 12),
        );

        final history = await useCase(date: DateTime(2026, 8, 10));

        expect(history.map((item) => item.id), ['aug-10']);
      },
    );
  });
}
