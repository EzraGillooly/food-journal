import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/entries/application/feed_filter.dart';
import 'package:food_journal/features/entries/data/food_category.dart';
import 'package:food_journal/features/entries/data/food_entry.dart';

FoodEntry _e({
  String name = 'Ramen',
  FoodCategory category = FoodCategory.dinner,
  bool homemade = true,
}) => FoodEntry(
  name: name,
  rating: 8,
  category: category,
  isHomemade: homemade,
  eatenAt: DateTime.utc(2026, 7, 11),
);

void main() {
  test('empty filter matches everything', () {
    expect(const FeedFilter().matches(_e()), isTrue);
    expect(const FeedFilter().isActive, isFalse);
  });

  test('category filter', () {
    const f = FeedFilter(category: FoodCategory.dinner);
    expect(f.matches(_e(category: FoodCategory.dinner)), isTrue);
    expect(f.matches(_e(category: FoodCategory.lunch)), isFalse);
    expect(f.isActive, isTrue);
  });

  test('made/bought filter', () {
    const made = FeedFilter(source: MadeBoughtFilter.made);
    expect(made.matches(_e(homemade: true)), isTrue);
    expect(made.matches(_e(homemade: false)), isFalse);

    const bought = FeedFilter(source: MadeBoughtFilter.bought);
    expect(bought.matches(_e(homemade: false)), isTrue);
    expect(bought.matches(_e(homemade: true)), isFalse);
  });

  test('name search is case-insensitive substring', () {
    const f = FeedFilter(query: 'RAM');
    expect(f.matches(_e(name: 'Miso ramen')), isTrue);
    expect(f.matches(_e(name: 'Toast')), isFalse);
  });

  test('filters combine with AND', () {
    const f = FeedFilter(
      category: FoodCategory.dinner,
      source: MadeBoughtFilter.made,
      query: 'ramen',
    );
    expect(
      f.matches(
        _e(name: 'Ramen', category: FoodCategory.dinner, homemade: true),
      ),
      isTrue,
    );
    expect(
      f.matches(
        _e(name: 'Ramen', category: FoodCategory.dinner, homemade: false),
      ),
      isFalse,
    );
  });
}
