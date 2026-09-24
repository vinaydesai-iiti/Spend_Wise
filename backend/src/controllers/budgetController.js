const Budget = require('../models/Budget');
const BudgetAlert = require('../models/BudgetAlert');
const Category = require('../models/Category');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { categoryTotals } = require('../utils/aggregation');

const MONTH_RE = /^\d{4}-\d{2}$/;

// Sensible defaults seeded the first time a user's budgets for a month
// are requested and none exist yet — mirrors MockData.budgetsFor's
// `defaults` map so a fresh account still sees useful progress bars
// instead of an empty screen.
const DEFAULT_LIMITS_PAISE = {
  food: 800000,
  groceries: 600000,
  transport: 300000,
  shopping: 500000,
  entertainment: 200000,
  bills: 400000,
  health: 250000,
  travel: 300000,
};
const FALLBACK_DEFAULT_LIMIT = 300000;

// GET /budgets?month= -> { items: Budget[] }
// F4 (budgets). `spentPaise` is always computed live from Transactions —
// never stored — so it can never disagree with the Overview/Feed totals
// (P05 §8 Accuracy). "Budget set mid-month: progress counts the whole
// month" (P05 §10) falls out naturally since spentPaise sums the whole
// month regardless of when the Budget document was created.
const getBudgets = asyncHandler(async (req, res) => {
  const { month } = req.query;
  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const [existing, spentMap, categories] = await Promise.all([
    Budget.find({ userId: req.userId, month }),
    categoryTotals(req.userId, month),
    Category.find(),
  ]);

  const byCategory = new Map(existing.map((b) => [b.category, b]));
  const missing = categories.filter((c) => !byCategory.has(c.id));

  if (missing.length > 0) {
    const toInsert = missing.map((c) => ({
      userId: req.userId,
      category: c.id,
      month,
      limitPaise: DEFAULT_LIMITS_PAISE[c.id] || FALLBACK_DEFAULT_LIMIT,
    }));
    // Race-safe: two concurrent first-loads may both try to seed the same
    // defaults. The unique (userId, category, month) index makes the
    // loser's insert a harmless duplicate-key error, not a crash.
    try {
      const inserted = await Budget.insertMany(toInsert, { ordered: false });
      for (const b of inserted) byCategory.set(b.category, b);
    } catch (err) {
      // ignore duplicate key races; re-read below covers it
    }
  }

  const all = missing.length > 0 ? await Budget.find({ userId: req.userId, month }) : existing;

  const items = all.map((b) => ({
    category: b.category,
    month: b.month,
    limitPaise: b.limitPaise,
    spentPaise: Math.max(0, spentMap.get(b.category) || 0),
  }));

  res.json({ items });
});

// PUT /budgets?month= — { category, limitPaise } -> updated Budget
// F4. 422 when limitPaise <= 0, mirroring BudgetRepository.setBudget's
// client-side mock check ("Budget must be greater than ₹0.").
const setBudget = asyncHandler(async (req, res) => {
  const { month } = req.query;
  const { category, limitPaise } = req.body || {};

  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }
  if (!category || typeof category !== 'string') {
    throw ApiError.unprocessable('category is required.');
  }
  if (typeof limitPaise !== 'number' || !Number.isFinite(limitPaise) || limitPaise <= 0) {
    throw ApiError.unprocessable('Budget must be greater than ₹0.');
  }

  const cat = await Category.findOne({ id: category });
  if (!cat) {
    throw ApiError.unprocessable('Unknown category.');
  }

  const budget = await Budget.findOneAndUpdate(
    { userId: req.userId, category, month },
    { limitPaise },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  const spentMap = await categoryTotals(req.userId, month);

  res.json({
    category: budget.category,
    month: budget.month,
    limitPaise: budget.limitPaise,
    spentPaise: Math.max(0, spentMap.get(category) || 0),
  });
});

/**
 * F5 (budget alerts) — called by transactionController after a new
 * transaction changes a category's spend. Checks the 80% and 100%
 * thresholds and returns which ones newly crossed, recording each in
 * BudgetAlert so it fires "at most one alert per category per threshold
 * per month" (P05 §4) even across concurrent requests, thanks to the
 * model's unique index.
 */
async function checkAndRecordAlerts(userId, category, month) {
  const [budget, spentMap] = await Promise.all([
    Budget.findOne({ userId, category, month }),
    categoryTotals(userId, month),
  ]);
  if (!budget || budget.limitPaise <= 0) return [];

  const spent = Math.max(0, spentMap.get(category) || 0);
  const pct = (spent / budget.limitPaise) * 100;
  const crossed = [];
  for (const threshold of [100, 80]) {
    if (pct >= threshold) {
      try {
        await BudgetAlert.create({ userId, category, month, threshold });
        crossed.push(threshold);
      } catch (err) {
        // duplicate key -> already alerted this threshold this month; skip
      }
      if (threshold === 100) break; // 100% implies 80% already fired earlier
    }
  }
  return crossed;
}

module.exports = { getBudgets, setBudget, checkAndRecordAlerts };
