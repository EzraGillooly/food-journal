import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../data/entries_repository.dart';

/// Loads and displays an entry photo from its private storage path via a signed
/// URL. Shows a soft placeholder while loading or when there is no photo.
class EntryPhoto extends ConsumerWidget {
  const EntryPhoto({super.key, required this.photoPath, this.fit});

  final String? photoPath;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    if (photoPath == null) {
      return Container(
        color: theme.tagBg,
        alignment: Alignment.center,
        child: Icon(Icons.restaurant, color: theme.tagInk, size: 28),
      );
    }

    final urlAsync = ref.watch(photoUrlProvider(photoPath!));
    return urlAsync.when(
      loading: () => Container(color: theme.tagBg),
      error: (err, stack) => Container(
        color: theme.tagBg,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: theme.tagInk),
      ),
      data: (url) => Image.network(
        url,
        fit: fit ?? BoxFit.cover,
        semanticLabel: 'Food photo',
        errorBuilder: (context, err, stack) => Container(color: theme.tagBg),
      ),
    );
  }
}

/// Signed URL for a stored photo path, cached per path for the session.
final photoUrlProvider = FutureProvider.family<String, String>((
  ref,
  path,
) async {
  return ref.watch(entriesRepositoryProvider).photoUrl(path);
});
