const Transaction = require('../models/Transaction');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const MONTH_RE = /^\d{4}-\d{2}$/;

// GET /merchants?month= -> { items: MerchantSummary[] }
// F6 (merchant insights). Grouped by cleaned merchantName, sorted by
// total descending by default (P05 §4 acceptance criteria), matching
// MerchantRepository.getMerchants's client-side grouping logic exactly —
// including clamping a merchant's net total at 0 if refunds outweigh
// spends for the month.
const getMerchants = asyncHandler(async (req, res) => {
  const { month } = req.query;
  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const rows = await Transaction.aggregate([
    { $match: { userId: req.userId, month } },
    { $sort: { at: -1 } },
    {
      $group: {
        _id: '$merchantName',
        totalPaise: { $sum: { $multiply: ['$amountPaise', -1] } },
        visitCount: { $sum: 1 },
        // First document in each group after the $sort above is the most
        // recent transaction, so its category is used as the merchant's
        // representative category — same tie-break the client used
        // (`e.value.first.categoryId` on a list already sorted newest-first).
        category: { $first: '$category' },
      },
    },
    { $sort: { totalPaise: -1 } },
  ]);

  const items = rows.map((r) => ({
    merchantName: r._id,
    category: r.category,
    totalPaise: Math.max(0, r.totalPaise),
    visitCount: r.visitCount,
  }));

  res.json({ items });
});

// GET /merchants/:merchantName/history?month= -> Txn[]
// Backs the Merchant detail screen (route /merchants/:id in P05 §5).
// Not in the abbreviated API contract table (§7), but required by
// MerchantRepository.getMerchantHistory, which the screen calls directly.
const getMerchantHistory = asyncHandler(async (req, res) => {
  const { month } = req.query;
  const { merchantName } = req.params;
  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const rows = await Transaction.find({
    userId: req.userId,
    month,
    merchantName: decodeURIComponent(merchantName),
  }).sort({ at: -1 });

  res.json({
    items: rows.map((t) => ({
      id: t._id.toString(),
      merchantRaw: t.merchantRaw,
      merchantName: t.merchantName,
      category: t.category,
      amountPaise: t.amountPaise,
      at: t.at.toISOString(),
      mode: t.mode,
    })),
  });
});

module.exports = { getMerchants, getMerchantHistory };
