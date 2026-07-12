import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/category_tag.dart';
import '../../../shared/made_bought_label.dart';
import '../../../shared/rating_stars.dart';
import '../application/entries_controller.dart';
import '../data/dish.dart';
import '../data/food_entry.dart';
import 'entry_form_dialog.dart';
import 'widgets/entry_photo.dart';

/// Opens the entry detail as a centered popup (used from the cards).
Future<void> showEntryDetail(BuildContext context, String entryId) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _EntryDetailDialog(entryId: entryId),
    ),
  );
}

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
                  onPressed: () => showEntryForm(context, existing: entry),
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

class _Detail extends StatefulWidget {
  const _Detail({required this.entry, required this.theme, required this.text});

  final FoodEntry entry;
  final AppTheme theme;
  final TextTheme text;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  int _dish = 0;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = widget.theme;
    final text = widget.text;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    if (_dish >= entry.dishes.length) _dish = 0;
    final dish = entry.dishes[_dish];
    final multi = entry.dishes.length > 1;

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
                  const SizedBox(height: 12),
                  // Dish tabs when there is more than one dish.
                  if (multi) ...[
                    _DishTabs(
                      theme: theme,
                      dishes: entry.dishes,
                      active: _dish,
                      onSelect: (i) => setState(() => _dish = i),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          dish.name,
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
                        child: RatingStars(rating: dish.rating, size: 22),
                      ),
                    ],
                  ),
                  if (dish.notes != null && dish.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      dish.notes!,
                      style: TextStyle(
                        fontFamily: theme.bodyFont,
                        fontSize: 16.5,
                        height: 1.55,
                        color: theme.ink,
                      ),
                    ),
                  ],
                  if (dish.recipe != null && dish.recipe!.isNotEmpty)
                    _pullBlock(theme, 'Ingredients & recipe', dish.recipe!),
                  const SizedBox(height: 24),
                  Divider(color: theme.inkMuted.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CategoryTag(category: entry.category),
                      const SizedBox(width: 10),
                      MadeBoughtLabel(isHomemade: entry.isHomemade),
                    ],
                  ),
                  if (entry.location != null && entry.location!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _row(theme, text, Icons.place_outlined, entry.location!),
                  ],
                  const SizedBox(height: 8),
                  _row(
                    theme,
                    text,
                    Icons.schedule,
                    formatEntryDateTime(entry.eatenAt),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(AppTheme theme, TextTheme text, IconData icon, String value) {
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

  Widget _pullBlock(AppTheme theme, String title, String body) {
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
    final entry = widget.entry;
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

/// Tab selector for switching between an entry's dishes on the detail view.
class _DishTabs extends StatelessWidget {
  const _DishTabs({
    required this.theme,
    required this.dishes,
    required this.active,
    required this.onSelect,
  });

  final AppTheme theme;
  final List<Dish> dishes;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < dishes.length; i++)
          InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: i == active ? theme.primary : theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: i == active
                      ? theme.primary
                      : theme.inkMuted.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                dishes[i].name,
                style: TextStyle(
                  fontFamily: theme.bodyFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: i == active ? theme.onPrimary : theme.ink,
                ),
              ),
            ),
          ),
      ],
    );
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

/// The entry detail rendered as popup content: a compact header (edit / delete /
/// close) over the same detail body used by the full-screen route.
class _EntryDetailDialog extends ConsumerWidget {
  const _EntryDetailDialog({required this.entryId});

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

    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 640, maxHeight: size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.inkMuted.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry?.name ?? 'Entry',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: theme.headingFont,
                      fontSize: 20,
                      color: theme.ink,
                    ),
                  ),
                ),
                if (entry != null) ...[
                  IconButton(
                    tooltip: 'Edit',
                    icon: Icon(Icons.edit_outlined, color: theme.inkMuted),
                    onPressed: () => showEntryForm(context, existing: entry),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: theme.inkMuted),
                    onPressed: () => _confirmDelete(context, ref, entry),
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.close, color: theme.inkMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: entriesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : entry == null
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Entry not found'),
                  )
                : _Detail(entry: entry, theme: theme, text: text),
          ),
        ],
      ),
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
    if (context.mounted) Navigator.of(context).pop();
  }
}
