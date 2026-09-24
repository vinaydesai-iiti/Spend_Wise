const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const MerchantRule = require('../models/MerchantRule');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { checkAndRecordAlerts } = require('./budgetController');

const DEFAULT_PAGE_SIZE = 50;
const MONTH_RE = /^\d{4}-\d{2}$/;

function encodeCursor(doc) {
  return Buffer.from(JSON.stringify({ at: doc.at.toISOString(), id: doc._id.toString() })).toString(
    'base64url'
  );
}

function decodeCursor(cursor) {
  try {
    const { at, id } = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
    return { at: new Date(at), id: new mongoose.Types.ObjectId(id) };
  } catch (err) {
    throw ApiError.badRequest('Invalid cursor.');
  }
}

// GET /transactions?month=&category=&q=&cursor=&limit=
// F1 (categorised feed) / F7 (search + filters). Sorted newest first,
// matching MockData._generate()'s `txns.sort((a, b) => b.at.compareTo(a.at))`
// and cursor-paginated by (at, _id) so pages never skip or repeat a row
// even if two transactions share the same timestamp.
const getFeed = asyncHandler(async (req, res) => {
  const { month, category, q, cursor } = req.query;
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || DEFAULT_PAGE_SIZE, 1), 200);

  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const filter = { userId: req.userId, month };
  if (category && category !== 'all') {
    filter.category = category;
  }
  if (q && q.trim()) {
    // Case-insensitive contains match on the cleaned merchant name,
    // mirroring `t.merchantName.toLowerCase().contains(q)` in the app.
    filter.merchantName = { $regex: escapeRegex(q.trim()), $options: 'i' };
  }
  if (cursor) {
    const { at, id } = decodeCursor(cursor);
    filter.$or = [{ at: { $lt: at } }, { at, _id: { $lt: id } }];
  }

  const rows = await Transaction.find(filter)
    .sort({ at: -1, _id: -1 })
    .limit(limit + 1)
    .lean({ virtuals: false });

  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;
  const nextCursor = hasMore ? encodeCursor(page[page.length - 1]) : null;

  res.json({
    items: page.map(toPublicJSON),
    nextCursor,
  });
});

function toPublicJSON(t) {
  return {
    id: t._id.toString(),
    merchantRaw: t.merchantRaw,
    merchantName: t.merchantName,
    category: t.category,
    amountPaise: t.amountPaise,
    at: new Date(t.at).toISOString(),
    mode: t.mode,
  };
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// PATCH /transactions/:id — { category, applyToMerchant } -> updated txn
// F2 (recategorise and learn). When applyToMerchant is true, every past
// AND future transaction with the same normalised merchant key is
// updated too, and a MerchantRule is upserted so future imports
// auto-categorise the same way — matching MockData.applyRecategorise.
const recategorise = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { category, applyToMerchant } = req.body || {};

  if (!category || typeof category !== 'string') {
    throw ApiError.unprocessable('category is required.');
  }

  const txn = await Transaction.findOne({ _id: id, userId: req.userId });
  if (!txn) {
    throw ApiError.notFound('Transaction not found.');
  }

  txn.category = category;
  await txn.save();

  let updatedCount = 1;

  if (applyToMerchant) {
    const key = txn.merchantKey;

    await MerchantRule.findOneAndUpdate(
      { userId: req.userId, merchantKey: key },
      { category },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    const result = await Transaction.updateMany(
      { userId: req.userId, merchantKey: key, _id: { $ne: txn._id } },
      { $set: { category } }
    );
    updatedCount += result.modifiedCount || 0;
  }

  // F5 — recategorising can push the destination category over 80%/100%
  // of its budget; check and dedup-record any newly crossed thresholds.
  const alerts = await checkAndRecordAlerts(req.userId, category, txn.month);

  res.json({ transaction: toPublicJSON(txn), updatedCount, alerts });
});

// GET /transactions/export?month= — CSV with a header row and ISO dates
// (F9). The app triggers the OS share sheet with the returned file; the
// export itself never has to leave the device except through that action.
const exportCsv = asyncHandler(async (req, res) => {
  const { month } = req.query;
  if (!month || !MONTH_RE.test(month)) {
    throw ApiError.badRequest('month is required, formatted YYYY-MM.');
  }

  const rows = await Transaction.find({ userId: req.userId, month }).sort({ at: 1 }).lean();

  const header = ['date', 'merchant', 'category', 'amountPaise', 'mode'];
  const lines = [header.join(',')];
  for (const t of rows) {
    const cells = [
      new Date(t.at).toISOString(),
      csvEscape(t.merchantName),
      t.category,
      String(t.amountPaise),
      t.mode,
    ];
    lines.push(cells.join(','));
  }

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="spendwise-${month}.csv"`);
  res.status(200).send(lines.join('\n'));
});

function csvEscape(value) {
  const s = String(value ?? '');
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

module.exports = { getFeed, recategorise, exportCsv };
