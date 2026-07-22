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
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: _Detail(entry: entry, theme: theme, text: text),
                ),
              ),
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
    if (context.mounted) context.go('/');
  }
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.entry,
    required this.theme,
    required this.text,
    this.actions,
  });

  final FoodEntry entry;
  final AppTheme theme;
  final TextTheme text;

  /// Optional action buttons rendered inline with the title (popup only).
  final List<Widget>? actions;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  int _dish = 0;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = widget.theme;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (_dish >= entry.dishes.length) _dish = 0;
    final dish = entry.dishes[_dish];
    final multi = entry.dishes.length > 1;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: wide ? 3 / 4 : 4 / 3,
        child: EntryPhoto(photoPath: entry.photoPath),
      ),
    );

    final date = Text(
      formatEntryDate(entry.eatenAt),
      style: TextStyle(
        fontFamily: theme.bodyFont,
        fontSize: 12.5,
        color: theme.inkMuted,
      ),
    );
    final stars = RatingStars(rating: dish.rating, size: 18);
    final category = CategoryTag(category: entry.category);
    final kcal = dish.calories == null
        ? null
        : Text(
            '${dish.calories} kcal',
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 12.5,
              color: theme.inkMuted,
            ),
          );
    final madeBought = MadeBoughtLabel(isHomemade: entry.isHomemade);

    // date · rating · category · [kcal] .......... made / bought.
    // On wide screens made/bought is pushed to the far right; on phones the
    // whole line wraps so nothing overflows.
    final meta = wide
        ? Row(
            children: [
              date,
              const SizedBox(width: 10),
              stars,
              const SizedBox(width: 10),
              category,
              if (kcal != null) ...[const SizedBox(width: 10), kcal],
              const Spacer(),
              const SizedBox(width: 8),
              madeBought,
            ],
          )
        : Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [date, stars, category, ?kcal, madeBought],
          );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        meta,
        if (dish.notes != null && dish.notes!.isNotEmpty)
          _section(theme, 'Notes', dish.notes!),
        if (dish.recipe != null && dish.recipe!.isNotEmpty)
          _section(theme, 'Ingredients', dish.recipe!),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multi) ...[
            Center(
              child: _DishTabs(
                theme: theme,
                dishes: entry.dishes,
                active: _dish,
                onSelect: (i) => setState(() => _dish = i),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Dish title, centered, with the actions inline on the right.
          _titleHeader(theme, dish.name, wide),
          const SizedBox(height: 22),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: image),
                const SizedBox(width: 28),
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: info,
                  ),
                ),
              ],
            )
          else ...[
            image,
            const SizedBox(height: 22),
            info,
          ],
          if (entry.location != null && entry.location!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 15, color: theme.inkMuted),
                  const SizedBox(width: 6),
                  Text(
                    entry.location!,
                    style: TextStyle(
                      fontFamily: theme.bodyFont,
                      fontSize: 13,
                      color: theme.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Title on the left with the popup's actions (edit / delete / close) inline
  /// on the right, on both phone and desktop.
  Widget _titleHeader(AppTheme theme, String title, bool wide) {
    final titleText = Text(
      title,
      style: TextStyle(
        fontFamily: theme.headingFont,
        fontSize: wide ? 34 : 28,
        height: 1.1,
        color: theme.ink,
      ),
    );
    final actions = widget.actions;
    if (actions == null || actions.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: titleText);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleText),
        const SizedBox(width: 8),
        Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
    );
  }

  Widget _section(AppTheme theme, String label, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: theme.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: theme.bodyFont,
              fontSize: 15,
              height: 1.55,
              color: theme.ink,
            ),
          ),
        ],
      ),
    );
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
      // Wide enough to keep the meta row on one line; only as tall as needed.
      constraints: BoxConstraints(maxWidth: 840, maxHeight: size.height * 0.92),
      child: SingleChildScrollView(
        child: entriesAsync.isLoading
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            : entry == null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.close, color: theme.inkMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Entry not found'),
                    ),
                  ],
                ),
              )
            : _Detail(
                entry: entry,
                theme: theme,
                text: text,
                actions: [
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
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: theme.inkMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
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
