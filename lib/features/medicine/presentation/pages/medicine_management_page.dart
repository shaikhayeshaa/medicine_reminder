import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/page_header.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Manage Medicines',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),

        // Solid fallback prevents a native black window from ever showing.
        backgroundColor: const Color(0xFF1769D8),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        // Status-bar icons remain readable over the branded header.
        systemOverlayStyle: SystemUiOverlayStyle.light,

        // Brand gradient gives the page a stable, modern header instead of
        // relying on a transparent AppBar over a body-only background.
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1769D8), Color(0xFF10BEB1)],
            ),
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(medicineNotifierProvider);
              await ref.read(medicineNotifierProvider.future);
            },
            child: medicinesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    'Unable to load medicines.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              data: (medicines) {
                if (medicines.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [SizedBox(height: 100), _EmptyMedicines()],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
                  itemCount: medicines.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: PageHeader(
                          eyebrow: 'Treatment control',
                          title: 'Your medicines',
                          subtitle:
                              'Edit schedules or pause, resume, stop and delete treatments.',
                        ),
                      );
                    }

                    final medicine = medicines[index - 1];

                    return _MedicineManagementCard(
                      medicine: medicine,
                      disabled: isWorking,
                      onEdit: () async {
                        final changed = await context.push<bool>(
                          AppRoutes.editMedicinePath(medicine.id),
                        );

                        if (changed == true) {
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
                              'Future doses and reminders will be removed. Previous history stays unchanged.',
                          confirmLabel: 'Stop',
                        );

                        if (!confirmed || !context.mounted) {
                          return;
                        }

                        await _runAction(
                          context: context,
                          ref: ref,
                          action: () => ref
                              .read(
                                medicineManagementControllerProvider.notifier,
                              )
                              .stopMedicine(medicine.id),
                          successMessage: 'Medicine stopped.',
                        );
                      },
                      onDelete: () async {
                        final confirmed = await _confirm(
                          context,
                          title: 'Delete medicine?',
                          message:
                              'The medicine definition and future reminders will be removed. Historical dose records stay available.',
                          confirmLabel: 'Delete',
                        );

                        if (!confirmed || !context.mounted) {
                          return;
                        }

                        await _runAction(
                          context: context,
                          ref: ref,
                          action: () => ref
                              .read(
                                medicineManagementControllerProvider.notifier,
                              )
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
          builder: (context) => AlertDialog(
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
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.medication_liquid_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${medicine.strength} • ${medicine.type}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 15, color: status.color),
                    const SizedBox(width: 5),
                    Text(
                      status.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  medicine.endDate == null
                      ? 'From ${DateFormat('dd MMM yyyy').format(medicine.startDate)} • Ongoing'
                      : '${DateFormat('dd MMM yyyy').format(medicine.startDate)} → ${DateFormat('dd MMM yyyy').format(medicine.endDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '${medicine.doses.length} dose${medicine.doses.length == 1 ? '' : 's'}/day',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<_MedicineAction>(
                enabled: !disabled,
                tooltip: 'Medicine actions',
                icon: const Icon(Icons.more_horiz_rounded),
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
                itemBuilder: (context) => [
                  if (medicine.isActive)
                    const PopupMenuItem(
                      value: _MedicineAction.pause,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.pause_rounded),
                        title: Text('Pause'),
                      ),
                    )
                  else if (_canResume(medicine))
                    const PopupMenuItem(
                      value: _MedicineAction.resume,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.play_arrow_rounded),
                        title: Text('Resume'),
                      ),
                    ),
                  if (medicine.isActive)
                    const PopupMenuItem(
                      value: _MedicineAction.stop,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.stop_circle_outlined),
                        title: Text('Stop'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: _MedicineAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static _MedicineVisualStatus _statusForMedicine(MedicineEntity medicine) {
    if (medicine.isActive) {
      return const _MedicineVisualStatus(
        label: 'Active',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF16A36A),
      );
    }

    if (!_canResume(medicine)) {
      return const _MedicineVisualStatus(
        label: 'Stopped',
        icon: Icons.stop_circle_rounded,
        color: Color(0xFFEF5A5A),
      );
    }

    return const _MedicineVisualStatus(
      label: 'Paused',
      icon: Icons.pause_circle_rounded,
      color: Color(0xFFF59E0B),
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
  final Color color;

  const _MedicineVisualStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}

enum _MedicineAction { pause, resume, stop, delete }

class _EmptyMedicines extends StatelessWidget {
  const _EmptyMedicines();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.medication_liquid_rounded,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first medicine from the Today tab.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
