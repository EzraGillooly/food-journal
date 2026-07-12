import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../application/entries_controller.dart';
import '../application/feed_filter.dart';
import '../data/food_entry.dart';
import 'widgets/entry_card.dart';
import 'widgets/feed_filter_bar.dart';

/// The journal feed (F3): the current user's entries, newest first, grouped by
/// day. RLS guarantees only their own entries are returned.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final entriesAsync = ref.watch(entriesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Journal'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.read(entriesControllerProvider.notifier).refresh(),
        ),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          final filter = ref.watch(feedFilterProvider);
          final filtered = entries
              .where(filter.matches)
              .toList(growable: false);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: FeedFilterBar(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(entriesControllerProvider.notifier)
                          .refresh(),
                      child: filtered.isEmpty
                          ? const _NoMatchesState()
                          : _DayGroupedList(entries: filtered),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayGroupedList extends ConsumerWidget {
  const _DayGroupedList({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    final groups = _groupByDay(entries);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 8 : 20, bottom: 12),
              child: Text(
                group.label,
                style: text.titleLarge?.copyWith(color: theme.inkMuted),
              ),
            ),
            for (final entry in group.entries)
              EntryCard(
                entry: entry,
                onTap: () => context.go('/entry/${entry.id}'),
              ),
          ],
        );
      },
    );
  }
}

class _NoMatchesState extends ConsumerWidget {
  const _NoMatchesState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 40, color: theme.inkMuted),
              const SizedBox(height: 12),
              Text('No entries match', style: text.titleMedium),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => ref.read(feedFilterProvider.notifier).clear(),
                child: const Text('Clear filters'),
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

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
            Text(
              'Your journal is empty',
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap “Add entry” to log your first bite.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load your journal", style: text.titleMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
