import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../data/entries_repository.dart';
import 'framed_image.dart';

/// Loads and displays an entry photo from its private storage path via a signed
/// URL. Shows a soft placeholder while loading or when there is no photo.
///
/// [focusX]/[focusY]/[zoom] frame the photo for the small card thumbnails; the
/// defaults reproduce a centered cover-crop, so cover/detail views (which pass
/// no framing) look unchanged.
class EntryPhoto extends ConsumerWidget {
  const EntryPhoto({
    super.key,
    required this.photoPath,
    this.focusX = 0,
    this.focusY = 0,
    this.zoom = 1,
  });

  final String? photoPath;
  final double focusX;
  final double focusY;
  final double zoom;

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
      data: (url) => FramedImage(
        provider: NetworkImage(url),
        focusX: focusX,
        focusY: focusY,
        zoom: zoom,
        background: theme.tagBg,
      ),
    );
  }
}
