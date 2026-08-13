import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_stats.dart';
import 'dashboard_occurrences_provider.dart';

final dashboardStatsProvider =
    Provider<AsyncValue<DashboardStats>>(
  (ref) {
    final occurrences = ref.watch(
      dashboardOccurrencesProvider,
    );

    return occurrences.whenData(
      DashboardStats.fromOccurrences,
    );
  },
);