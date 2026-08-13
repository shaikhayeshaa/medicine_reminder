import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';

class MedicineOccurrenceCard extends StatelessWidget {
  final DoseOccurrenceEntity occurrence;
  final VoidCallback? onTap;

  const MedicineOccurrenceCard({
    super.key,
    required this.occurrence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = occurrence.quantity == occurrence.quantity.roundToDouble()
        ? occurrence.quantity.toInt().toString()
        : occurrence.quantity.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('hh:mm').format(occurrence.scheduledAt),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                      Text(
                        DateFormat('a').format(occurrence.scheduledAt),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              occurrence.medicineName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: occurrence.status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${occurrence.medicineStrength} • '
                        '$quantity ${occurrence.unit}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (occurrence.foodInstruction.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 16,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                occurrence.foodInstruction,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (occurrence.snoozedUntil != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Snoozed until ${DateFormat('hh:mm a').format(occurrence.snoozedUntil!)}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
