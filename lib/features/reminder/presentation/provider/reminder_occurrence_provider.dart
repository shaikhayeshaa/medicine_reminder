import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';

final reminderOccurrenceProvider = FutureProvider.autoDispose
    .family<DoseOccurrenceEntity?, String>((ref, occurrenceId) async {
      // Dose action ke baad provider refresh hoga.
      ref.watch(doseOccurrenceRevisionProvider);

      final useCase = ref.watch(getDoseOccurrenceByIdUseCaseProvider);

      return useCase(occurrenceId);
    });
