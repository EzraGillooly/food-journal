import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';

/// A two-option segmented toggle: "I made it" vs "I bought it".
///
/// [isHomemade] true = made, false = bought. Maps to `is_homemade` in the DB.
class MadeBoughtToggle extends ConsumerWidget {
  const MadeBoughtToggle({
    super.key,
    required this.isHomemade,
    required this.onChanged,
  });

  final bool isHomemade;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.inkMuted.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _segment(
            theme,
            'Made it',
            Icons.soup_kitchen,
            isHomemade,
            () => onChanged(true),
          ),
          _segment(
            theme,
            'Bought it',
            Icons.storefront,
            !isHomemade,
            () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    AppTheme theme,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? theme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? theme.onPrimary : theme.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: theme.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? theme.onPrimary : theme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
