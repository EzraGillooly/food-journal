import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';

/// The "N/10" rating pill, filled with the theme primary. Shared by the feed
/// card and the entry detail screen.
class RatingBadge extends ConsumerWidget {
  const RatingBadge({super.key, required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$rating/10',
        style: TextStyle(
          fontFamily: theme.bodyFont,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: theme.onPrimary,
        ),
      ),
    );
  }
}
