import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/utils/occurrence_search.dart';
import '../providers/dashboard_date_provider.dart';
import '../providers/dashboard_occurrences_provider.dart';
import 'medicine_occurrence_card.dart';

class DashboardOccurrenceList extends ConsumerStatefulWidget {
  const DashboardOccurrenceList({super.key});

  @override
  ConsumerState<DashboardOccurrenceList> createState() =>
      _DashboardOccurrenceListState();
}

class _DashboardOccurrenceListState
    extends ConsumerState<DashboardOccurrenceList> {
  final _searchController = TextEditingController();
  final _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _query.dispose();
    super.dispose();
  }

  List<DoseOccurrenceEntity> _filter(
    List<DoseOccurrenceEntity> occurrences,
    String query,
  ) {
    return occurrences
        .where((occurrence) => occurrenceMatchesSearch(occurrence, query))
        .toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(dashboardDateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isToday(selectedDate) ? "Today's medicines" : 'Scheduled medicines',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GlassSurface(
          borderRadius: BorderRadius.circular(20),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _query.value = value,
            decoration: InputDecoration(
              hintText: 'Search name, type or description',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: ValueListenableBuilder<String>(
                valueListenable: _query,
                builder: (context, query, child) {
                  if (query.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      _query.value = '';
                    },
                    icon: const Icon(Icons.close_rounded),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Consumer(
          builder: (context, ref, child) {
            final occurrencesAsync = ref.watch(dashboardOccurrencesProvider);

            return occurrencesAsync.when(
              loading: () => const _LoadingState(),
              error: (error, stackTrace) => const _ErrorState(),
              data: (occurrences) {
                return ValueListenableBuilder<String>(
                  valueListenable: _query,
                  builder: (context, query, child) {
                    final filtered = _filter(occurrences, query);

                    if (occurrences.isEmpty) {
                      return const _EmptyState();
                    }

                    if (filtered.isEmpty) {
                      return const _NoSearchResults();
                    }

                    return Column(
                      children: [
                        for (final occurrence in filtered)
                          MedicineOccurrenceCard(
                            key: ValueKey(occurrence.id),
                            occurrence: occurrence,
                            onTap: () {
                              context.push(
                                AppRoutes.reminderPath(occurrence.id),
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded),
          SizedBox(width: 10),
          Expanded(child: Text('Unable to load medicines. Pull to retry.')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_liquid_rounded,
            size: 50,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'No doses scheduled',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Add a medicine or choose another date.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: Text('No matching medicines found.')),
    );
  }
}
