import 'package:flutter/widgets.dart';

/// Draws [provider] inside its box with an adjustable crop: [focusX]/[focusY]
/// pick which part of the photo stays visible (each in [-1, 1], 0 = centered)
/// and [zoom] scales relative to a "cover" fill (1 = cover, <1 reveals more of
/// the photo, >1 crops in). Defaults (0, 0, 1) reproduce a plain centered
/// cover-crop, so entries without custom framing look unchanged.
///
/// Needs the image's intrinsic size to place it precisely, so it resolves the
/// provider and falls back to a plain cover fit until that's known.
class FramedImage extends StatefulWidget {
  const FramedImage({
    super.key,
    required this.provider,
    this.focusX = 0,
    this.focusY = 0,
    this.zoom = 1,
    this.background,
  });

  final ImageProvider provider;
  final double focusX;
  final double focusY;
  final double zoom;
  final Color? background;

  @override
  State<FramedImage> createState() => _FramedImageState();
}

class _FramedImageState extends State<FramedImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _intrinsic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(FramedImage old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) {
      _intrinsic = null;
      _resolve();
    }
  }

  void _resolve() {
    final stream = widget.provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _detach();
    _stream = stream;
    _listener = ImageStreamListener((info, _) {
      final size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      if (mounted && size != _intrinsic) setState(() => _intrinsic = size);
    });
    _stream!.addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.background ?? const Color(0x00000000);
    final img = _intrinsic;
    if (img == null || img.width == 0 || img.height == 0) {
      // Intrinsic size unknown yet: plain cover keeps the space filled.
      return Container(
        color: bg,
        child: Image(
          image: widget.provider,
          fit: BoxFit.cover,
          alignment: Alignment(widget.focusX, widget.focusY),
        ),
      );
    }
    return ColoredBox(
      color: bg,
      child: LayoutBuilder(
        builder: (context, c) {
          if (!c.maxWidth.isFinite || !c.maxHeight.isFinite) {
            return Image(
              image: widget.provider,
              fit: BoxFit.cover,
              alignment: Alignment(widget.focusX, widget.focusY),
            );
          }
          final coverScale = (c.maxWidth / img.width) > (c.maxHeight / img.height)
              ? c.maxWidth / img.width
              : c.maxHeight / img.height;
          final scale = coverScale * widget.zoom;
          final dispW = img.width * scale;
          final dispH = img.height * scale;
          return ClipRect(
            child: OverflowBox(
              minWidth: dispW,
              maxWidth: dispW,
              minHeight: dispH,
              maxHeight: dispH,
              alignment: Alignment(widget.focusX, widget.focusY),
              child: Image(
                image: widget.provider,
                width: dispW,
                height: dispH,
                fit: BoxFit.fill,
              ),
            ),
          );
        },
      ),
    );
  }
}
