const mongoose = require('mongoose');

// Mirrors features/budgets/domain/budget.dart's `Budget`: category, month,
// limitPaise, spentPaise. Only `limitPaise` is actually persisted here —
// `spentPaise` is always recomputed live from Transactions at read time
// (see budgetController) so it can never drift out of sync with the feed,
// which is the "Accuracy" non-functional requirement in the spec (P05 §8:
// "Category totals equal the sum of their transactions to the paise").
const budgetSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    category: { type: String, required: true }, // Category.id
    month: { type: String, required: true }, // "YYYY-MM"
    limitPaise: { type: Number, required: true, min: 1 },
  },
  { timestamps: true, versionKey: false }
);

budgetSchema.index({ userId: 1, category: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('Budget', budgetSchema);
