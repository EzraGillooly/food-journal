import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/selectable_chip.dart';
import '../../application/feed_filter.dart';
import '../../data/food_category.dart';

/// Search field plus a Filters button that opens the category / made-bought
/// filters in a popup, so the journal header stays tidy.
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

  int _activeCount(FeedFilter f) =>
      (f.category != null ? 1 : 0) + (f.source != MadeBoughtFilter.any ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final ctrl = ref.read(feedFilterProvider.notifier);

    // Keep the search field in sync when the filter is cleared elsewhere.
    if (_search.text != filter.query) {
      _search.value = _search.value.copyWith(
        text: filter.query,
        selection: TextSelection.collapsed(offset: filter.query.length),
      );
    }

    final active = _activeCount(filter);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: ctrl.setQuery,
            decoration: InputDecoration(
              hintText: 'Search name, notes, place',
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
        ),
        const SizedBox(width: 10),
        _FilterButton(
          theme: theme,
          activeCount: active,
          onTap: () => _openFilters(theme),
        ),
      ],
    );
  }

  Future<void> _openFilters(AppTheme theme) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const _FiltersPopup(),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.theme,
    required this.activeCount,
    required this.onTap,
  });
  final AppTheme theme;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = activeCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? theme.primary : theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? theme.primary : theme.inkMuted.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: on ? theme.onPrimary : theme.inkMuted,
            ),
            const SizedBox(width: 8),
            Text(
              on ? 'Filters ($activeCount)' : 'Filters',
              style: TextStyle(
                fontFamily: theme.bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: on ? theme.onPrimary : theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPopup extends ConsumerWidget {
  const _FiltersPopup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final filter = ref.watch(feedFilterProvider);
    final ctrl = ref.read(feedFilterProvider.notifier);

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
          fontFamily: theme.bodyFont,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: theme.inkMuted,
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: theme.headingFont,
                      fontSize: 20,
                      color: theme.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: ctrl.clear,
                    child: const Text('Clear all'),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.inkMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label('Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SelectableChip(
                        label: 'All',
                        selected: filter.category == null,
                        onTap: () => ctrl.setCategory(null),
                      ),
                      for (final c in FoodCategory.values)
                        SelectableChip(
                          label: c.label,
                          icon: c.icon,
                          selected: filter.category == c,
                          onTap: () => ctrl.toggleCategory(c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  label('Made or bought'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in MadeBoughtFilter.values)
                        SelectableChip(
                          label: switch (s) {
                            MadeBoughtFilter.any => 'Any',
                            MadeBoughtFilter.made => 'Made',
                            MadeBoughtFilter.bought => 'Bought',
                          },
                          selected: filter.source == s,
                          onTap: () => ctrl.setSource(s),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
