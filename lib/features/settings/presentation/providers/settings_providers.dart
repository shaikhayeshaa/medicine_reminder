import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/settings_sound_preview_service.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/save_and_apply_settings.dart';
import '../../domain/usecases/save_settings.dart';
import '../models/reminder_sound_option.dart';

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSourceImpl(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) {
    return SettingsRepositoryImpl(
      localDataSource: ref.watch(settingsLocalDataSourceProvider),
    );
  },
);

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>(
  (ref) {
    return GetSettingsUseCase(
      repository: ref.watch(settingsRepositoryProvider),
    );
  },
);

final saveSettingsUseCaseProvider = Provider<SaveSettingsUseCase>(
  (ref) {
    return SaveSettingsUseCase(
      repository: ref.watch(settingsRepositoryProvider),
    );
  },
);

/// Coordinates persisted Settings with the medicine notification queue.
final saveAndApplySettingsUseCaseProvider =
    Provider<SaveAndApplySettingsUseCase>((ref) {
  return SaveAndApplySettingsUseCase(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    medicineRepository: ref.watch(medicineRepositoryProvider),
    reminderNotificationRepository:
        ref.watch(reminderNotificationRepositoryProvider),
  );
});

final settingsSoundPreviewServiceProvider =
    Provider<SettingsSoundPreviewService>((ref) {
  final service = SettingsSoundPreviewService();

  // Release native audio resources when the provider is disposed.
  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});

class SettingsController extends AsyncNotifier<SettingsEntity> {
  @override
  Future<SettingsEntity> build() async {
    final getSettings = ref.read(getSettingsUseCaseProvider);
    return getSettings();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final current = state.value;

    if (current == null || current.notificationsEnabled == enabled) {
      return;
    }

    // Turning notifications on/off must immediately synchronize the
    // scheduled reminder queue.
    await _persist(
      current.copyWith(notificationsEnabled: enabled),
      rescheduleNotifications: true,
    );
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final current = state.value;

    if (current == null || current.vibrationEnabled == enabled) {
      return;
    }

    // Existing future reminders are rebuilt so the new vibration
    // preference applies to them.
    await _persist(
      current.copyWith(vibrationEnabled: enabled),
      rescheduleNotifications: true,
    );
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    const allowedValues = {5, 10, 15, 30};

    if (!allowedValues.contains(minutes)) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Default snooze must be 5, 10, 15, or 30 minutes.',
      );
    }

    final current = state.value;

    if (current == null || current.defaultSnoozeMinutes == minutes) {
      return;
    }

    // Default snooze only affects future snooze actions. Existing reminder
    // times do not need to be rebuilt.
    await _persist(
      current.copyWith(defaultSnoozeMinutes: minutes),
      rescheduleNotifications: false,
    );
  }

  Future<void> setReminderSound(String soundId) async {
    // Only sounds shipped by this app are allowed to be persisted.
    final isKnownSound = reminderSoundOptions.any(
      (option) => option.id == soundId,
    );

    if (!isKnownSound) {
      throw ArgumentError.value(
        soundId,
        'soundId',
        'Unknown reminder sound.',
      );
    }

    final current = state.value;

    if (current == null || current.reminderSoundId == soundId) {
      return;
    }

    // Rebuild future reminders so the selected sound is actually used.
    await _persist(
      current.copyWith(reminderSoundId: soundId),
      rescheduleNotifications: true,
    );
  }

  Future<void> _persist(
    SettingsEntity updated, {
    required bool rescheduleNotifications,
  }) async {
    final previous = state.value;

    // Optimistic state keeps switches/chips responsive.
    state = AsyncData(updated);

    try {
      final saveAndApply = ref.read(
        saveAndApplySettingsUseCaseProvider,
      );

      await saveAndApply(
        updated,
        rescheduleNotifications: rescheduleNotifications,
      );
    } catch (error, stackTrace) {
      // This rollback is primarily for Hive persistence failures.
      if (previous != null) {
        state = AsyncData(previous);
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsEntity>(
  SettingsController.new,
);
