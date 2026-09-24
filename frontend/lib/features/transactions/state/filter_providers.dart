import 'package:flutter_riverpod/flutter_riverpod.dart';

/// F7 — filters combine (search + category + amount range + date range)
/// and must survive navigating away and back. Because this lives in a
/// StateNotifierProvider (not scoped to a screen), it naturally persists
/// for the lifetime of the app / ProviderScope.
class FeedFilterState {
  final String query;
  final String categoryId; // 'all' or a category id
  final int? minAmountPaise;
  final int? maxAmountPaise;
  final FeedDateRange? dateRange;

  const FeedFilterState({
    this.query = '',
    this.categoryId = 'all',
    this.minAmountPaise,
    this.maxAmountPaise,
    this.dateRange,
  });

  bool get isActive =>
      query.isNotEmpty ||
      categoryId != 'all' ||
      minAmountPaise != null ||
      maxAmountPaise != null ||
      dateRange != null;

  FeedFilterState copyWith({
    String? query,
    String? categoryId,
    int? minAmountPaise,
    int? maxAmountPaise,
    FeedDateRange? dateRange,
    bool clearAmount = false,
    bool clearDate = false,
  }) {
    return FeedFilterState(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      minAmountPaise: clearAmount ? null : (minAmountPaise ?? this.minAmountPaise),
      maxAmountPaise: clearAmount ? null : (maxAmountPaise ?? this.maxAmountPaise),
      dateRange: clearDate ? null : (dateRange ?? this.dateRange),
    );
  }
}

/// Deliberately our own type (not Flutter's material DateTimeRange) so
/// this provider file has no Flutter/material dependency at all.
class FeedDateRange {
  final DateTime start;
  final DateTime end;
  const FeedDateRange({required this.start, required this.end});
}

class FeedFilterNotifier extends StateNotifier<FeedFilterState> {
  FeedFilterNotifier() : super(const FeedFilterState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(String id) => state = state.copyWith(categoryId: id);
  void setAmountRange(int? min, int? max) =>
      state = state.copyWith(minAmountPaise: min, maxAmountPaise: max);
  void setDateRange(FeedDateRange? range) =>
      state = range == null ? state.copyWith(clearDate: true) : state.copyWith(dateRange: range);
  void clearAll() => state = const FeedFilterState();
}

final filterStateNotifierProvider =
    StateNotifierProvider<FeedFilterNotifier, FeedFilterState>((ref) {
  return FeedFilterNotifier();
});
