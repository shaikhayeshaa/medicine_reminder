import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/glass_icon_button.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../providers/dashboard_occurrences_provider.dart';
import '../widgets/dashboard_date_header.dart';
import '../widgets/dashboard_occurrence_list.dart';
import '../widgets/dashboard_stats_section.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _addMedicine(BuildContext context, WidgetRef ref) async {
    final added = await context.push<bool>(AppRoutes.addMedicine);

    if (added == true) {
      ref.invalidate(dashboardOccurrencesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(dashboardOccurrencesProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
              children: [
                PageHeader(
                  eyebrow: 'Meditrake',
                  title: 'Your daily care',
                  subtitle: 'Stay on schedule with every dose.',
                  trailing: GlassIconButton(
                    icon: Icons.medication_liquid_rounded,
                    tooltip: 'Manage medicines',
                    onPressed: () {
                      context.push(AppRoutes.manageMedicines);
                    },
                  ),
                ),
                const SizedBox(height: 22),
                const DashboardDateHeader(),
                const SizedBox(height: 22),
                const DashboardStatsSection(),
                const SizedBox(height: 26),
                const DashboardOccurrenceList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 92),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _addMedicine(context, ref),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          tint: Theme.of(context).colorScheme.primary,
          lightOpacity: 0.90,
          darkOpacity: 0.72,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Medicine',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
