const Transaction = require('../models/Transaction');
const Category = require('../models/Category');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { categoryTotals, shiftMonth } = require('../utils/aggregation');

const MONTH_RE = /^\d{4}-\d{2}$/;

// GET /summary?month= -> MonthSummary
// F3 (monthly overview). Shape matches MonthSummary.fromJson exactly:
// { month, totalPaise, lastMonthTotalPaise, byCategory, byDay }.
// Zero transactions in a month returns the same "empty" shape the app's
// MonthSummary.empty() builds client-side (P05 §10 edge case) rather
// than an error, so the Overview screen renders its empty state instead
// of crashing.
const getSummary = asyncHandler(async (req, res) => {
  const { month } = req.query;
  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const [byCategoryMap, byDayRows, prevTotal] = await Promise.all([
    categoryTotals(req.userId, month),
    dailyTotals(req.userId, month),
    monthTotalNonNegative(req.userId, shiftMonth(month, -1)),
  ]);

  const byCategory = {};
  let total = 0;
  for (const [catId, net] of byCategoryMap.entries()) {
    byCategory[catId] = net;
    total += net;
  }

  res.json({
    month,
    totalPaise: Math.max(0, total),
    lastMonthTotalPaise: prevTotal,
    byCategory,
    byDay: byDayRows,
  });
});

async function dailyTotals(userId, month) {
  const rows = await Transaction.aggregate([
    { $match: { userId, month } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$at' } },
        net: { $sum: { $multiply: ['$amountPaise', -1] } },
      },
    },
    { $sort: { _id: 1 } },
  ]);
  return rows.map((r) => ({
    date: new Date(`${r._id}T00:00:00.000Z`).toISOString(),
    amountPaise: r.net,
  }));
}

async function monthTotalNonNegative(userId, month) {
  const totals = await categoryTotals(userId, month);
  let sum = 0;
  for (const v of totals.values()) sum += v;
  return Math.max(0, sum);
}

// GET /insights?month= -> { cards: string[] }
// F10 (insight cards) — "Could" priority, server-generated. Logic mirrors
// SummaryRepository.getInsights: a month-over-month % change card (when
// the change is at least 1%) plus a "top category" card, skipped
// entirely for an empty month.
const getInsights = asyncHandler(async (req, res) => {
  const month = req.query.month || defaultMonth();
  if (!MONTH_RE.test(month)) {
    throw ApiError.badRequest('month must be formatted YYYY-MM.');
  }

  const byCategoryMap = await categoryTotals(req.userId, month);
  let total = 0;
  for (const v of byCategoryMap.values()) total += v;
  total = Math.max(0, total);

  if (total === 0 && byCategoryMap.size === 0) {
    return res.json({ cards: [] });
  }

  const prevTotal = await monthTotalNonNegative(req.userId, shiftMonth(month, -1));
  const cards = [];

  if (prevTotal > 0) {
    const pct = ((total - prevTotal) / prevTotal) * 100;
    if (Math.abs(pct) >= 1) {
      const dir = pct > 0 ? 'more' : 'less';
      cards.push(`You spent ${Math.abs(pct).toFixed(0)}% ${dir} than last month`);
    }
  }

  if (byCategoryMap.size > 0) {
    let topId = null;
    let topVal = -Infinity;
    for (const [id, val] of byCategoryMap.entries()) {
      if (val > topVal) {
        topVal = val;
        topId = id;
      }
    }
    if (topId) {
      const cat = await Category.findOne({ id: topId });
      cards.push(`${cat ? cat.name : topId} was your top category this month`);
    }
  }

  res.json({ cards });
});

function defaultMonth() {
  const now = new Date();
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
}

module.exports = { getSummary, getInsights };
