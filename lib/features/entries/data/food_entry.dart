import 'dish.dart';
import 'food_category.dart';

/// A single food-journal entry. Mirrors the `food_entries` table (migrations
/// 0001 + 0003). [id]/[userId]/[createdAt] are assigned by Postgres on insert,
/// so they are nullable on a not-yet-saved draft.
///
/// An entry holds one or more [dishes] (one photo, possibly several dishes).
/// The legacy `name`/`rating`/`notes`/`recipe` columns mirror the primary dish
/// so the feed's sort, search, and older rows keep working.
class FoodEntry {
  const FoodEntry({
    this.id,
    this.userId,
    required this.dishes,
    required this.category,
    required this.isHomemade,
    this.location,
    this.photoPath,
    required this.eatenAt,
    this.createdAt,
  }) : assert(dishes.length > 0, 'an entry needs at least one dish');

  final String? id;
  final String? userId;
  final List<Dish> dishes;
  final FoodCategory category;
  final bool isHomemade;
  final String? location;
  final String? photoPath;
  final DateTime eatenAt;
  final DateTime? createdAt;

  Dish get primary => dishes.first;
  String get name => primary.name;
  int get rating => primary.rating;
  String? get notes => primary.notes;
  String? get recipe => primary.recipe;

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    final raw = map['dishes'];
    final List<Dish> dishes;
    if (raw is List && raw.isNotEmpty) {
      dishes = raw
          .map((d) => Dish.fromMap((d as Map).cast<String, dynamic>()))
          .toList();
    } else {
      // Legacy row without a dishes array: synthesize one from the columns.
      dishes = [
        Dish(
          name: map['name'] as String,
          rating: (map['rating'] as num).toInt(),
          notes: map['notes'] as String?,
          recipe: map['recipe'] as String?,
        ),
      ];
    }
    return FoodEntry(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      dishes: dishes,
      category: FoodCategory.fromWire(map['category'] as String),
      isHomemade: map['is_homemade'] as bool,
      location: map['location'] as String?,
      photoPath: map['photo_path'] as String?,
      eatenAt: DateTime.parse(map['eaten_at'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }

  /// Columns to write on insert/update. Omits DB-managed fields (id, user_id,
  /// created_at, updated_at). The legacy name/rating/notes/recipe columns are
  /// kept in sync with the primary dish.
  Map<String, dynamic> toInsert() {
    return {
      'name': primary.name,
      'rating': primary.rating,
      'notes': Dish.clean(primary.notes),
      'recipe': Dish.clean(primary.recipe),
      'dishes': dishes.map((d) => d.toMap()).toList(),
      'category': category.wire,
      'is_homemade': isHomemade,
      'location': Dish.clean(location),
      'photo_path': photoPath,
      'eaten_at': eatenAt.toUtc().toIso8601String(),
    };
  }

  FoodEntry copyWith({String? photoPath}) {
    return FoodEntry(
      id: id,
      userId: userId,
      dishes: dishes,
      category: category,
      isHomemade: isHomemade,
      location: location,
      photoPath: photoPath ?? this.photoPath,
      eatenAt: eatenAt,
      createdAt: createdAt,
    );
  }
}
