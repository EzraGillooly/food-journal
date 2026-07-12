import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../shared/category_tag.dart';
import '../../../../shared/made_bought_label.dart';
import '../../../../shared/rating_badge.dart';
import '../../data/food_entry.dart';
import 'entry_photo.dart';

/// A single entry in the feed: photo hero, name, category, made/bought, rating.
class EntryCard extends ConsumerWidget {
  const EntryCard({super.key, required this.entry, this.onTap});

  final FoodEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      RatingBadge(rating: entry.rating),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CategoryTag(category: entry.category),
                      const SizedBox(width: 8),
                      MadeBoughtLabel(isHomemade: entry.isHomemade),
                      const Spacer(),
                      Text(
                        formatEntryTime(entry.eatenAt),
                        style: text.bodySmall,
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
