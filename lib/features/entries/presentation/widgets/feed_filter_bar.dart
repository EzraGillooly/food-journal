import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/selectable_chip.dart';
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

    // Keep the text field in sync when the query is changed elsewhere (e.g. the
    // "Clear filters" button), so the box never shows a stale search term.
    ref.listen(feedFilterProvider.select((f) => f.query), (_, query) {
      if (_search.text != query) _search.text = query;
    });

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
              SelectableChip(
                label: 'All',
                selected: filter.category == null,
                onTap: () => ctrl.setCategory(null),
              ),
              for (final c in FoodCategory.values) ...[
                const SizedBox(width: 8),
                SelectableChip(
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
              SelectableChip(
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
