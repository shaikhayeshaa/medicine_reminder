import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../medicine/domain/entities/dose_occurrence_entity.dart';
import '../../../medicine/domain/entities/dose_status.dart';
import '../../domain/entities/history_status_filter.dart';
import '../providers/history_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchQuery.value = _searchController.text.trim().toLowerCase();
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
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyOccurrencesProvider);

          await ref.read(historyOccurrencesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SearchField(controller: _searchController),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _HistoryDateFilter(),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _StatusFilters(),
              ),
            ),

            _HistoryList(searchQuery: _searchQuery),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search medicine...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.close),
            );
          },
        ),
        border: const OutlineInputBorder(),
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
          child: OutlinedButton.icon(
            onPressed: () async {
              final initialDate = selectedDate ?? DateTime.now();

              final date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (date == null) {
                return;
              }

              ref.read(historyDateProvider.notifier).selectDate(date);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              selectedDate == null
                  ? 'All Dates'
                  : DateFormat('dd MMM yyyy').format(selectedDate),
            ),
          ),
        ),

        if (selectedDate != null) ...[
          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Clear date filter',
            onPressed: () {
              ref.read(historyDateProvider.notifier).clear();
            },
            icon: const Icon(Icons.close),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            value: HistoryStatusFilter.all,
            selected: selected,
          ),
          _FilterChip(
            label: 'Taken',
            value: HistoryStatusFilter.taken,
            selected: selected,
          ),
          _FilterChip(
            label: 'Missed',
            value: HistoryStatusFilter.missed,
            selected: selected,
          ),
          _FilterChip(
            label: 'Skipped',
            value: HistoryStatusFilter.skipped,
            selected: selected,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;

  final HistoryStatusFilter value;

  final HistoryStatusFilter selected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) {
          ref.read(historyStatusFilterProvider.notifier).select(value);
        },
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final ValueNotifier<String> searchQuery;

  const _HistoryList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrencesAsync = ref.watch(historyStatusFilteredProvider);

    return occurrencesAsync.when(
      loading: () {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      },

      error: (error, stackTrace) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('Unable to load history.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(historyOccurrencesProvider);
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      data: (occurrences) {
        return ValueListenableBuilder<String>(
          valueListenable: searchQuery,
          builder: (context, query, child) {
            final filtered = occurrences.where((occurrence) {
              if (query.isEmpty) {
                return true;
              }

              return occurrence.medicineName.toLowerCase().contains(query) ||
                  occurrence.medicineDescription.toLowerCase().contains(
                    query,
                  ) ||
                  occurrence.medicineType.toLowerCase().contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _HistoryEmptyState(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final occurrence = filtered[index];

                  final previous = index == 0 ? null : filtered[index - 1];

                  final showDateHeader =
                      previous == null ||
                      !_sameDay(previous.scheduledAt, occurrence.scheduledAt);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDateHeader)
                        _DateHeader(date: occurrence.scheduledAt),

                      _HistoryOccurrenceCard(occurrence: occurrence),
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
      padding: const EdgeInsets.only(top: 14, bottom: 8),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 75,
              child: Text(
                DateFormat('hh:mm a').format(occurrence.scheduledAt),
                style: Theme.of(context).textTheme.titleSmall,
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
                    '${occurrence.medicineStrength}'
                    ' • '
                    '${_quantityText(occurrence.quantity)} '
                    '${occurrence.unit}',
                  ),

                  if (occurrence.foodInstruction.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(occurrence.foodInstruction),
                  ],

                  if (occurrence.actionAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Action: '
                      '${DateFormat('hh:mm a').format(occurrence.actionAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            _HistoryStatusChip(status: occurrence.status),
          ],
        ),
      ),
    );
  }

  String _quantityText(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toString();
  }
}

class _HistoryStatusChip extends StatelessWidget {
  final DoseStatus status;

  const _HistoryStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      DoseStatus.pending => ('Pending', Icons.schedule),
      DoseStatus.taken => ('Taken', Icons.check_circle),
      DoseStatus.missed => ('Missed', Icons.cancel),
      DoseStatus.skipped => ('Skipped', Icons.skip_next),
    };

    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      visualDensity: VisualDensity.compact,
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
              Icons.history,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No history found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing the search, date, or status filter.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
