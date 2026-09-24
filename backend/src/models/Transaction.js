const mongoose = require('mongoose');

const PAYMENT_MODES = ['upi', 'card', 'cash', 'netbanking'];

// Mirrors features/transactions/domain/transaction.dart's `Txn` exactly:
// id, merchantRaw, merchantName, category, amountPaise, at, mode.
// amountPaise is negative for a spend, positive for a refund/credit —
// the sign convention the whole app (and the aggregation below) relies on.
const transactionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    merchantRaw: { type: String, required: true, trim: true },
    merchantName: { type: String, required: true, trim: true },
    // Normalised merchant key ("SWIGGY*1234" -> "SWIGGY"), used to match
    // MerchantRule entries and to group merchant insights. Computed on
    // save, never sent by the client.
    merchantKey: { type: String, required: true, index: true },
    category: { type: String, required: true, index: true }, // Category.id
    amountPaise: { type: Number, required: true },
    at: { type: Date, required: true },
    mode: { type: String, enum: PAYMENT_MODES, required: true },
    // Denormalised "YYYY-MM" of `at` (server-local/UTC), so every
    // month-scoped query (feed, summary, merchants) is a plain indexed
    // equality match instead of a date-range scan.
    month: { type: String, required: true, index: true },
  },
  { timestamps: true, versionKey: false }
);

transactionSchema.index({ userId: 1, month: 1, at: -1, _id: -1 });
transactionSchema.index({ userId: 1, merchantKey: 1 });

// Matches Txn.normalise() in the Flutter app bit-for-bit:
//   raw.split(/[*#]/).first.trim().toUpperCase().replaceAll(/\s+/, ' ')
function normaliseMerchant(raw) {
  const withoutSuffix = String(raw).split(/[*#]/)[0];
  return withoutSuffix.trim().toUpperCase().replace(/\s+/g, ' ');
}

function monthKeyOf(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

transactionSchema.pre('validate', function preValidate(next) {
  if (this.merchantRaw) {
    this.merchantKey = normaliseMerchant(this.merchantRaw);
  }
  if (this.at) {
    this.month = monthKeyOf(new Date(this.at));
  }
  next();
});

// Shape that matches Txn.fromJson exactly: id, merchantRaw, merchantName,
// category, amountPaise, at (ISO-8601 UTC), mode.
transactionSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id.toString(),
    merchantRaw: this.merchantRaw,
    merchantName: this.merchantName,
    category: this.category,
    amountPaise: this.amountPaise,
    at: this.at.toISOString(),
    mode: this.mode,
  };
};

transactionSchema.statics.normaliseMerchant = normaliseMerchant;
transactionSchema.statics.monthKeyOf = monthKeyOf;
transactionSchema.statics.PAYMENT_MODES = PAYMENT_MODES;

module.exports = mongoose.model('Transaction', transactionSchema);
