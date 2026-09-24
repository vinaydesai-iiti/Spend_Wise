import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';
import 'package:spend_wise/features/transactions/state/feed_providers.dart';
import 'package:spend_wise/features/transactions/state/filter_providers.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/features/transactions/presentation/filters_sheet.dart';
import 'package:spend_wise/features/transactions/widgets/transaction_tile.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(monthProvider);
    final filters = ref.watch(filterStateNotifierProvider);
    final groupedAsync = ref.watch(feedGroupedProvider(month));

    if (_searchController.text != filters.query) {
      _searchController.value = _searchController.value.copyWith(text: filters.query);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions · ${DateFmt.monthLabel(month)}'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (filters.isActive)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFE0526A), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const FiltersSheet(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref.read(filterStateNotifierProvider.notifier).setQuery(v),
              decoration: InputDecoration(
                hintText: 'Search merchants',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: groupedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
              data: (grouped) {
                if (grouped.isEmpty) {
                  return _EmptyFeed(hasFilters: filters.isActive);
                }
                final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final dayKey = days[i];
                    final txns = grouped[dayKey]!;
                    return _DaySection(dayKey: dayKey, txns: txns, month: month);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String dayKey;
  final List<Txn> txns;
  final String month;
  const _DaySection({required this.dayKey, required this.txns, required this.month});

  @override
  Widget build(BuildContext context) {
    final parts = dayKey.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF6F7FB),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(
            DateFmt.dayHeader(date),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: txns
                .map((t) => TransactionTile(
                      txn: t,
                      onTap: () => context.push('/transactions/${t.id}', extra: month),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final bool hasFilters;
  const _EmptyFeed({required this.hasFilters});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'No transactions match your filters' : 'No transactions this month',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
