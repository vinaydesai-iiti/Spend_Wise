import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/mock/mock_data.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';
import 'package:spend_wise/features/transactions/state/feed_providers.dart';
import 'package:spend_wise/features/transactions/data/transaction_repository.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String txnId;
  final String month;
  const TransactionDetailScreen({super.key, required this.txnId, required this.month});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider(widget.month));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txns) {
          final txn = txns.where((t) => t.id == widget.txnId).firstOrNull;
          if (txn == null) {
            return const Center(child: Text('Transaction not found'));
          }
          final category = MockData.instance.categoryById(txn.categoryId);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(category.icon, color: category.color, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text(txn.merchantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      Money.rupees(txn.amountPaise, showSign: true),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: txn.isRefund ? const Color(0xFF2FB380) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Date', '${DateFmt.dayHeader(txn.at)} · ${DateFmt.time(txn.at)}'),
                      const Divider(height: 20),
                      _row('Category', category.name),
                      const Divider(height: 20),
                      _row('Payment mode', txn.mode.name.toUpperCase()),
                      const Divider(height: 20),
                      _row('Raw merchant string', txn.merchantRaw),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Recategorise'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _openRecategoriseSheet(context, txn),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ),
      ],
    );
  }

  void _openRecategoriseSheet(BuildContext context, Txn txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecategoriseSheet(
        txnId: txn.id,
        month: widget.month,
        currentCategoryId: txn.categoryId,
        merchantName: txn.merchantName,
      ),
    );
  }
}

class _RecategoriseSheet extends ConsumerStatefulWidget {
  final String txnId;
  final String month;
  final String currentCategoryId;
  final String merchantName;
  const _RecategoriseSheet({
    required this.txnId,
    required this.month,
    required this.currentCategoryId,
    required this.merchantName,
  });

  @override
  ConsumerState<_RecategoriseSheet> createState() => _RecategoriseSheetState();
}

class _RecategoriseSheetState extends ConsumerState<_RecategoriseSheet> {
  bool applyToAll = false;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final categories = MockData.instance.categories;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((c) {
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: saving ? null : () => _save(c.id),
                child: Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: c.id == widget.currentCategoryId ? c.color.withValues(alpha: 0.16) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: c.id == widget.currentCategoryId ? Border.all(color: c.color, width: 1.4) : null,
                  ),
                  child: Column(
                    children: [
                      Icon(c.icon, color: c.color),
                      const SizedBox(height: 6),
                      Text(c.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: applyToAll,
            onChanged: saving ? null : (v) => setState(() => applyToAll = v),
            title: Text('Apply to all "${widget.merchantName}" transactions'),
            subtitle: const Text('Updates past and future matches', style: TextStyle(fontSize: 12)),
          ),
          if (saving) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Future<void> _save(String newCategoryId) async {
    setState(() => saving = true);
    final previousCategoryId = widget.currentCategoryId;
    try {
      await ref.read(transactionRepositoryProvider).recategorise(
            txnId: widget.txnId,
            month: widget.month,
            newCategoryId: newCategoryId,
            applyToAllMerchant: applyToAll,
          );
      ref.invalidate(feedProvider(widget.month));
      ref.invalidate(feedGroupedProvider(widget.month));
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category updated'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              await ref.read(transactionRepositoryProvider).recategorise(
                    txnId: widget.txnId,
                    month: widget.month,
                    newCategoryId: previousCategoryId,
                    applyToAllMerchant: applyToAll,
                  );
              ref.invalidate(feedProvider(widget.month));
              ref.invalidate(feedGroupedProvider(widget.month));
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
