import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medicine_reminder/app/router.dart';

import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
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
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return occurrences;
    }

    return occurrences.where((occurrence) {
      final name = occurrence.medicineName.toLowerCase();

      final description = occurrence.medicineDescription.toLowerCase();

      final type = occurrence.medicineType.toLowerCase();

      return name.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          type.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Medicines',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _searchController,
          onChanged: (value) {
            _query.value = value;
          },
          decoration: InputDecoration(
            hintText: 'Search medicines',
            prefixIcon: const Icon(Icons.search),
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
                  icon: const Icon(Icons.close),
                );
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

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
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text('Unable to load medicines.')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),

            const SizedBox(height: 12),

            Text(
              'No medicines scheduled',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 4),

            Text(
              'Add a medicine to create reminders.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text('No matching medicines found.')),
    );
  }
}
