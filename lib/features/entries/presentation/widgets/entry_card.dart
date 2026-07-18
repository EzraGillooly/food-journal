import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/category_tag.dart';
import '../../../../shared/made_bought_label.dart';
import '../../../../shared/rating_stars.dart';
import '../../data/food_entry.dart';
import 'entry_photo.dart';

/// A single entry as a horizontal card: a portrait photo on the left (phone
/// photos are usually tall) and the dish info on the right.
class EntryCard extends ConsumerWidget {
  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.photoOverride,
  });

  final FoodEntry entry;
  final VoidCallback? onTap;

  /// When set, shows this instead of loading the stored photo (used by the
  /// live card preview in the entry form).
  final Widget? photoOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final extraDishes = entry.dishes.length - 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 116,
                child: photoOverride ?? EntryPhoto(photoPath: entry.photoPath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(
                          fontFamily: theme.headingFont,
                          fontSize: 18,
                          height: 1.1,
                          color: theme.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      RatingStars(rating: entry.rating, size: 17),
                      if (extraDishes > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          extraDishes == 1
                              ? '+1 more dish'
                              : '+$extraDishes more dishes',
                          style: TextStyle(
                            fontFamily: theme.bodyFont,
                            fontSize: 11.5,
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Scale the tag + made/bought down to fit rather than
                      // overflow when the card is narrow (e.g. the live preview
                      // in the entry form). Keeps a single line so the fixed
                      // card height is never exceeded.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            CategoryTag(category: entry.category),
                            const SizedBox(width: 8),
                            MadeBoughtLabel(isHomemade: entry.isHomemade),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
