import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/mock/mock_data.dart';
import 'package:spend_wise/features/transactions/state/filter_providers.dart';

class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({super.key});

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  late String categoryId;
  RangeValues amountRange = const RangeValues(0, 10000);
  FeedDateRange? dateRange;

  @override
  void initState() {
    super.initState();
    final f = ref.read(filterStateNotifierProvider);
    categoryId = f.categoryId;
    dateRange = f.dateRange;
    if (f.minAmountPaise != null || f.maxAmountPaise != null) {
      amountRange = RangeValues(
        (f.minAmountPaise ?? 0) / 100,
        (f.maxAmountPaise ?? 1000000) / 100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = MockData.instance.categories;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  setState(() {
                    categoryId = 'all';
                    amountRange = const RangeValues(0, 10000);
                    dateRange = null;
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: categoryId == 'all',
                onSelected: (_) => setState(() => categoryId = 'all'),
              ),
              ...categories.map((c) => ChoiceChip(
                    label: Text(c.name),
                    selected: categoryId == c.id,
                    onSelected: (_) => setState(() => categoryId = c.id),
                  )),
            ],
          ),
          const SizedBox(height: 20),
          Text('Amount range · ₹${amountRange.start.round()} – ₹${amountRange.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          RangeSlider(
            values: amountRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels('₹${amountRange.start.round()}', '₹${amountRange.end.round()}'),
            onChanged: (v) => setState(() => amountRange = v),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(dateRange == null
                ? 'Select date range'
                : '${_fmt(dateRange!.start)} – ${_fmt(dateRange!.end)}'),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
              );
              if (picked != null) {
                setState(() => dateRange = FeedDateRange(start: picked.start, end: picked.end));
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final notifier = ref.read(filterStateNotifierProvider.notifier);
                notifier.setCategory(categoryId);
                notifier.setAmountRange(
                  (amountRange.start * 100).round(),
                  (amountRange.end * 100).round(),
                );
                notifier.setDateRange(dateRange);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Apply filters'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
