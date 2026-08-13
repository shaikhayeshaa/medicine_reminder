import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';
import '../../../medicine/domain/entities/snooze_option.dart';
import '../provider/dose_action_controller.dart';
import '../provider/reminder_occurrence_provider.dart';

class ReminderPage extends ConsumerWidget {
  final String occurrenceId;

  const ReminderPage({super.key, required this.occurrenceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(doseActionControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.isLoading == true && next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update dose: ${next.error}')),
        );
      }
    });

    final occurrenceAsync = ref.watch(reminderOccurrenceProvider(occurrenceId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: occurrenceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _MessageState(
            title: 'Unable to load reminder',
            actionLabel: 'Try again',
            onAction: () {
              ref.invalidate(reminderOccurrenceProvider(occurrenceId));
            },
          ),
          data: (occurrence) {
            if (occurrence == null) {
              return _MessageState(
                title: 'Reminder not found',
                actionLabel: 'Go back',
                onAction: context.pop,
              );
            }

            return SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 165),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back',
                        onPressed: context.pop,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                      StatusBadge(status: occurrence.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ReminderHero(occurrence: occurrence),
                  const SizedBox(height: 18),
                  _DetailsCard(occurrence: occurrence),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: occurrenceAsync.maybeWhen(
        data: (occurrence) {
          if (occurrence == null) {
            return null;
          }

          return _DoseActionBar(occurrence: occurrence);
        },
        orElse: () => null,
      ),
    );
  }
}

class _ReminderHero extends StatelessWidget {
  final DoseOccurrenceEntity occurrence;

  const _ReminderHero({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = occurrence.quantity == occurrence.quantity.roundToDouble()
        ? occurrence.quantity.toInt().toString()
        : occurrence.quantity.toString();

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.secondary],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.24),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Icon(
            Icons.medication_liquid_rounded,
            size: 44,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Medicine Reminder',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          occurrence.medicineName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        Text(
          '${occurrence.medicineStrength} • '
          '$quantity ${occurrence.unit}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text(
          DateFormat('hh:mm a').format(occurrence.scheduledAt),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: scheme.primary),
        ),
        if (occurrence.snoozedUntil != null) ...[
          const SizedBox(height: 7),
          Text(
            'Snoozed until '
            '${DateFormat('hh:mm a').format(occurrence.snoozedUntil!)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final DoseOccurrenceEntity occurrence;

  const _DetailsCard({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final quantity = occurrence.quantity == occurrence.quantity.roundToDouble()
        ? occurrence.quantity.toInt().toString()
        : occurrence.quantity.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.medical_information_outlined,
            label: 'Type',
            value: occurrence.medicineType,
          ),
          const Divider(height: 26),
          _DetailRow(
            icon: Icons.medication_outlined,
            label: 'Dose',
            value: '$quantity ${occurrence.unit}',
          ),
          const Divider(height: 26),
          _DetailRow(
            icon: Icons.restaurant_rounded,
            label: 'Food instruction',
            value: occurrence.foodInstruction.isEmpty
                ? 'No special instruction'
                : occurrence.foodInstruction,
          ),
          if (occurrence.medicineDescription.isNotEmpty) ...[
            const Divider(height: 26),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Description',
              value: occurrence.medicineDescription,
            ),
          ],
          if (occurrence.actionAt != null) ...[
            const Divider(height: 26),
            _DetailRow(
              icon: Icons.task_alt_rounded,
              label: 'Action time',
              value: DateFormat(
                'dd MMM • hh:mm a',
              ).format(occurrence.actionAt!),
            ),
          ],
        ],
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoseActionBar extends ConsumerWidget {
  final DoseOccurrenceEntity occurrence;

  const _DoseActionBar({required this.occurrence});

  Future<void> _markTaken(BuildContext context, WidgetRef ref) async {
    await ref.read(doseActionControllerProvider.notifier).markTaken(occurrence);
    _closeOnSuccess(context, ref);
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(doseActionControllerProvider.notifier).skip(occurrence);
    _closeOnSuccess(context, ref);
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final option = await showModalBottomSheet<SnoozeOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _SnoozeSheet(),
    );

    if (option == null || !context.mounted) {
      return;
    }

    await ref
        .read(doseActionControllerProvider.notifier)
        .snooze(occurrence: occurrence, option: option);

    _closeOnSuccess(context, ref);
  }

  void _closeOnSuccess(BuildContext context, WidgetRef ref) {
    if (!context.mounted) {
      return;
    }

    final result = ref.read(doseActionControllerProvider);
    if (!result.hasError) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      doseActionControllerProvider.select((state) => state.isLoading),
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(10),
        child:
            occurrence.status != DoseStatus.pending &&
                occurrence.status != DoseStatus.missed
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'This dose is already ${occurrence.status.name}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _markTaken(context, ref),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Taken'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Snooze',
                    onPressed: isLoading ? null : () => _snooze(context, ref),
                    icon: const Icon(Icons.snooze_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Skip',
                    onPressed: isLoading ? null : () => _skip(context, ref),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Snooze reminder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'Only this dose will move. Your medicine schedule stays unchanged.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in SnoozeOption.values)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.snooze_rounded),
                title: Text('${option.minutes} minutes'),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medication_outlined, size: 54),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
