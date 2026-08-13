import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicine_reminder/features/settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/medicine_entity.dart';
import 'medicine_providers.dart';

class AddMedicineController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(MedicineEntity medicine) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final addMedicineUseCase = ref.read(addMedicineUseCaseProvider);

      final occurrences = await addMedicineUseCase(medicine);

      final notificationRepository = ref.read(
        reminderNotificationRepositoryProvider,
      );

      // Read persisted notification preferences.
      final settings = await ref.read(settingsControllerProvider.future);

      if (settings.notificationsEnabled) {
        try {
          await notificationRepository.requestPermissions();

          await notificationRepository.scheduleReminders(
            occurrences,

            // Future reminders now respect Settings.
            vibrationEnabled: settings.vibrationEnabled,

            soundId: settings.reminderSoundId,
          );
        } catch (_) {
          // Medicine data has already been saved safely.
          // Notification permission/platform failure must not
          // delete the medicine.
        }
      }
    });
  }
}

final addMedicineControllerProvider =
    AsyncNotifierProvider<AddMedicineController, void>(
      AddMedicineController.new,
    );
