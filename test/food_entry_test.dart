import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/entries/data/dish.dart';
import 'package:food_journal/features/entries/data/food_category.dart';
import 'package:food_journal/features/entries/data/food_entry.dart';

void main() {
  test('fromMap parses a legacy row (no dishes array)', () {
    final e = FoodEntry.fromMap({
      'id': 'abc',
      'user_id': 'u1',
      'name': 'Miso ramen',
      'rating': 9,
      'category': 'dinner',
      'is_homemade': true,
      'notes': 'cozy',
      'recipe': null,
      'location': 'Home',
      'photo_path': 'u1/abc.jpg',
      'eaten_at': '2026-07-11T18:30:00.000Z',
      'created_at': '2026-07-11T18:31:00.000Z',
    });
    expect(e.name, 'Miso ramen');
    expect(e.rating, 9);
    expect(e.dishes.length, 1);
    expect(e.category, FoodCategory.dinner);
    expect(e.isHomemade, isTrue);
    expect(e.photoPath, 'u1/abc.jpg');
  });

  test('fromMap parses a multi-dish row', () {
    final e = FoodEntry.fromMap({
      'name': 'Ramen',
      'rating': 9,
      'category': 'dinner',
      'is_homemade': true,
      'eaten_at': '2026-07-11T18:30:00.000Z',
      'dishes': [
        {'name': 'Ramen', 'rating': 9, 'notes': 'rich'},
        {'name': 'Gyoza', 'rating': 7},
      ],
    });
    expect(e.dishes.length, 2);
    expect(e.name, 'Ramen'); // primary dish
    expect(e.dishes[1].name, 'Gyoza');
    expect(e.dishes[1].rating, 7);
  });

  test('toInsert mirrors the primary dish and writes the dishes array', () {
    final e = FoodEntry(
      dishes: [
        Dish(name: 'Toast', rating: 6, notes: '   ', recipe: ''),
        Dish(name: 'Jam', rating: 8),
      ],
      category: FoodCategory.breakfast,
      isHomemade: true,
      location: 'Kitchen',
      eatenAt: DateTime.utc(2026, 7, 11, 8),
    );
    final map = e.toInsert();
    expect(map['name'], 'Toast');
    expect(map['rating'], 6);
    expect(map['notes'], isNull); // whitespace cleaned
    expect(map['recipe'], isNull); // empty cleaned
    expect(map['location'], 'Kitchen');
    expect(map['category'], 'breakfast');
    expect((map['dishes'] as List).length, 2);
    expect(map.containsKey('id'), isFalse);
    expect(map.containsKey('user_id'), isFalse);
  });

  test('copyWith sets photoPath', () {
    final e = FoodEntry(
      dishes: [Dish(name: 'X', rating: 5)],
      category: FoodCategory.snack,
      isHomemade: false,
      eatenAt: DateTime.utc(2026),
    );
    expect(e.copyWith(photoPath: 'p/1.jpg').photoPath, 'p/1.jpg');
  });
}
