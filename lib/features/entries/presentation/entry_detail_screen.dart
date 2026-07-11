import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/category_tag.dart';
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: EntryPhoto(photoPath: entry.photoPath),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(entry.name, style: text.displaySmall),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.rating}/10',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: theme.bodyFont,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CategoryTag(category: entry.category),
                      const SizedBox(width: 8),
                      Icon(
                        entry.isHomemade
                            ? Icons.soup_kitchen
                            : Icons.storefront,
                        size: 16,
                        color: theme.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.isHomemade ? 'Made it' : 'Bought it',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _row(context, Icons.schedule, _formatDateTime(entry.eatenAt)),
                  if (entry.location != null && entry.location!.isNotEmpty)
                    _row(context, Icons.place_outlined, entry.location!),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    _section(text, 'Notes', entry.notes!),
                  if (entry.recipe != null && entry.recipe!.isNotEmpty)
                    _section(text, 'Ingredients / recipe', entry.recipe!),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.inkMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }

  Widget _section(TextTheme text, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: 6),
          Text(body, style: text.bodyLarge),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final local = d.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}  $h:$m $ampm';
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
