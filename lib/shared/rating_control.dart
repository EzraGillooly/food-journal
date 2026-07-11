import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';

/// A 1-10 rating selector. Renders ten tappable chips; the selected value and
/// everything below it fill with the primary colour.
///
/// [value] is null when nothing is chosen yet. Each chip is a 44x44 touch
/// target for accessibility.
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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(10, (i) {
        final n = i + 1;
        final selected = value != null && n <= value!;
        return Semantics(
          button: true,
          selected: value == n,
          label: 'Rate $n out of 10',
          child: InkWell(
            onTap: () => onChanged(n),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? theme.primary : theme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: value == n
                      ? theme.ink
                      : theme.inkMuted.withValues(alpha: 0.4),
                  width: value == n ? 2 : 1,
                ),
              ),
              child: Text(
                '$n',
                style: TextStyle(
                  fontFamily: theme.bodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : theme.inkMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
