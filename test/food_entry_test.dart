import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/entries/data/food_category.dart';
import 'package:food_journal/features/entries/data/food_entry.dart';

void main() {
  test('fromMap parses a DB row', () {
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
    expect(e.category, FoodCategory.dinner);
    expect(e.isHomemade, isTrue);
    expect(e.photoPath, 'u1/abc.jpg');
  });

  test(
    'toInsert blanks empty optional strings to null and omits db fields',
    () {
      final e = FoodEntry(
        name: 'Toast',
        rating: 6,
        category: FoodCategory.breakfast,
        isHomemade: true,
        notes: '   ',
        recipe: '',
        location: 'Kitchen',
        eatenAt: DateTime.utc(2026, 7, 11, 8),
      );
      final map = e.toInsert();
      expect(map['notes'], isNull);
      expect(map['recipe'], isNull);
      expect(map['location'], 'Kitchen');
      expect(map['category'], 'breakfast');
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('user_id'), isFalse);
    },
  );

  test('copyWith sets photoPath', () {
    final e = FoodEntry(
      name: 'X',
      rating: 5,
      category: FoodCategory.snack,
      isHomemade: false,
      eatenAt: DateTime.utc(2026),
    );
    expect(e.copyWith(photoPath: 'p/1.jpg').photoPath, 'p/1.jpg');
  });
}
