/// One dish within an entry. A single photo can hold several dishes, each with
/// its own name, rating, notes, and recipe.
class Dish {
  const Dish({
    required this.name,
    required this.rating,
    this.calories,
    this.notes,
    this.recipe,
  });

  final String name;
  final int rating; // 1-10 (5 stars, half-star increments)
  final int? calories;
  final String? notes;
  final String? recipe;

  factory Dish.fromMap(Map<String, dynamic> m) => Dish(
    name: m['name'] as String,
    rating: (m['rating'] as num).toInt(),
    calories: (m['calories'] as num?)?.toInt(),
    notes: m['notes'] as String?,
    recipe: m['recipe'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'rating': rating,
    if (calories != null) 'calories': calories,
    if (clean(notes) != null) 'notes': clean(notes),
    if (clean(recipe) != null) 'recipe': clean(recipe),
  };

  Dish copyWith({
    String? name,
    int? rating,
    int? calories,
    String? notes,
    String? recipe,
  }) => Dish(
    name: name ?? this.name,
    rating: rating ?? this.rating,
    calories: calories ?? this.calories,
    notes: notes ?? this.notes,
    recipe: recipe ?? this.recipe,
  );

  static String? clean(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
