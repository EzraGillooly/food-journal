import '../data/food_category.dart';
import '../data/food_entry.dart';

/// Derived, read-only summaries of a journal for Home and Insights. All values
/// are computed from the already-loaded entries list, so no extra queries.
class JournalStats {
  JournalStats(this.entries);

  final List<FoodEntry> entries;

  int get total => entries.length;

  int get madeCount => entries.where((e) => e.isHomemade).length;
  int get boughtCount => total - madeCount;

  /// Entry count per category, in enum order, only for non-empty categories.
  Map<FoodCategory, int> get byCategory {
    final counts = <FoodCategory, int>{};
    for (final e in entries) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return {
      for (final c in FoodCategory.values)
        if (counts[c] != null) c: counts[c]!,
    };
  }

  /// Count of entries at each whole-star rating bucket (1-5 stars), so a 9/10
  /// counts toward 5 stars, 7/10 toward 4, etc.
  List<int> get ratingBuckets {
    final buckets = List.filled(5, 0);
    for (final e in entries) {
      final star = ((e.rating + 1) ~/ 2).clamp(1, 5); // 1..5
      buckets[star - 1]++;
    }
    return buckets;
  }

  double get avgRating {
    if (entries.isEmpty) return 0;
    final sum = entries.fold<int>(0, (a, e) => a + e.rating);
    return sum / entries.length;
  }

  int get homemadePercent {
    if (entries.isEmpty) return 0;
    final made = entries.where((e) => e.isHomemade).length;
    return (made / entries.length * 100).round();
  }

  /// Entries eaten within the last 7 days.
  List<FoodEntry> get thisWeek {
    final cutoff = _today.subtract(const Duration(days: 6));
    return entries
        .where((e) => !_dayOf(e.eatenAt).isBefore(cutoff))
        .toList(growable: false);
  }

  /// The highest-rated recent entry (last ~14 days), for the editorial cover.
  /// Falls back to the highest-rated overall, then the newest.
  FoodEntry? get featured {
    if (entries.isEmpty) return null;
    final cutoff = _today.subtract(const Duration(days: 13));
    final recent = entries
        .where((e) => !_dayOf(e.eatenAt).isBefore(cutoff))
        .toList();
    final pool = recent.isNotEmpty ? recent : entries;
    return pool.reduce((a, b) => b.rating > a.rating ? b : a);
  }

  /// Entries other than [featured], newest first (already sorted upstream).
  List<FoodEntry> lately({int limit = 6}) {
    final f = featured;
    return entries.where((e) => e.id != f?.id).take(limit).toList();
  }

  /// Top-rated entries (9+), newest first.
  List<FoodEntry> get topRated =>
      entries.where((e) => e.rating >= 9).toList(growable: false);

  /// Most-logged category label, or null when empty.
  String? get topCategoryLabel {
    if (entries.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.category.label] = (counts[e.category.label] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Consecutive days (ending today or yesterday) that have at least one entry.
  int get currentStreak {
    if (entries.isEmpty) return 0;
    final days = entries.map((e) => _dayOf(e.eatenAt)).toSet();
    var cursor = _today;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Number of distinct days logged in the last [window] days (for a heatmap).
  List<bool> loggedDays({int window = 14}) {
    final days = entries.map((e) => _dayOf(e.eatenAt)).toSet();
    return List.generate(window, (i) {
      final d = _today.subtract(Duration(days: window - 1 - i));
      return days.contains(d);
    });
  }

  /// Entries from a previous month/day that matches today (memory resurfacing).
  /// Matches same month + day in an earlier year, or same day-of-month a full
  /// month or more ago, so there's usually something to show once there's
  /// history.
  List<FoodEntry> get onThisDay {
    final now = _today;
    return entries
        .where((e) {
          final d = _dayOf(e.eatenAt);
          if (d == now) return false;
          final monthsBack = (now.year - d.year) * 12 + (now.month - d.month);
          return d.day == now.day && monthsBack >= 1;
        })
        .toList(growable: false);
  }

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _dayOf(DateTime dt) {
    final l = dt.toLocal();
    return DateTime(l.year, l.month, l.day);
  }
}
