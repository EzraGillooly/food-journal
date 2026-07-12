import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';

/// A 5-star rating with half-star increments. The value is still stored on the
/// 1-10 scale the database uses: each half-star is 1 point, a full star is 2,
/// so 5 stars = 10/10 and 4.5 stars = 9/10.
///
/// [value] is null until the user picks a rating. Each star splits into a left
/// (half) and right (full) tap zone.
class RatingControl extends ConsumerWidget {
  const RatingControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < 5; i++) _star(theme, i)],
    );
  }

  Widget _star(AppTheme theme, int index) {
    final full = (index + 1) * 2; // value for a full star
    final half = index * 2 + 1; // value for a half star
    final v = value ?? 0;

    final IconData icon;
    if (v >= full) {
      icon = Icons.star_rounded;
    } else if (v >= half) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_outline_rounded;
    }
    final filled = v >= half;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: 40,
              color: filled
                  ? theme.primary
                  : theme.inkMuted.withValues(alpha: 0.45),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: ValueKey('rate-$half'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(half),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: ValueKey('rate-$full'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(full),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
