import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../domain/entities/medicine_entity.dart';
import '../providers/medicine_management_providers.dart';
import '../providers/medicine_notifier.dart';

class MedicineManagementPage extends ConsumerWidget {
  const MedicineManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineNotifierProvider);

    final isWorking = ref.watch(
      medicineManagementControllerProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Medicines')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Current medicines provider ko invalidate karke
          // fresh data dobara repository/Hive se load karte hain.
          ref.invalidate(medicineNotifierProvider);

          await ref.read(medicineNotifierProvider.future);
        },
        child: medicinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 180),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load medicines.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          data: (medicines) {
            if (medicines.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 180), _EmptyMedicines()],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final medicine = medicines[index];

                return _MedicineManagementCard(
                  medicine: medicine,
                  disabled: isWorking,
                  onEdit: () async {
                    final changed = await context.push<bool>(
                      AppRoutes.editMedicinePath(medicine.id),
                    );

                    if (changed == true) {
                      // Current medicines provider ko invalidate karke
                      // fresh data dobara repository/Hive se load karte hain.
                      ref.invalidate(medicineNotifierProvider);

                      await ref.read(medicineNotifierProvider.future);
                    }
                  },
                  onPause: () => _runAction(
                    context: context,
                    ref: ref,
                    action: () => ref
                        .read(medicineManagementControllerProvider.notifier)
                        .pauseMedicine(medicine.id),
                    successMessage: 'Medicine paused.',
                  ),
                  onResume: () => _runAction(
                    context: context,
                    ref: ref,
                    action: () => ref
                        .read(medicineManagementControllerProvider.notifier)
                        .resumeMedicine(medicine.id),
                    successMessage: 'Medicine resumed.',
                  ),
                  onStop: () async {
                    final confirmed = await _confirm(
                      context,
                      title: 'Stop medicine?',
                      message:
                          'Future doses and reminders will be removed. Previous history will stay unchanged.',
                      confirmLabel: 'Stop',
                    );

                    if (!confirmed || !context.mounted) {
                      return;
                    }

                    await _runAction(
                      context: context,
                      ref: ref,
                      action: () => ref
                          .read(medicineManagementControllerProvider.notifier)
                          .stopMedicine(medicine.id),
                      successMessage: 'Medicine stopped.',
                    );
                  },
                  onDelete: () async {
                    final confirmed = await _confirm(
                      context,
                      title: 'Delete medicine?',
                      message:
                          'The medicine will be removed. Historical Taken/Missed/Skipped records will remain available in History.',
                      confirmLabel: 'Delete',
                    );

                    if (!confirmed || !context.mounted) {
                      return;
                    }

                    await _runAction(
                      context: context,
                      ref: ref,
                      action: () => ref
                          .read(medicineManagementControllerProvider.notifier)
                          .deleteMedicine(medicine.id),
                      successMessage: 'Medicine deleted.',
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Future<void> _runAction({
    required BuildContext context,
    required WidgetRef ref,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    await action();

    if (!context.mounted) {
      return;
    }

    final state = ref.read(medicineManagementControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: ${state.error}')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _MedicineManagementCard extends StatelessWidget {
  final MedicineEntity medicine;
  final bool disabled;

  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  const _MedicineManagementCard({
    required this.medicine,
    required this.disabled,
    required this.onEdit,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusForMedicine(medicine);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(child: Icon(Icons.medication_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text('${medicine.strength} • ${medicine.type}'),
                    ],
                  ),
                ),
                Chip(
                  label: Text(status.label),
                  avatar: Icon(status.icon, size: 17),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              medicine.endDate == null
                  ? 'From ${DateFormat('dd MMM yyyy').format(medicine.startDate)} • No end date'
                  : '${DateFormat('dd MMM yyyy').format(medicine.startDate)} → ${DateFormat('dd MMM yyyy').format(medicine.endDate!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: disabled ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                PopupMenuButton<_MedicineAction>(
                  enabled: !disabled,
                  tooltip: 'Medicine actions',
                  onSelected: (action) {
                    switch (action) {
                      case _MedicineAction.pause:
                        onPause();
                      case _MedicineAction.resume:
                        onResume();
                      case _MedicineAction.stop:
                        onStop();
                      case _MedicineAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (medicine.isActive)
                        const PopupMenuItem(
                          value: _MedicineAction.pause,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.pause),
                            title: Text('Pause'),
                          ),
                        )
                      else if (_canResume(medicine))
                        const PopupMenuItem(
                          value: _MedicineAction.resume,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.play_arrow),
                            title: Text('Resume'),
                          ),
                        ),

                      if (medicine.isActive)
                        const PopupMenuItem(
                          value: _MedicineAction.stop,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.stop),
                            title: Text('Stop'),
                          ),
                        ),

                      const PopupMenuItem(
                        value: _MedicineAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static _MedicineVisualStatus _statusForMedicine(MedicineEntity medicine) {
    if (medicine.isActive) {
      return const _MedicineVisualStatus(
        label: 'Active',
        icon: Icons.check_circle_outline,
      );
    }

    if (!_canResume(medicine)) {
      return const _MedicineVisualStatus(
        label: 'Stopped',
        icon: Icons.stop_circle_outlined,
      );
    }

    return const _MedicineVisualStatus(
      label: 'Paused',
      icon: Icons.pause_circle_outline,
    );
  }

  static bool _canResume(MedicineEntity medicine) {
    if (medicine.endDate == null) {
      return true;
    }

    final now = DateTime.now();

    final endOfDay = DateTime(
      medicine.endDate!.year,
      medicine.endDate!.month,
      medicine.endDate!.day,
      23,
      59,
      59,
    );

    return endOfDay.isAfter(now);
  }
}

class _MedicineVisualStatus {
  final String label;
  final IconData icon;

  const _MedicineVisualStatus({required this.label, required this.icon});
}

enum _MedicineAction { pause, resume, stop, delete }

class _EmptyMedicines extends StatelessWidget {
  const _EmptyMedicines();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No medicines yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a medicine from the Today tab.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
