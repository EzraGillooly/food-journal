import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_toggle.dart';
import '../../../shared/rating_control.dart';
import '../data/food_category.dart';

/// Temporary landing screen used until the feed (F3) lands. Doubles as a design
/// preview so the theme, fonts, and shared widgets can be eyeballed together.
class HomePlaceholderScreen extends ConsumerStatefulWidget {
  const HomePlaceholderScreen({super.key});

  @override
  ConsumerState<HomePlaceholderScreen> createState() =>
      _HomePlaceholderScreenState();
}

class _HomePlaceholderScreenState extends ConsumerState<HomePlaceholderScreen> {
  int? _rating = 8;
  bool _homemade = true;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Journal'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 44,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A little diary of what you eat',
                        style: text.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Design foundation ready - ${theme.label}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Categories', style: text.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in FoodCategory.values)
                      CategoryTag(category: c),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Rating', style: text.titleLarge),
                const SizedBox(height: 10),
                RatingControl(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 24),
                Text('Made or bought', style: text.titleLarge),
                const SizedBox(height: 10),
                MadeBoughtToggle(
                  isHomemade: _homemade,
                  onChanged: (v) => setState(() => _homemade = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/new'),
                  child: const Text('Add entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
