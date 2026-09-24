const mongoose = require('mongoose');

// F5 "Budget alerts" — a transaction that pushes a category over 80% or
// 100% of its budget should notify the user, but "at most one alert per
// category per threshold per month" (P05 §4). This collection is the
// dedup ledger: before sending a notification, the caller checks whether
// a row already exists for (userId, category, month, threshold); if not,
// it inserts one and sends. See budgetController.checkAndRecordAlerts.
const budgetAlertSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    category: { type: String, required: true },
    month: { type: String, required: true },
    threshold: { type: Number, enum: [80, 100], required: true },
  },
  { timestamps: true, versionKey: false }
);

budgetAlertSchema.index({ userId: 1, category: 1, month: 1, threshold: 1 }, { unique: true });

module.exports = mongoose.model('BudgetAlert', budgetAlertSchema);
