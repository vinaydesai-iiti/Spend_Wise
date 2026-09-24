const mongoose = require('mongoose');

// Mirrors features/merchants/domain/merchant_rule.dart's `MerchantRule`.
// Created/updated whenever a user recategorises a transaction with
// "apply to all" (F2), so future transactions from the same normalised
// merchant auto-categorise the same way.
const merchantRuleSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    merchantKey: { type: String, required: true }, // normalised merchant string
    category: { type: String, required: true }, // Category.id
  },
  { timestamps: true, versionKey: false }
);

merchantRuleSchema.index({ userId: 1, merchantKey: 1 }, { unique: true });

module.exports = mongoose.model('MerchantRule', merchantRuleSchema);
