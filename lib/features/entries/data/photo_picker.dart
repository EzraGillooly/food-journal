import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a food photo and downsizes it. Uses image_picker's built-in resize +
/// quality, which runs on web (canvas) and mobile alike. Returns the picked
/// file (the caller crops it before upload).
class PhotoPicker {
  PhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxEdge = 2000.0;
  static const _quality = 85;

  Future<XFile?> pick(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
    );
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => PhotoPicker());
