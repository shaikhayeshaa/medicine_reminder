import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../providers/dashboard_stats_provider.dart';

class DashboardStatsSection extends ConsumerWidget {
  const DashboardStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'A quick view of today\'s individual dose occurrences.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 14),
        statsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => const _StatsError(),
          data: (stats) => _StatsGrid(stats: stats),
        ),
      ],
    );
  }
}

/// A fixed, responsive summary that never requires horizontal scrolling.
///
/// Total gets a full-width summary card, while the four actionable statuses
/// are shown in a compact 2 x 2 grid. This is easier to scan with one hand on
/// small phones and still scales cleanly on wider Android/iOS devices.
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(
        'Pending',
        stats.pending,
        Icons.schedule_rounded,
        const Color(0xFFF59E0B),
      ),
      _StatData(
        'Taken',
        stats.taken,
        Icons.check_circle_rounded,
        const Color(0xFF16A36A),
      ),
      _StatData(
        'Missed',
        stats.missed,
        Icons.error_rounded,
        const Color(0xFFEF5A5A),
      ),
      _StatData(
        'Skipped',
        stats.skipped,
        Icons.skip_next_rounded,
        const Color(0xFF7C6BEF),
      ),
    ];

    return Column(
      children: [
        _TotalDoseCard(total: stats.total),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 10.0;
            final itemWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: itemWidth,
                    child: _StatusStatCard(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TotalDoseCard extends StatelessWidget {
  final int total;

  const _TotalDoseCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Total doses scheduled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStatCard extends StatelessWidget {
  final _StatData item;

  const _StatusStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.value}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 1),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData(
    this.label,
    this.value,
    this.icon,
    this.color,
  );
}

class _StatsError extends StatelessWidget {
  const _StatsError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load daily statistics.',
            ),
          ),
        ],
      ),
    );
  }
}
