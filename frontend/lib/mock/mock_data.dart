import 'package:flutter/material.dart';
import 'package:spend_wise/core/models/category.dart';

/// The fixed 8-category catalogue.
///
/// Every other kind of data (transactions, summaries, budgets, merchant
/// insights) now comes from the real backend — see the `*_repository.dart`
/// files under `features/*/data/`, which call the Node.js/Express API in
/// `/backend`. Categories are the one thing still defined client-side:
/// the app owns their icon/color presentation, and the same 8 ids are
/// seeded server-side (`backend/src/seed/seed.js`) so `category` values
/// returned by the API always resolve here.
class MockData {
  MockData._();
  static final MockData instance = MockData._();

  final List<Category> categories = const [
    Category(id: 'food', name: 'Food & Dining', iconKey: 'food', color: Color(0xFFFF7A59)),
    Category(id: 'groceries', name: 'Groceries', iconKey: 'groceries', color: Color(0xFF3CB371)),
    Category(id: 'transport', name: 'Transport', iconKey: 'transport', color: Color(0xFF4C8BF5)),
    Category(id: 'shopping', name: 'Shopping', iconKey: 'shopping', color: Color(0xFFB06AF2)),
    Category(id: 'entertainment', name: 'Entertainment', iconKey: 'entertainment', color: Color(0xFFF2B705)),
    Category(id: 'bills', name: 'Bills & Utilities', iconKey: 'bills', color: Color(0xFF5C6B7A)),
    Category(id: 'health', name: 'Health', iconKey: 'health', color: Color(0xFFE0526A)),
    Category(id: 'travel', name: 'Travel', iconKey: 'travel', color: Color(0xFF16A3A3)),
  ];

  Category categoryById(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.last);
}
