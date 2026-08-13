import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medicine_reminder/features/dashboard/presentation/providers/dashboard_occurrences_provider.dart';
import 'package:medicine_reminder/features/dashboard/presentation/widgets/dashboard_date_header.dart';
import 'package:medicine_reminder/features/dashboard/presentation/widgets/dashboard_occurrence_list.dart';
import 'package:medicine_reminder/features/dashboard/presentation/widgets/dashboard_stats_section.dart';
import '../../../../app/router.dart';

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
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        actions: [
          IconButton(
            tooltip: 'Manage medicines',
            onPressed: () {
              context.push(AppRoutes.manageMedicines);
            },
            icon: const Icon(Icons.medication_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(dashboardOccurrencesProvider.future);
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            DashboardDateHeader(),

            SizedBox(height: 20),

            DashboardStatsSection(),

            SizedBox(height: 24),

            DashboardOccurrenceList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMedicine(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }
}
