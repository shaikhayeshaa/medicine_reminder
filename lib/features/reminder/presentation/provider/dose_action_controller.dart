import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicine_reminder/features/settings/presentation/providers/settings_providers.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/snooze_option.dart';
import '../../../medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';

class DoseActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markTaken(DoseOccurrenceEntity occurrence) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(markDoseTakenUseCaseProvider);

      final notificationRepository = ref.read(
        reminderNotificationRepositoryProvider,
      );
      // 1. Hive status update
      await useCase(occurrence);

      // 2. Same occurrence ki notification cancel
      await notificationRepository.cancelReminder(occurrence.id);

      // 3. Dashboard/Reminder ko refresh signal
      _notifyOccurrenceChanged();
    });
  }

  Future<void> skip(DoseOccurrenceEntity occurrence) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(skipDoseUseCaseProvider);

      final notificationRepository = ref.read(
        reminderNotificationRepositoryProvider,
      );
      // 1. Hive status update
      await useCase(occurrence);

      // 2. Notification cancel
      await notificationRepository.cancelReminder(occurrence.id);

      // 3. Refresh
      _notifyOccurrenceChanged();
    });
  }

  Future<void> snooze({
    required DoseOccurrenceEntity occurrence,
    required SnoozeOption option,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(snoozeDoseUseCaseProvider);

      final notificationRepository = ref.read(
        reminderNotificationRepositoryProvider,
      );

      // Update this one occurrence in Hive.
      final updatedOccurrence = await useCase(
        occurrence: occurrence,
        option: option,
      );

      // Remove its previous notification.
      await notificationRepository.cancelReminder(occurrence.id);

      final settings = await ref.read(settingsControllerProvider.future);

      // If notifications are globally disabled,
      // only persist snoozedUntil; don't create a new OS reminder.
      if (settings.notificationsEnabled) {
        await notificationRepository.scheduleReminder(
          updatedOccurrence,
          vibrationEnabled: settings.vibrationEnabled,
          soundId: settings.reminderSoundId,
        );
      }

      _notifyOccurrenceChanged();
    });
  }

  void _notifyOccurrenceChanged() {
    ref.read(doseOccurrenceRevisionProvider.notifier).changed();
  }
}

final doseActionControllerProvider =
    AsyncNotifierProvider<DoseActionController, void>(DoseActionController.new);
