import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_date_provider.dart';

class DashboardDateHeader
    extends ConsumerWidget {
  const DashboardDateHeader({
    super.key,
  });

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
        .read(
          dashboardDateProvider.notifier,
        )
        .selectDate(selectedDate);
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final selectedDate = ref.watch(
      dashboardDateProvider,
    );

    final isToday = _isToday(
      selectedDate,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday
                        ? 'Today'
                        : 'Selected date',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                    ).format(selectedDate),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ],
              ),
            ),

            if (!isToday)
              TextButton(
                onPressed: () {
                  ref
                      .read(
                        dashboardDateProvider
                            .notifier,
                      )
                      .selectToday();
                },
                child: const Text(
                  'Today',
                ),
              ),

            IconButton(
              tooltip: 'Select date',
              onPressed: () => _selectDate(
                context,
                ref,
                selectedDate,
              ),
              icon: const Icon(
                Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}