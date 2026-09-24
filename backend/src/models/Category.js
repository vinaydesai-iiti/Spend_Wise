const mongoose = require('mongoose');

// Global (not per-user) — matches the fixed 8-category set the Flutter
// app already ships client-side in mock/mock_data.dart. `id` is a short
// slug ('food', 'groceries', ...) because that's the string every other
// collection (Transaction.category, Budget.category, MerchantRule.category)
// references — never a Mongo ObjectId.
const categorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true },
    icon: { type: String, required: true },
    // 6-digit hex without '#', matching Category.fromJson's _colorFromHex.
    color: { type: String, required: true },
  },
  { timestamps: true, versionKey: false }
);

categorySchema.methods.toPublicJSON = function toPublicJSON() {
  return { id: this.id, name: this.name, icon: this.icon, color: this.color };
};

module.exports = mongoose.model('Category', categorySchema);
