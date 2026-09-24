/**
 * Seeds the database with:
 *   - the 8 fixed categories (must match core/models/category.dart's
 *     MockData.instance.categories exactly, id/name/icon/color)
 *   - one demo user
 *   - ~4 months of realistic transactions for that user, generated with
 *     the same merchant list and general shape as mock/mock_data.dart's
 *     MockData._generate(), so the app looks the same as it did against
 *     the mock backend once it's pointed at this API.
 *
 * Run with: npm run seed
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/db');

const User = require('../models/User');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const MerchantRule = require('../models/MerchantRule');
const BudgetAlert = require('../models/BudgetAlert');

const DEMO_EMAIL = 'demo@spendwise.app';
const DEMO_PASSWORD = 'password123';

const CATEGORIES = [
  { id: 'food', name: 'Food & Dining', icon: 'food', color: 'FF7A59' },
  { id: 'groceries', name: 'Groceries', icon: 'groceries', color: '3CB371' },
  { id: 'transport', name: 'Transport', icon: 'transport', color: '4C8BF5' },
  { id: 'shopping', name: 'Shopping', icon: 'shopping', color: 'B06AF2' },
  { id: 'entertainment', name: 'Entertainment', icon: 'entertainment', color: 'F2B705' },
  { id: 'bills', name: 'Bills & Utilities', icon: 'bills', color: '5C6B7A' },
  { id: 'health', name: 'Health', icon: 'health', color: 'E0526A' },
  { id: 'travel', name: 'Travel', icon: 'travel', color: '16A3A3' },
];

const MERCHANTS = {
  SWIGGY: 'food',
  ZOMATO: 'food',
  STARBUCKS: 'food',
  BIGBASKET: 'groceries',
  BLINKIT: 'groceries',
  DMART: 'groceries',
  UBER: 'transport',
  OLA: 'transport',
  IRCTC: 'travel',
  INDIGO: 'travel',
  AMAZON: 'shopping',
  MYNTRA: 'shopping',
  FLIPKART: 'shopping',
  NETFLIX: 'entertainment',
  BOOKMYSHOW: 'entertainment',
  SPOTIFY: 'entertainment',
  BESCOM: 'bills',
  AIRTEL: 'bills',
  'ACT FIBERNET': 'bills',
  'APOLLO PHARMACY': 'health',
  PRACTO: 'health',
};
const PAYMENT_MODES = ['upi', 'card', 'cash', 'netbanking'];

// Small deterministic PRNG (mulberry32) so re-running the seed produces
// the same dataset, mirroring `Random(42)` in mock_data.dart.
function mulberry32(seed) {
  let a = seed;
  return function rnd() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function titleCase(s) {
  return s
    .toLowerCase()
    .split(' ')
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
    .join(' ');
}

function monthKey(y, m /* 1-12 */) {
  return `${y}-${String(m).padStart(2, '0')}`;
}

async function seed() {
  await connectDB();

  console.log('[seed] clearing existing demo data...');
  const existingUser = await User.findOne({ email: DEMO_EMAIL });
  if (existingUser) {
    await Promise.all([
      Transaction.deleteMany({ userId: existingUser._id }),
      Budget.deleteMany({ userId: existingUser._id }),
      MerchantRule.deleteMany({ userId: existingUser._id }),
      BudgetAlert.deleteMany({ userId: existingUser._id }),
      User.deleteOne({ _id: existingUser._id }),
    ]);
  }

  console.log('[seed] upserting categories...');
  for (const c of CATEGORIES) {
    // eslint-disable-next-line no-await-in-loop
    await Category.findOneAndUpdate({ id: c.id }, c, { upsert: true, new: true });
  }

  console.log('[seed] creating demo user...');
  const user = new User({ name: 'Demo User', email: DEMO_EMAIL });
  await user.setPassword(DEMO_PASSWORD);
  await user.save();

  console.log('[seed] generating transactions...');
  const rnd = mulberry32(42);
  const merchantKeys = Object.keys(MERCHANTS);
  const now = new Date();
  const docs = [];

  for (let mOffset = 0; mOffset < 4; mOffset += 1) {
    let y = now.getUTCFullYear();
    let m = now.getUTCMonth() + 1 - mOffset; // 1-12
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    const mk = monthKey(y, m);
    const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();
    const capDay = mOffset === 0 ? Math.min(now.getUTCDate(), daysInMonth) : daysInMonth;
    const count = mOffset === 0 ? 45 : 60 + Math.floor(rnd() * 20);

    for (let i = 0; i < count; i += 1) {
      const merchant = merchantKeys[Math.floor(rnd() * merchantKeys.length)];
      const category = MERCHANTS[merchant];
      const day = 1 + Math.floor(rnd() * capDay);
      const isRefund = Math.floor(rnd() * 30) === 0;
      const baseAmount = 5000 + Math.floor(rnd() * 250000); // paise: ₹50–₹2500
      const amountPaise = isRefund ? baseAmount : -baseAmount;
      const mode = PAYMENT_MODES[Math.floor(rnd() * PAYMENT_MODES.length)];
      const hour = 8 + Math.floor(rnd() * 14);
      const minute = Math.floor(rnd() * 60);
      const merchantRaw = merchant + (Math.floor(rnd() * 2) === 0 ? `*${1000 + Math.floor(rnd() * 9000)}` : '');

      docs.push({
        userId: user._id,
        merchantRaw,
        merchantName: titleCase(merchant),
        category,
        amountPaise,
        at: new Date(Date.UTC(y, m - 1, day, hour, minute)),
        mode,
        // merchantKey / month are filled by the pre('validate') hook, but
        // insertMany skips document middleware for validation by default
        // unless { runValidators: true }, so compute them here too.
        merchantKey: merchantRaw.split(/[*#]/)[0].trim().toUpperCase().replace(/\s+/g, ' '),
        month: mk,
      });
    }
  }

  await Transaction.insertMany(docs);
  console.log(`[seed] inserted ${docs.length} transactions across 4 months.`);

  console.log('[seed] done.');
  console.log('');
  console.log('  Demo login:');
  console.log(`    email:    ${DEMO_EMAIL}`);
  console.log(`    password: ${DEMO_PASSWORD}`);
  console.log('');

  await mongoose.connection.close();
  process.exit(0);
}

seed().catch((err) => {
  console.error('[seed] failed:', err);
  process.exit(1);
});
