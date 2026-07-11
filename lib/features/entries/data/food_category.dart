import 'package:flutter/material.dart';

/// The meal categories a journal entry can belong to.
///
/// [wire] is the exact string stored in Postgres (must match the
/// `category` check constraint in migration 0001).
enum FoodCategory {
  breakfast('breakfast', 'Breakfast', Icons.wb_twilight),
  lunch('lunch', 'Lunch', Icons.lunch_dining),
  dinner('dinner', 'Dinner', Icons.dinner_dining),
  snack('snack', 'Snack', Icons.cookie),
  drink('drink', 'Drink', Icons.local_cafe);

  const FoodCategory(this.wire, this.label, this.icon);

  final String wire;
  final String label;
  final IconData icon;

  static FoodCategory fromWire(String value) =>
      FoodCategory.values.firstWhere((c) => c.wire == value);
}
