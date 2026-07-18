import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';
import 'app_shell.dart';

/// A softly pulsing placeholder block used to compose loading skeletons.
class Skeleton extends ConsumerStatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.expand = false,
  });

  final double? width;
  final double height;
  final double radius;

  /// Fill the available width (for use inside an Expanded/stretch context).
  final bool expand;

  @override
  ConsumerState<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends ConsumerState<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.expand ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(theme.tagBg, theme.surface, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A placeholder shaped like the horizontal entry card, so the list doesn't
/// jump when real data arrives.
class SkeletonEntryCard extends ConsumerWidget {
  const SkeletonEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 116, child: Skeleton(radius: 0, expand: true)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Skeleton(width: 150, height: 16),
                    SizedBox(height: 12),
                    Skeleton(width: 90, height: 13),
                    SizedBox(height: 14),
                    Skeleton(width: 120, height: 22, radius: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short column of skeleton cards for a loading feed.
class SkeletonFeed extends StatelessWidget {
  const SkeletonFeed({super.key, this.count = 4, this.maxWidth = 760});

  final int count;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ContentColumn(
      maxWidth: maxWidth,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [for (var i = 0; i < count; i++) const SkeletonEntryCard()],
      ),
    );
  }
}
