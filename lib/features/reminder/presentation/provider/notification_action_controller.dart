import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/notification_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../medicine/domain/entities/snooze_option.dart';
import '../../../medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class NotificationActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> handleAction(NotificationActionEvent event) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final getOccurrence = ref.read(getDoseOccurrenceByIdUseCaseProvider);

      // Payload contains the individual occurrence id.
      final occurrence = await getOccurrence(event.occurrenceId);

      if (occurrence == null) {
        throw StateError('Dose occurrence not found.');
      }

      final notificationRepository = ref.read(
        reminderNotificationRepositoryProvider,
      );

      switch (event.actionId) {
        case NotificationConstants.takenActionId:
          final markTaken = ref.read(markDoseTakenUseCaseProvider);

          // Persist Taken + actual action time.
          await markTaken(occurrence);

          await notificationRepository.cancelReminder(occurrence.id);

          break;

        case NotificationConstants.skipActionId:
          final skip = ref.read(skipDoseUseCaseProvider);

          // Persist Skipped + actual action time.
          await skip(occurrence);

          await notificationRepository.cancelReminder(occurrence.id);

          break;

        case NotificationConstants.snoozeActionId:
          final settings = await ref.read(settingsControllerProvider.future);

          final snoozeUseCase = ref.read(snoozeDoseUseCaseProvider);

          // Convert persisted 5/10/15/30 setting
          // into our domain SnoozeOption enum.
          final option = SnoozeOption.values.firstWhere(
            (item) => item.minutes == settings.defaultSnoozeMinutes,
            orElse: () => SnoozeOption.tenMinutes,
          );

          final updated = await snoozeUseCase(
            occurrence: occurrence,
            option: option,
          );

          await notificationRepository.cancelReminder(occurrence.id);

          if (settings.notificationsEnabled) {
            await notificationRepository.scheduleReminder(
              updated,
              vibrationEnabled: settings.vibrationEnabled,
              soundId: settings.reminderSoundId,
            );
          }

          break;

        default:
          return;
      }

      // Dashboard / History / Reminder providers refresh.
      ref.read(doseOccurrenceRevisionProvider.notifier).changed();
    });
  }
}

final notificationActionControllerProvider =
    AsyncNotifierProvider<NotificationActionController, void>(
      NotificationActionController.new,
    );
