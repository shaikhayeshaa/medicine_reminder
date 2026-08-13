import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../medicine/presentation/providers/dose_occurrence_revision_provider.dart';
import '../../../medicine/presentation/providers/medicine_notifier.dart';
import '../../../medicine/presentation/providers/medicine_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/recovery_report.dart';
import '../../domain/usecases/run_app_recovery.dart';

final runAppRecoveryUseCaseProvider = Provider<RunAppRecoveryUseCase>((ref) {
  return RunAppRecoveryUseCase(
    medicineRepository: ref.watch(medicineRepositoryProvider),
    reminderNotificationRepository: ref.watch(
      reminderNotificationRepositoryProvider,
    ),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    generateDoseOccurrences: ref.watch(generateDoseOccurrencesUseCaseProvider),
  );
});

/// Executes recovery from app startup/resume without placing business logic
/// inside widgets.
class AppRecoveryController extends AsyncNotifier<RecoveryReport?> {
  DateTime? _lastRunAt;

  @override
  FutureOr<RecoveryReport?> build() => null;

  Future<void> recover({bool force = false}) async {
    if (state.isLoading) {
      return;
    }

    final currentTime = DateTime.now();

    // App lifecycle can emit resume more than once in a short period.
    if (!force &&
        _lastRunAt != null &&
        currentTime.difference(_lastRunAt!) < const Duration(seconds: 10)) {
      return;
    }

    _lastRunAt = currentTime;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final report = await ref.read(runAppRecoveryUseCaseProvider)();

      // Refresh every occurrence-dependent screen after recovery changes.
      ref.read(doseOccurrenceRevisionProvider.notifier).changed();
      ref.invalidate(medicineNotifierProvider);

      return report;
    });
  }
}

final appRecoveryControllerProvider =
    AsyncNotifierProvider<AppRecoveryController, RecoveryReport?>(
      AppRecoveryController.new,
    );
