import 'package:flutter/material.dart';

import '../core/theme/theme_provider.dart';
import '../features/entries/data/food_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A small pill showing a meal category with its icon, in theme tag colours.
class CategoryTag extends ConsumerWidget {
  const CategoryTag({super.key, required this.category});

  final FoodCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.tagBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: theme.tagInk),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.tagInk,
            ),
          ),
        ],
      ),
    );
  }
}
