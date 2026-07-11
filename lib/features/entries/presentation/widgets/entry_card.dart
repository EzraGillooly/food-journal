import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/category_tag.dart';
import '../../data/food_entry.dart';
import 'entry_photo.dart';

/// A single entry in the feed: photo hero, name, category, made/bought, rating.
class EntryCard extends ConsumerWidget {
  const EntryCard({super.key, required this.entry, this.onTap});

  final FoodEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: EntryPhoto(photoPath: entry.photoPath),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: text.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RatingBadge(rating: entry.rating),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CategoryTag(category: entry.category),
                      const SizedBox(width: 8),
                      Icon(
                        entry.isHomemade
                            ? Icons.soup_kitchen
                            : Icons.storefront,
                        size: 15,
                        color: theme.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.isHomemade ? 'Made it' : 'Bought it',
                        style: text.bodySmall,
                      ),
                      const Spacer(),
                      Text(_time(entry.eatenAt), style: text.bodySmall),
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

  String _time(DateTime d) {
    final local = d.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _RatingBadge extends ConsumerWidget {
  const _RatingBadge({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$rating/10',
        style: TextStyle(
          fontFamily: theme.bodyFont,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}
