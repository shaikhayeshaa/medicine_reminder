import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/glass_surface.dart';
import '../providers/dashboard_date_provider.dart';

class DashboardDateHeader extends ConsumerWidget {
  const DashboardDateHeader({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    ref
        .read(dashboardDateProvider.notifier)
        .selectDate(selectedDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(dashboardDateProvider);
    final isToday = _isToday(selectedDate);
    final scheme = Theme.of(context).colorScheme;

    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : 'Selected day',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEE, d MMM yyyy')
                      .format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (!isToday)
            TextButton(
              onPressed: () {
                ref
                    .read(dashboardDateProvider.notifier)
                    .selectToday();
              },
              child: const Text('Today'),
            ),
          IconButton.filledTonal(
            tooltip: 'Choose date',
            onPressed: () => _selectDate(
              context,
              ref,
              selectedDate,
            ),
            icon: const Icon(Icons.edit_calendar_rounded),
          ),
        ],
      ),
    );
  }
}
