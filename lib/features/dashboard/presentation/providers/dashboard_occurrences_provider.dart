import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicine_reminder/features/medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';
import 'dashboard_date_provider.dart';

final dashboardOccurrencesProvider = FutureProvider<List<DoseOccurrenceEntity>>(
  (ref) async {
    ref.watch(doseOccurrenceRevisionProvider);

    final selectedDate = ref.watch(dashboardDateProvider);

    final useCase = ref.watch(getDoseOccurrencesByDateUseCaseProvider);

    return useCase(selectedDate);
  },
);
