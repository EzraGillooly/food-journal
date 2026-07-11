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
    );
  }
}
