import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_label.dart';
import '../../../shared/rating_badge.dart';
import '../application/entries_controller.dart';
import '../application/feed_filter.dart';
import '../data/food_entry.dart';
import 'widgets/entry_photo.dart';
import 'widgets/feed_filter_bar.dart';

/// The journal (Direction A: timeline spine). Entries grouped by day on a dated
/// rail, newest first. Body-only; the shell provides nav + the add button.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesControllerProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        title: "Couldn't load your journal",
        action: 'Retry',
        onAction: () => ref.read(entriesControllerProvider.notifier).refresh(),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _Message(
            title: 'Your journal is empty',
            body: 'Tap “Add entry” to log your first bite.',
          );
        }
        final filter = ref.watch(feedFilterProvider);
        final filtered = entries.where(filter.matches).toList(growable: false);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(entriesControllerProvider.notifier).refresh(),
          child: ContentColumn(
            maxWidth: 680,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: FeedFilterBar()),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoMatches(
                      onClear: () =>
                          ref.read(feedFilterProvider.notifier).clear(),
                    ),
                  )
                else
                  _Timeline(groups: _groupByDay(filtered)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.groups});
  final List<_DayGroup> groups;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: groups.length,
      itemBuilder: (context, i) => _DaySection(group: groups[i], first: i == 0),
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.group, required this.first});
  final _DayGroup group;
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Padding(
      padding: EdgeInsets.only(top: first ? 20 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              group.label,
              style: TextStyle(
                fontFamily: theme.headingFont,
                fontSize: 20,
                color: theme.inkMuted,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 5),
            padding: const EdgeInsets.only(left: 22),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.inkMuted.withValues(alpha: 0.22),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                for (final e in group.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TimelineTile(entry: e),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends ConsumerWidget {
  const _TimelineTile({required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/entry/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 60,
                  child: EntryPhoto(photoPath: entry.photoPath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: theme.headingFont,
                              fontSize: 16,
                              color: theme.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RatingBadge(rating: entry.rating),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        CategoryTag(category: entry.category),
                        const SizedBox(width: 8),
                        Flexible(
                          child: MadeBoughtLabel(isHomemade: entry.isHomemade),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatEntryTime(entry.eatenAt),
                          style: TextStyle(
                            fontFamily: theme.bodyFont,
                            fontSize: 11.5,
                            color: theme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.label, this.entries);
  final String label;
  final List<FoodEntry> entries;
}

List<_DayGroup> _groupByDay(List<FoodEntry> entries) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final groups = <String, List<FoodEntry>>{};
  final order = <String>[];
  for (final e in entries) {
    final local = e.eatenAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
        ? 'Yesterday'
        : '${day.year}-${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}';
    if (!groups.containsKey(label)) {
      groups[label] = [];
      order.add(label);
    }
    groups[label]!.add(e);
  }
  return [for (final l in order) _DayGroup(l, groups[l]!)];
}

class _NoMatches extends ConsumerWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40, color: theme.inkMuted),
          const SizedBox(height: 12),
          Text('No entries match', style: text.titleMedium),
          const SizedBox(height: 6),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _Message extends ConsumerWidget {
  const _Message({required this.title, this.body, this.action, this.onAction});
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 44, color: theme.primary),
            const SizedBox(height: 16),
            Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, style: text.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
