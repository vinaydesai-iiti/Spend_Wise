const Transaction = require('../models/Transaction');

/**
 * Category totals for a user's month, in the app's "spend positive"
 * convention (net = -amountPaise summed, so a spend adds and a refund
 * subtracts — see the "refund reduces category total" edge case in
 * P05 §10). Used by both the summary and budgets endpoints so the two
 * screens can never disagree about a category's total to the paise
 * (P05 §8 Accuracy).
 *
 * Returns a Map<categoryId, paise>.
 */
async function categoryTotals(userId, month) {
  const rows = await Transaction.aggregate([
    { $match: { userId, month } },
    { $group: { _id: '$category', net: { $sum: { $multiply: ['$amountPaise', -1] } } } },
  ]);
  const map = new Map();
  for (const row of rows) {
    map.set(row._id, row.net);
  }
  return map;
}

/** Total spend across all categories for a user's month (paise, floor 0). */
async function monthTotal(userId, month) {
  const totals = await categoryTotals(userId, month);
  let sum = 0;
  for (const v of totals.values()) sum += v;
  return Math.max(0, sum);
}

function shiftMonth(month, delta) {
  const [yStr, mStr] = month.split('-');
  let y = Number(yStr);
  let m = Number(mStr) + delta;
  while (m < 1) {
    m += 12;
    y -= 1;
  }
  while (m > 12) {
    m -= 12;
    y += 1;
  }
  return `${y}-${String(m).padStart(2, '0')}`;
}

module.exports = { categoryTotals, monthTotal, shiftMonth };
