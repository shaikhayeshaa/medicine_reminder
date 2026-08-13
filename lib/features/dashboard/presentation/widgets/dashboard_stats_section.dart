import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../providers/dashboard_stats_provider.dart';

class DashboardStatsSection
    extends ConsumerWidget {
  const DashboardStatsSection({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final statsAsync = ref.watch(
      dashboardStatsProvider,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(height: 12),

        statsAsync.when(
          loading: () =>
              const LinearProgressIndicator(),

          error: (error, stackTrace) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unable to load daily statistics.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },

          data: (stats) {
            return _StatsList(
              stats: stats,
            );
          },
        ),
      ],
    );
  }
}

class _StatsList extends StatelessWidget {
  final DashboardStats stats;

  const _StatsList({
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            label: 'Total',
            count: stats.total,
            icon: Icons.medication_outlined,
          ),

          _StatCard(
            label: 'Pending',
            count: stats.pending,
            icon: Icons.schedule_outlined,
          ),

          _StatCard(
            label: 'Taken',
            count: stats.taken,
            icon:
                Icons.check_circle_outline,
          ),

          _StatCard(
            label: 'Missed',
            count: stats.missed,
            icon: Icons.cancel_outlined,
          ),

          _StatCard(
            label: 'Skipped',
            count: stats.skipped,
            icon:
                Icons.skip_next_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      margin: const EdgeInsets.only(
        right: 10,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(icon),

              const Spacer(),

              Text(
                count.toString(),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}