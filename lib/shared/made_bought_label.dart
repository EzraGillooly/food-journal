import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';

/// The made-vs-bought icon + label, in muted ink. One source of truth for the
/// icon and wording, shared by the feed card and detail screen.
class MadeBoughtLabel extends ConsumerWidget {
  const MadeBoughtLabel({super.key, required this.isHomemade});

  final bool isHomemade;

  static IconData iconFor(bool isHomemade) =>
      isHomemade ? Icons.soup_kitchen : Icons.storefront;

  static String labelFor(bool isHomemade) =>
      isHomemade ? 'Made it' : 'Bought it';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(isHomemade), size: 15, color: theme.inkMuted),
        const SizedBox(width: 4),
        Text(labelFor(isHomemade), style: text.bodySmall),
      ],
    );
  }
}
