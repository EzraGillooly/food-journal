import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_label.dart';
import '../../../shared/rating_badge.dart';
import '../application/entries_controller.dart';
import '../data/food_entry.dart';
import 'widgets/entry_photo.dart';

/// Full-screen view of one entry (F4). Deep-linkable at /entry/:id. Because the
/// entry comes from the user's own RLS-scoped list, a non-owner simply won't
/// find it and sees the not-found state.
class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;
    final entriesAsync = ref.watch(entriesControllerProvider);

    final entry = entriesAsync.value
        ?.where((e) => e.id == entryId)
        .cast<FoodEntry?>()
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(entry?.name ?? 'Entry'),
        actions: entry == null
            ? null
            : [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.go('/entry/${entry.id}/edit'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, entry),
                ),
              ],
      ),
      body: entriesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : entriesAsync.hasError
          ? _LoadError(
              onRetry: () =>
                  ref.read(entriesControllerProvider.notifier).refresh(),
            )
          : entry == null
          ? _NotFound()
          : _Detail(entry: entry, theme: theme, text: text),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FoodEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('“${entry.name}” will be removed for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(entriesControllerProvider.notifier).remove(entry);
    if (context.mounted) context.go('/');
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.entry, required this.theme, required this.text});

  final FoodEntry entry;
  final AppTheme theme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Full-bleed hero.
        SizedBox(
          height: wide ? 360 : 240,
          width: double.infinity,
          child: EntryPhoto(photoPath: entry.photoPath),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eyebrow().toUpperCase(),
                    style: TextStyle(
                      fontFamily: theme.bodyFont,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: TextStyle(
                            fontFamily: theme.headingFont,
                            fontSize: wide ? 38 : 30,
                            height: 1.05,
                            color: theme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: RatingBadge(rating: entry.rating),
                      ),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      entry.notes!,
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 16.5,
                        height: 1.55,
                        color: theme.ink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CategoryTag(category: entry.category),
                      const SizedBox(width: 10),
                      MadeBoughtLabel(isHomemade: entry.isHomemade),
                    ],
                  ),
                  if (entry.location != null && entry.location!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _row(Icons.place_outlined, entry.location!),
                  ],
                  const SizedBox(height: 8),
                  _row(Icons.schedule, formatEntryDateTime(entry.eatenAt)),
                  if (entry.recipe != null && entry.recipe!.isNotEmpty)
                    _pullBlock('Ingredients & recipe', entry.recipe!),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.inkMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }

  Widget _pullBlock(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(left: BorderSide(color: theme.secondary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 14.5,
              height: 1.5,
              color: theme.ink,
            ),
          ),
        ],
      ),
    );
  }

  String _eyebrow() {
    final made = entry.isHomemade ? 'made' : 'bought';
    final local = entry.eatenAt.toLocal();
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final d1 = DateTime(local.year, local.month, local.day);
    final diff = d0.difference(d1).inDays;
    final when = diff == 0
        ? 'today'
        : diff == 1
        ? 'yesterday'
        : '$diff days ago';
    return '${entry.category.label} · $made · $when';
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Entry not found', style: text.titleMedium),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to journal'),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load this entry", style: text.titleMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
