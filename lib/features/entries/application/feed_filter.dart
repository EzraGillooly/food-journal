import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_category.dart';
import '../data/food_entry.dart';

/// Source filter for the feed: made, bought, or either.
enum MadeBoughtFilter { any, made, bought }

/// The active feed filters. All combine (AND).
class FeedFilter {
  const FeedFilter({
    this.category,
    this.source = MadeBoughtFilter.any,
    this.query = '',
  });

  /// null means "all categories".
  final FoodCategory? category;
  final MadeBoughtFilter source;
  final String query;

  bool get isActive =>
      category != null ||
      source != MadeBoughtFilter.any ||
      query.trim().isNotEmpty;

  FeedFilter copyWith({
    FoodCategory? category,
    bool clearCategory = false,
    MadeBoughtFilter? source,
    String? query,
  }) {
    return FeedFilter(
      category: clearCategory ? null : (category ?? this.category),
      source: source ?? this.source,
      query: query ?? this.query,
    );
  }

  bool matches(FoodEntry e) {
    if (category != null && e.category != category) return false;
    if (source == MadeBoughtFilter.made && !e.isHomemade) return false;
    if (source == MadeBoughtFilter.bought && e.isHomemade) return false;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && !_haystack(e).contains(q)) return false;
    return true;
  }

  /// All searchable text for an entry: every dish's name/notes/recipe, plus the
  /// location and category label, so search isn't limited to the dish name.
  String _haystack(FoodEntry e) {
    final parts = <String?>[
      for (final d in e.dishes) ...[d.name, d.notes, d.recipe],
      e.location,
      e.category.label,
    ];
    return parts.whereType<String>().join(' ').toLowerCase();
  }
}

class FeedFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void setCategory(FoodCategory? c) => state = c == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: c);

  void toggleCategory(FoodCategory c) => state = state.category == c
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: c);

  void setSource(MadeBoughtFilter s) => state = state.copyWith(source: s);

  void setQuery(String q) => state = state.copyWith(query: q);

  void clear() => state = const FeedFilter();
}

final feedFilterProvider = NotifierProvider<FeedFilterController, FeedFilter>(
  FeedFilterController.new,
);
