import 'food_category.dart';

/// A single food-journal entry. Mirrors the `food_entries` table (migration
/// 0001). [id]/[userId]/[createdAt] are assigned by Postgres on insert, so they
/// are nullable on a not-yet-saved draft.
class FoodEntry {
  const FoodEntry({
    this.id,
    this.userId,
    required this.name,
    required this.rating,
    required this.category,
    required this.isHomemade,
    this.notes,
    this.recipe,
    this.location,
    this.photoPath,
    required this.eatenAt,
    this.createdAt,
  });

  final String? id;
  final String? userId;
  final String name;
  final int rating;
  final FoodCategory category;
  final bool isHomemade;
  final String? notes;
  final String? recipe;
  final String? location;
  final String? photoPath;
  final DateTime eatenAt;
  final DateTime? createdAt;

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      rating: (map['rating'] as num).toInt(),
      category: FoodCategory.fromWire(map['category'] as String),
      isHomemade: map['is_homemade'] as bool,
      notes: map['notes'] as String?,
      recipe: map['recipe'] as String?,
      location: map['location'] as String?,
      photoPath: map['photo_path'] as String?,
      eatenAt: DateTime.parse(map['eaten_at'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }

  /// Columns to write on insert/update. Omits DB-managed fields (id, user_id,
  /// created_at, updated_at); `user_id` defaults to auth.uid() in Postgres.
  Map<String, dynamic> toInsert() {
    return {
      'name': name,
      'rating': rating,
      'category': category.wire,
      'is_homemade': isHomemade,
      'notes': _emptyToNull(notes),
      'recipe': _emptyToNull(recipe),
      'location': _emptyToNull(location),
      'photo_path': photoPath,
      'eaten_at': eatenAt.toUtc().toIso8601String(),
    };
  }

  FoodEntry copyWith({String? photoPath}) {
    return FoodEntry(
      id: id,
      userId: userId,
      name: name,
      rating: rating,
      category: category,
      isHomemade: isHomemade,
      notes: notes,
      recipe: recipe,
      location: location,
      photoPath: photoPath ?? this.photoPath,
      eatenAt: eatenAt,
      createdAt: createdAt,
    );
  }

  static String? _emptyToNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
