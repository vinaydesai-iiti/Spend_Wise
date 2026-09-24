# SpendWise API

Node.js + Express + MongoDB backend for the **SpendWise** Flutter app (P05).
Implements the API contract in the spec (§7), plus JWT auth and a few
supporting endpoints the screens need but the contract table abbreviates.

## Stack

- Express 4, Mongoose 8 (MongoDB)
- JWT access + refresh tokens (`jsonwebtoken`), bcrypt password hashing
- helmet, cors, express-rate-limit, morgan

## Setup

```bash
cd backend
npm install
cp .env.example .env      # then edit .env — at minimum set MONGO_URI and the two JWT secrets
npm run seed               # creates 8 categories, a demo user, ~4 months of transactions
npm run dev                 # nodemon, or `npm start` for a plain node run
```

Server listens on `http://localhost:5000` by default; every route is under `/api`.

**Demo login** (created by `npm run seed`):
```
email:    demo@spendwise.app
password: password123
```

### Pointing the Flutter app at this server

Edit `lib/core/network/api_config.dart`:
- Android emulator → `http://10.0.2.2:5000/api`
- iOS simulator / desktop → `http://localhost:5000/api`
- Physical device → `http://<your-machine-LAN-IP>:5000/api`

## Auth

`POST /api/auth/login` returns a JWT `accessToken` (plus a `refreshToken`)
in the exact shape `AuthResult.fromJson` expects. Every other route
requires `Authorization: Bearer <accessToken>` — that's what the app's
`_AuthInterceptor` already attaches to every request once signed in.

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| POST | /api/auth/register | `{ name, email, password }` | not called by the shipped login screen, but needed to create an account |
| POST | /api/auth/login | `{ email, password }` | 422 on bad credentials |
| POST | /api/auth/refresh | `{ refreshToken }` | issues a new token pair |
| POST | /api/auth/logout | — (auth required) | invalidates the stored refresh token |
| GET | /api/auth/me | — (auth required) | current user |

## Core API (P05 §7)

All routes below require `Authorization: Bearer <token>`.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /api/transactions?month=&category=&q=&cursor=&limit= | Feed (F1/F7), cursor-paginated, newest first |
| PATCH | /api/transactions/:id | `{ category, applyToMerchant }` → recategorise (F2); 422 if `category` missing |
| GET | /api/transactions/export?month= | CSV download (F9) |
| GET | /api/summary?month= | Month summary (F3) |
| GET | /api/insights?month= | Server-generated insight cards (F10) |
| GET | /api/budgets?month= | Budgets with live-computed `spentPaise` (F4) |
| PUT | /api/budgets?month= | `{ category, limitPaise }` → set a limit; 422 if `limitPaise <= 0` |
| GET | /api/merchants?month= | Per-merchant totals/visits/avg, sorted by total desc (F6) |
| GET | /api/merchants/:merchantName/history?month= | A merchant's transactions (backs the Merchant detail screen) |
| GET | /api/categories | The 8 fixed categories (not yet called by the app — see note below) |

## Design notes

- **Money.** Every amount is an integer in paise. A spend is negative,
  a refund is positive (`amountPaise > 0`) — this matches `Txn` in the
  Flutter app exactly, including the "a refund reduces the category
  total" edge case (P05 §10): summing `-amountPaise` per category
  naturally nets it out.
- **Accuracy (P05 §8).** `Budget.spentPaise` is never stored — it's
  always recomputed live from `Transaction` documents at read time
  (`src/utils/aggregation.js`), so the Overview and Budgets screens can
  never disagree with the Feed about a category's total.
- **Merchant normalisation.** `Transaction.merchantKey` is computed with
  the exact same rule as `Txn.normalise()` in the Dart code
  (`"SWIGGY*1234"` → `"SWIGGY"`), so `MerchantRule` entries created by
  "apply to all" (F2) match reliably even when a merchant's suffix
  changes (P05 §10).
- **Budget alerts (F5).** `BudgetAlert` is a dedup ledger keyed on
  `(userId, category, month, threshold)` with a unique index, so a
  crossed 80%/100% threshold triggers at most once per category per
  month even under concurrent requests. Checked after a recategorise
  moves spend into a category (there's no transaction-creation endpoint
  in the given contract — the app's transactions are seeded, matching
  the spec's "Backend (simulated)" note in §9).
- **Categories.** The app currently ships the 8 categories statically in
  `lib/mock/mock_data.dart` (it owns their icon/color mapping). This API
  seeds the identical 8 categories server-side and exposes `GET
  /categories` as the authoritative source, but the Flutter repositories
  were left reading the static list rather than fetching it over the
  network — changing that would mean threading a new provider through
  every screen that reads `MockData.instance.categories` for a change
  that's cosmetic today. Worth doing if categories become
  server-editable later.
- **Cursor pagination.** `cursor` encodes the last row's `(at, _id)` as
  base64; pages are stable even when two transactions share a timestamp.

## Project layout

```
backend/
  server.js                 entry point
  src/
    app.js                  Express app: middleware, routes, error handling
    config/db.js             Mongoose connection
    models/                  User, Category, Transaction, Budget, MerchantRule, BudgetAlert
    middleware/               auth.js (JWT guard), errorHandler.js
    controllers/               one per resource
    routes/                    one per resource + index.js
    utils/                      jwt.js, ApiError.js, asyncHandler.js, aggregation.js
    seed/seed.js               category + demo user + demo transaction seeding
```

## Error shape

Every error response is `{ "message": "..." }` (plus an optional
`details` field), matching what the app's `ErrorMapper` already reads:
`401` → session expired, `422` → validation message shown inline, anything
else `>= 400` → generic server error with the status code in the message.
