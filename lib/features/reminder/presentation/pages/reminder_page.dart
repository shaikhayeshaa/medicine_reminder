import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder/features/reminder/presentation/provider/dose_action_controller.dart';
import 'package:medicine_reminder/features/reminder/presentation/provider/reminder_occurrence_provider.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';
import '../../../medicine/domain/entities/snooze_option.dart';


class ReminderPage extends ConsumerWidget {
  final String occurrenceId;

  const ReminderPage({
    super.key,
    required this.occurrenceId,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    ref.listen<AsyncValue<void>>(
      doseActionControllerProvider,
      (previous, next) {
        if (previous?.isLoading == true &&
            next.hasError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Unable to update dose: ${next.error}',
              ),
            ),
          );
        }
      },
    );

    final occurrenceAsync = ref.watch(
      reminderOccurrenceProvider(
        occurrenceId,
      ),
    );

    return occurrenceAsync.when(
      loading: () {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Medicine Reminder',
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },

      error: (error, stackTrace) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Medicine Reminder',
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load reminder.',
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: () {
                      ref.invalidate(
                        reminderOccurrenceProvider(
                          occurrenceId,
                        ),
                      );
                    },
                    child: const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      data: (occurrence) {
        if (occurrence == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Medicine Reminder',
              ),
            ),
            body: const Center(
              child: Text(
                'Reminder not found.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Medicine Reminder',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                120,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: _ReminderContent(
                    occurrence: occurrence,
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar:
              _DoseActionBar(
            occurrence: occurrence,
          ),
        );
      },
    );
  }
}

class _ReminderContent extends StatelessWidget {
  final DoseOccurrenceEntity occurrence;

  const _ReminderContent({
    required this.occurrence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  child: Icon(
                    Icons.medication_outlined,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  occurrence.medicineName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 6),

                Text(
                  occurrence.medicineStrength,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 16),

                _StatusChip(
                  status: occurrence.status,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Scheduled time',
                  value: DateFormat(
                    'hh:mm a',
                  ).format(
                    occurrence.scheduledAt,
                  ),
                ),

                const Divider(),

                _DetailRow(
                  icon: Icons.medication_outlined,
                  label: 'Dose',
                  value:
                      '${occurrence.quantity} '
                      '${occurrence.unit}',
                ),

                const Divider(),

                _DetailRow(
                  icon:
                      Icons.restaurant_outlined,
                  label: 'Food instruction',
                  value:
                      occurrence.foodInstruction,
                ),

                const Divider(),

                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value:
                      occurrence.medicineType,
                ),

                if (occurrence
                    .medicineDescription
                    .isNotEmpty) ...[
                  const Divider(),

                  _DetailRow(
                    icon:
                        Icons.description_outlined,
                    label: 'Description',
                    value: occurrence
                        .medicineDescription,
                  ),
                ],

                if (occurrence.snoozedUntil !=
                    null) ...[
                  const Divider(),

                  _DetailRow(
                    icon:
                        Icons.snooze_outlined,
                    label: 'Snoozed until',
                    value: DateFormat(
                      'hh:mm a',
                    ).format(
                      occurrence
                          .snoozedUntil!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium,
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DoseStatus status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      DoseStatus.pending => (
          'Pending',
          Icons.schedule_outlined,
        ),
      DoseStatus.taken => (
          'Taken',
          Icons.check_circle_outline,
        ),
      DoseStatus.missed => (
          'Missed',
          Icons.cancel_outlined,
        ),
      DoseStatus.skipped => (
          'Skipped',
          Icons.skip_next_outlined,
        ),
    };

    return Chip(
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(label),
    );
  }
}

class _DoseActionBar extends ConsumerWidget {
  final DoseOccurrenceEntity occurrence;

  const _DoseActionBar({
    required this.occurrence,
  });

  Future<void> _markTaken(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref
        .read(
          doseActionControllerProvider.notifier,
        )
        .markTaken(occurrence);

    _closeOnSuccess(
      context,
      ref,
    );
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref
        .read(
          doseActionControllerProvider.notifier,
        )
        .skip(occurrence);

    _closeOnSuccess(
      context,
      ref,
    );
  }

  Future<void> _snooze(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final option =
        await showModalBottomSheet<
            SnoozeOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const _SnoozeSheet();
      },
    );

    if (option == null ||
        !context.mounted) {
      return;
    }

    await ref
        .read(
          doseActionControllerProvider.notifier,
        )
        .snooze(
          occurrence: occurrence,
          option: option,
        );

    if (!context.mounted) {
      return;
    }

    _closeOnSuccess(
      context,
      ref,
    );
  }

  void _closeOnSuccess(
    BuildContext context,
    WidgetRef ref,
  ) {
    if (!context.mounted) {
      return;
    }

    final actionState = ref.read(
      doseActionControllerProvider,
    );

    if (!actionState.hasError) {
      context.pop();
    }
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final isLoading = ref.watch(
      doseActionControllerProvider.select(
        (state) => state.isLoading,
      ),
    );

    if (occurrence.status !=
        DoseStatus.pending) {
      return SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Text(
          'This dose is already '
          '${occurrence.status.name}.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _markTaken(
                        context,
                        ref,
                      ),
              icon: const Icon(
                Icons.check,
              ),
              label: const Text(
                'Taken',
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _snooze(
                        context,
                        ref,
                      ),
              icon: const Icon(
                Icons.snooze,
              ),
              label: const Text(
                'Snooze',
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _skip(
                        context,
                        ref,
                      ),
              icon: const Icon(
                Icons.skip_next,
              ),
              label: const Text(
                'Skip',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnoozeSheet extends StatelessWidget {
  const _SnoozeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Snooze reminder',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 12),

            for (final option
                in SnoozeOption.values)
              ListTile(
                leading: const Icon(
                  Icons.snooze,
                ),
                title: Text(
                  '${option.minutes} minutes',
                ),
                onTap: () {
                  Navigator.of(context).pop(
                    option,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}