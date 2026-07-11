import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Picks and downsizes a food photo. Uses image_picker's built-in resize +
/// quality, which runs on web (canvas) and mobile alike, so we avoid a separate
/// native compression plugin.
class PhotoPicker {
  PhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxEdge = 1600.0;
  static const _quality = 80;

  Future<Uint8List?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => PhotoPicker());
