import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/mock/mock_data.dart';
import 'package:spend_wise/features/overview/domain/month_summary.dart';
import 'package:spend_wise/features/transactions/state/filter_providers.dart';
import 'package:spend_wise/core/state/month_provider.dart';
import 'package:spend_wise/features/overview/state/summary_providers.dart';
import 'package:spend_wise/core/widgets/async_error_view.dart';
import 'package:spend_wise/core/widgets/skeleton.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider);
    final summaryAsync = ref.watch(summaryProvider(month));
    final insightsAsync = ref.watch(insightsProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(summaryProvider(month));
          ref.invalidate(insightsProvider(month));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _MonthSwitcher(month: month),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const SkeletonColumn(heights: [120, 200, 180]),
              error: (e, _) => AsyncErrorView(message: e.toString(), onRetry: () => ref.invalidate(summaryProvider(month))),
              data: (summary) => summary.isEmpty
                  ? const _EmptyMonthCard()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TotalsCard(summary: summary),
                        const SizedBox(height: 16),
                        _DailyLineChart(summary: summary),
                        const SizedBox(height: 16),
                        _CategoryDonut(summary: summary, month: month),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            insightsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cards) => cards.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...cards.map((c) => _InsightCard(text: c)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSwitcher extends ConsumerWidget {
  final String month;
  const _MonthSwitcher({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => ref.read(monthProvider.notifier).previous(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(DateFmt.monthLabel(month), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        IconButton(
          onPressed: () => ref.read(monthProvider.notifier).next(),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final MonthSummary summary;
  const _TotalsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.monthOverMonthPct;
    final up = pct > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total spent', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 6),
            Text(Money.rupees(summary.totalPaise), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (pct.abs() >= 1)
              Row(
                children: [
                  Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 16, color: up ? const Color(0xFFE0526A) : const Color(0xFF2FB380)),
                  const SizedBox(width: 4),
                  Text(
                    '${pct.abs().toStringAsFixed(0)}% vs last month',
                    style: TextStyle(
                      color: up ? const Color(0xFFE0526A) : const Color(0xFF2FB380),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyLineChart extends StatelessWidget {
  final MonthSummary summary;
  const _DailyLineChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final spots = summary.byDay
        .map((d) => FlSpot(d.date.day.toDouble(), d.amountPaise / 100))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily spend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF3F6AF6),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3F6AF6).withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDonut extends ConsumerWidget {
  final MonthSummary summary;
  final String month;
  const _CategoryDonut({required this.summary, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalPaise == 0 ? 1 : summary.totalPaise;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top categories', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      sections: entries.take(6).map((e) {
                        final cat = MockData.instance.categoryById(e.key);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: cat.color,
                          radius: 24,
                          showTitle: false,
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions) return;
                          final idx = response?.touchedSection?.touchedSectionIndex;
                          if (idx == null || idx < 0 || idx >= entries.length) return;
                          // F3: tapping a slice filters the feed by that category.
                          ref.read(filterStateNotifierProvider.notifier).setCategory(entries[idx].key);
                          context.push('/transactions');
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.take(5).map((e) {
                      final cat = MockData.instance.categoryById(e.key);
                      final pct = (e.value / total * 100).toStringAsFixed(0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                            Text('$pct%', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatefulWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (dismissed) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFFEFF3FF),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF3F6AF6), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMonthCard extends StatelessWidget {
  const _EmptyMonthCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.insert_chart_outlined_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No transactions this month', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Charts will appear once spending is recorded.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}


