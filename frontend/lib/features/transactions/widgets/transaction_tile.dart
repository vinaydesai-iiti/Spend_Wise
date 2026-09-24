import 'package:flutter/material.dart';
import 'package:spend_wise/core/utils/money.dart';
import 'package:spend_wise/core/utils/date_format.dart';
import 'package:spend_wise/mock/mock_data.dart';
import 'package:spend_wise/features/transactions/domain/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Txn txn;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.txn, this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = MockData.instance.categoryById(txn.categoryId);
    final isRefund = txn.isRefund;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.merchantName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.name} · ${DateFmt.time(txn.at)}',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              Money.rupees(txn.amountPaise, showSign: true),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isRefund ? const Color(0xFF2FB380) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
