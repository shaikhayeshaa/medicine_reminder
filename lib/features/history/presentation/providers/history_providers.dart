import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';
import '../../domain/entities/history_status_filter.dart';
import '../../domain/usecases/get_history_occurrences.dart';

final getHistoryOccurrencesUseCaseProvider =
    Provider<GetHistoryOccurrencesUseCase>((ref) {
      final repository = ref.watch(medicineRepositoryProvider);

      return GetHistoryOccurrencesUseCase(repository: repository);
    });

class HistoryDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void clear() {
    state = null;
  }
}

final historyDateProvider = NotifierProvider<HistoryDateNotifier, DateTime?>(
  HistoryDateNotifier.new,
);

//null → All Dates

class HistoryStatusFilterNotifier extends Notifier<HistoryStatusFilter> {
  @override
  HistoryStatusFilter build() {
    return HistoryStatusFilter.all;
  }

  void select(HistoryStatusFilter filter) {
    state = filter;
  }
}

final historyStatusFilterProvider =
    NotifierProvider<HistoryStatusFilterNotifier, HistoryStatusFilter>(
      HistoryStatusFilterNotifier.new,
    );

final historyOccurrencesProvider = FutureProvider<List<DoseOccurrenceEntity>>((
  ref,
) async {
  final selectedDate = ref.watch(historyDateProvider);

  // Taken / Skip / Snooze ke baad
  // automatically reload.
  ref.watch(doseOccurrenceRevisionProvider);

  final useCase = ref.watch(getHistoryOccurrencesUseCaseProvider);

  return useCase(date: selectedDate);
});

final historyStatusFilteredProvider =
    Provider<AsyncValue<List<DoseOccurrenceEntity>>>((ref) {
      final occurrences = ref.watch(historyOccurrencesProvider);

      final filter = ref.watch(historyStatusFilterProvider);

      return occurrences.whenData((items) {
        return items
            .where((occurrence) => matchesHistoryStatus(occurrence, filter))
            .toList();
      });
    });
