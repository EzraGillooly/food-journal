import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
import 'router.dart';

class FoodJournalApp extends ConsumerWidget {
  const FoodJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Food Journal',
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      routerConfig: router,
      // Hide the always-on web scrollbar for a cleaner, app-like look;
      // scrolling by wheel/trackpad/touch still works.
      scrollBehavior: _NoScrollbarBehavior(),
    );
  }
}

/// Removes the scrollbar overlay that the web/desktop scroll behavior adds.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
