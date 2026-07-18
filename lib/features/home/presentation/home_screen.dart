import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/rating_stars.dart';
import '../../../shared/skeleton.dart';
import '../../entries/application/entries_controller.dart';
import '../../entries/application/journal_stats.dart';
import '../../entries/data/food_entry.dart';
import '../../entries/presentation/entry_detail_screen.dart';
import '../../entries/presentation/widgets/entry_card.dart';
import '../../entries/presentation/widgets/entry_photo.dart';

/// Editorial home (Direction B): a featured "cover" entry, then a recent grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesControllerProvider);

    return entriesAsync.when(
      loading: () => const SkeletonFeed(maxWidth: kContentMaxWidth),
      error: (e, _) => const _HomeMessage(
        title: "Couldn't load your journal",
        body: 'Check your connection and try again.',
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _HomeMessage(
            title: 'Welcome to your food journal',
            body: 'Tap “Add entry” to log your first bite.',
          );
        }
        final stats = JournalStats(entries);
        final featured = stats.featured!;
        final lately = stats.lately(limit: 6);
        return ContentColumn(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= kWideBreakpoint;
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Cover(entry: featured, wide: wide),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 0 : 16,
                        28,
                        wide ? 0 : 16,
                        14,
                      ),
                      child: _SectionHeader(
                        label: 'Lately',
                        onSeeAll: () => context.go('/journal'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 16),
                      child: _LatelyGrid(entries: lately),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({required this.entry, required this.wide});

  final FoodEntry entry;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 20 : 16),
        child: GestureDetector(
          onTap: () => showEntryDetail(context, entry.id!),
          child: SizedBox(
            height: wide ? 340 : 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EntryPhoto(photoPath: entry.photoPath),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                      stops: const [0.35, 0.7, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(wide ? 28 : 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Highest rated lately',
                            style: TextStyle(
                              fontFamily: theme.bodyFont,
                              fontSize: 11.5,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RatingStars(
                            rating: entry.rating,
                            size: 15,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: theme.headingFont,
                          fontSize: wide ? 40 : 30,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: theme.bodyFont,
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.onSeeAll});
  final String label;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Label(label),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _Label extends ConsumerWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: theme.bodyFont,
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
        color: theme.inkMuted,
      ),
    );
  }
}

class _LatelyGrid extends StatelessWidget {
  const _LatelyGrid({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    // Size cards from the actual available width so the two columns fill it
    // exactly (flush with the cover above) instead of leaving a right gap.
    return LayoutBuilder(
      builder: (context, c) {
        // Horizontal cards are wide, so at most two across.
        final cols = c.maxWidth >= 720 ? 2 : 1;
        // Subtract a hair so sub-pixel rounding can't push a card to a new row.
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols - 0.5;
        return Wrap(
          spacing: gap,
          runSpacing: 4,
          children: [
            for (final e in entries)
              SizedBox(
                width: cols == 1 ? double.infinity : cardW,
                child: EntryCard(
                  entry: e,
                  onTap: () => showEntryDetail(context, e.id!),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeMessage extends ConsumerWidget {
  const _HomeMessage({required this.title, required this.body});
  final String title;
  final String body;

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
            const SizedBox(height: 8),
            Text(body, style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
