import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';

/// Read-only star display of a 1-10 rating as 5 stars with half increments
/// (half star = 1 point). Used on cards and the entry detail.
class RatingStars extends ConsumerWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
  });

  final int rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final c = color ?? theme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            rating >= (i + 1) * 2
                ? Icons.star_rounded
                : rating >= i * 2 + 1
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: rating >= i * 2 + 1 ? c : c.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}
