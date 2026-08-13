import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../domain/entities/history_status_filter.dart';
import '../providers/history_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController =
      TextEditingController();
  final ValueNotifier<String> _searchQuery =
      ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchQuery.value =
        _searchController.text.trim().toLowerCase();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyOccurrencesProvider);
              await ref.read(historyOccurrencesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: PageHeader(
                      eyebrow: 'Dose timeline',
                      title: 'History',
                      subtitle:
                          'Review exactly what happened with every dose.',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                    child: GlassSurface(
                      borderRadius: BorderRadius.circular(20),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search medicine, type or description',
                          prefixIcon:
                              const Icon(Icons.search_rounded),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          suffixIcon:
                              ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, child) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return IconButton(
                                tooltip: 'Clear search',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: _HistoryDateFilter(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: _StatusFilters(),
                  ),
                ),
                _HistoryList(searchQuery: _searchQuery),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 130),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryDateFilter extends ConsumerWidget {
  const _HistoryDateFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(historyDateProvider);

    return Row(
      children: [
        Expanded(
          child: GlassSurface(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (date != null) {
                ref
                    .read(historyDateProvider.notifier)
                    .selectDate(date);
              }
            },
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? 'All dates'
                        : DateFormat('dd MMM yyyy')
                            .format(selectedDate),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Clear date filter',
            onPressed: () {
              ref.read(historyDateProvider.notifier).clear();
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}

class _StatusFilters extends ConsumerWidget {
  const _StatusFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(historyStatusFilterProvider);

    // Wrap keeps every status visible without forcing a horizontal swipe.
    // On narrow phones the chips naturally move to the next line.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in const [
          (HistoryStatusFilter.all, 'All'),
          (HistoryStatusFilter.taken, 'Taken'),
          (HistoryStatusFilter.missed, 'Missed'),
          (HistoryStatusFilter.skipped, 'Skipped'),
        ])
          ChoiceChip(
            label: Text(item.$2),
            selected: selected == item.$1,
            onSelected: (_) {
              ref
                  .read(historyStatusFilterProvider.notifier)
                  .select(item.$1);
            },
          ),
      ],
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final ValueNotifier<String> searchQuery;

  const _HistoryList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrencesAsync =
        ref.watch(historyStatusFilteredProvider);

    return occurrencesAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: FilledButton.icon(
            onPressed: () {
              ref.invalidate(historyOccurrencesProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry history'),
          ),
        ),
      ),
      data: (occurrences) {
        return ValueListenableBuilder<String>(
          valueListenable: searchQuery,
          builder: (context, query, child) {
            final filtered = occurrences.where((occurrence) {
              if (query.isEmpty) {
                return true;
              }

              return occurrence.medicineName
                      .toLowerCase()
                      .contains(query) ||
                  occurrence.medicineDescription
                      .toLowerCase()
                      .contains(query) ||
                  occurrence.medicineType
                      .toLowerCase()
                      .contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _HistoryEmptyState(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final occurrence = filtered[index];
                  final previous =
                      index == 0 ? null : filtered[index - 1];
                  final showDateHeader = previous == null ||
                      !_sameDay(
                        previous.scheduledAt,
                        occurrence.scheduledAt,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDateHeader)
                        _DateHeader(date: occurrence.scheduledAt),
                      _HistoryOccurrenceCard(
                        occurrence: occurrence,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 9),
      child: Text(
        DateFormat('EEEE, dd MMM yyyy').format(date),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _HistoryOccurrenceCard extends StatelessWidget {
  final DoseOccurrenceEntity occurrence;

  const _HistoryOccurrenceCard({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = occurrence.quantity ==
            occurrence.quantity.roundToDouble()
        ? occurrence.quantity.toInt().toString()
        : occurrence.quantity.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              DateFormat('hh:mm a').format(occurrence.scheduledAt),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occurrence.medicineName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${occurrence.medicineStrength} • '
                  '$quantity ${occurrence.unit}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (occurrence.foodInstruction.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    occurrence.foodInstruction,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (occurrence.actionAt != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Action at ${DateFormat('hh:mm a').format(occurrence.actionAt!)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: occurrence.status),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Try another date, status, or search term.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
