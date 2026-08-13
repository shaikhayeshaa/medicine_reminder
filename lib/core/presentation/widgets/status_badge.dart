import 'package:flutter/material.dart';

import '../../../features/medicine/domain/entities/dose_status.dart';

class StatusBadge extends StatelessWidget {
  final DoseStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(presentation.icon, size: 15, color: presentation.color),
          const SizedBox(width: 5),
          Text(
            presentation.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: presentation.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  _StatusPresentation _presentation(DoseStatus status) {
    return switch (status) {
      DoseStatus.pending => const _StatusPresentation(
        label: 'Pending',
        icon: Icons.schedule_rounded,
        color: Color(0xFFF59E0B),
      ),
      DoseStatus.taken => const _StatusPresentation(
        label: 'Taken',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF16A36A),
      ),
      DoseStatus.missed => const _StatusPresentation(
        label: 'Missed',
        icon: Icons.error_rounded,
        color: Color(0xFFEF5A5A),
      ),
      DoseStatus.skipped => const _StatusPresentation(
        label: 'Skipped',
        icon: Icons.skip_next_rounded,
        color: Color(0xFF7C6BEF),
      ),
    };
  }
}

class _StatusPresentation {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });
}
