import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../application/feed_filter.dart';
import '../../data/food_category.dart';

/// Search field + category and made/bought filters shown above the feed.
class FeedFilterBar extends ConsumerStatefulWidget {
  const FeedFilterBar({super.key});

  @override
  ConsumerState<FeedFilterBar> createState() => _FeedFilterBarState();
}

class _FeedFilterBarState extends ConsumerState<FeedFilterBar> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final ctrl = ref.read(feedFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: ctrl.setQuery,
          decoration: InputDecoration(
            hintText: 'Search by name',
            prefixIcon: Icon(Icons.search, color: theme.inkMuted),
            suffixIcon: filter.query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: theme.inkMuted),
                    onPressed: () {
                      _search.clear();
                      ctrl.setQuery('');
                    },
                  ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                theme: theme,
                label: 'All',
                selected: filter.category == null,
                onTap: () => ctrl.setCategory(null),
              ),
              for (final c in FoodCategory.values) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  theme: theme,
                  label: c.label,
                  icon: c.icon,
                  selected: filter.category == c,
                  onTap: () => ctrl.toggleCategory(c),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final s in MadeBoughtFilter.values) ...[
              _FilterChip(
                theme: theme,
                label: _sourceLabel(s),
                selected: filter.source == s,
                onTap: () => ctrl.setSource(s),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  String _sourceLabel(MadeBoughtFilter s) => switch (s) {
    MadeBoughtFilter.any => 'Any',
    MadeBoughtFilter.made => 'Made',
    MadeBoughtFilter.bought => 'Bought',
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final AppTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.primary
                : theme.inkMuted.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : theme.inkMuted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
