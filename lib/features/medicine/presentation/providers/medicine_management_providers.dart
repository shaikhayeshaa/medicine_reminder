import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/dose_occurrence_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../../domain/usecases/delete_medicine.dart';
import '../../domain/usecases/get_medicine_by_id.dart';
import '../../domain/usecases/pause_medicine.dart';
import '../../domain/usecases/resume_medicine.dart';
import '../../domain/usecases/stop_medicine.dart';
import '../../domain/usecases/update_medicine.dart';
import 'dose_occurrence_revision_provider.dart';
import 'medicine_notifier.dart';
import 'medicine_providers.dart';

final getMedicineByIdUseCaseProvider =
    Provider<GetMedicineByIdUseCase>((ref) {
  return GetMedicineByIdUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
  );
});

final updateMedicineUseCaseProvider =
    Provider<UpdateMedicineUseCase>((ref) {
  return UpdateMedicineUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
    generateOccurrences: ref.watch(
      generateDoseOccurrencesUseCaseProvider,
    ),
  );
});

final deleteMedicineUseCaseProvider =
    Provider<DeleteMedicineUseCase>((ref) {
  return DeleteMedicineUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
  );
});

final pauseMedicineUseCaseProvider =
    Provider<PauseMedicineUseCase>((ref) {
  return PauseMedicineUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
  );
});

final resumeMedicineUseCaseProvider =
    Provider<ResumeMedicineUseCase>((ref) {
  return ResumeMedicineUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
    generateOccurrences: ref.watch(
      generateDoseOccurrencesUseCaseProvider,
    ),
  );
});

final stopMedicineUseCaseProvider =
    Provider<StopMedicineUseCase>((ref) {
  return StopMedicineUseCase(
    repository: ref.watch(
      medicineRepositoryProvider,
    ),
  );
});

/// Loads one medicine for Edit/management screens.
final medicineByIdProvider = FutureProvider.autoDispose
    .family<MedicineEntity?, String>(
  (ref, medicineId) async {
    final useCase = ref.watch(
      getMedicineByIdUseCaseProvider,
    );

    return useCase(medicineId);
  },
);

/// Coordinates Hive medicine changes with operating-system notifications.
///
/// Business mutations live in use cases. This controller only coordinates
/// cross-feature side effects such as cancelling/rescheduling reminders.
class MedicineManagementController
    extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateMedicine(
    MedicineEntity medicine,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(updateMedicineUseCaseProvider)
          .call(medicine);

      await _cancelNotifications(
        result.cancelledOccurrences,
      );

      await _scheduleNotifications(
        result.createdOccurrences,
      );

      _refreshAppState();
    });
  }

  Future<void> deleteMedicine(
    String medicineId,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final cancelled = await ref
          .read(deleteMedicineUseCaseProvider)
          .call(medicineId);

      await _cancelNotifications(cancelled);

      _refreshAppState();
    });
  }

  Future<void> pauseMedicine(
    String medicineId,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final cancelled = await ref
          .read(pauseMedicineUseCaseProvider)
          .call(medicineId);

      await _cancelNotifications(cancelled);

      _refreshAppState();
    });
  }

  Future<void> resumeMedicine(
    String medicineId,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(resumeMedicineUseCaseProvider)
          .call(medicineId);

      await _scheduleNotifications(
        result.createdOccurrences,
      );

      _refreshAppState();
    });
  }

  Future<void> stopMedicine(
    String medicineId,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final cancelled = await ref
          .read(stopMedicineUseCaseProvider)
          .call(medicineId);

      await _cancelNotifications(cancelled);

      _refreshAppState();
    });
  }

  Future<void> _cancelNotifications(
    List<DoseOccurrenceEntity> occurrences,
  ) async {
    final notificationRepository = ref.read(
      reminderNotificationRepositoryProvider,
    );

    // Notification failure should not roll back valid Hive data.
    // Startup synchronization will repair any OS/Hive mismatch later.
    for (final occurrence in occurrences) {
      try {
        await notificationRepository.cancelReminder(
          occurrence.id,
        );
      } catch (_) {
        // Best-effort cancellation.
      }
    }
  }

  Future<void> _scheduleNotifications(
    List<DoseOccurrenceEntity> occurrences,
  ) async {
    if (occurrences.isEmpty) {
      return;
    }

    final settings = await ref.read(
      settingsControllerProvider.future,
    );

    if (!settings.notificationsEnabled) {
      return;
    }

    try {
      await ref
          .read(reminderNotificationRepositoryProvider)
          .scheduleReminders(
        occurrences,
        vibrationEnabled:
            settings.vibrationEnabled,
        soundId: settings.reminderSoundId,
      );
    } catch (_) {
      // Data remains valid even if the OS temporarily rejects scheduling.
    }
  }

  void _refreshAppState() {
    // Refresh medicine management/list screens.
    ref.invalidate(medicineNotifierProvider);

    // Refresh Dashboard, Reminder and History occurrence providers.
    ref
        .read(
          doseOccurrenceRevisionProvider.notifier,
        )
        .changed();
  }
}

final medicineManagementControllerProvider =
    AsyncNotifierProvider<
        MedicineManagementController,
        void>(
  MedicineManagementController.new,
);
