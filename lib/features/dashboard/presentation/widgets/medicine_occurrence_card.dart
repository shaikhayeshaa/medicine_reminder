import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';

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
    final statusPresentation = _statusPresentation(context, occurrence.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  DateFormat('hh:mm a').format(occurrence.scheduledAt),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
        
              const SizedBox(width: 12),
        
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.medicineName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
        
                    const SizedBox(height: 4),
        
                    Text(
                      '${occurrence.medicineStrength}'
                      ' • '
                      '${occurrence.quantity} '
                      '${occurrence.unit}',
                    ),
        
                    if (occurrence.foodInstruction.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        occurrence.foodInstruction,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
        
                    if (occurrence.snoozedUntil != null) ...[
                      const SizedBox(height: 6),
        
                      Text(
                        'Snoozed until '
                        '${DateFormat('hh:mm a').format(occurrence.snoozedUntil!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
        
              const SizedBox(width: 8),
        
              Chip(
                avatar: Icon(statusPresentation.icon, size: 16),
                label: Text(statusPresentation.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusPresentation _statusPresentation(
    BuildContext context,
    DoseStatus status,
  ) {
    switch (status) {
      case DoseStatus.pending:
        return const _StatusPresentation(
          label: 'Pending',
          icon: Icons.schedule_outlined,
        );

      case DoseStatus.taken:
        return const _StatusPresentation(
          label: 'Taken',
          icon: Icons.check_circle_outline,
        );

      case DoseStatus.missed:
        return const _StatusPresentation(
          label: 'Missed',
          icon: Icons.cancel_outlined,
        );

      case DoseStatus.skipped:
        return const _StatusPresentation(
          label: 'Skipped',
          icon: Icons.skip_next_outlined,
        );
    }
  }
}

class _StatusPresentation {
  final String label;
  final IconData icon;

  const _StatusPresentation({required this.label, required this.icon});
}
