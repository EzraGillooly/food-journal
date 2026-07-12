import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';

/// Opens the crop UI on a picked photo. The crop is free-form so tall phone
/// photos can stay portrait (the cards fit any shape); the user manually
/// positions and sizes the crop box, and can pick a preset ratio. Returns the
/// cropped JPEG bytes, or null if the user cancels.
Future<Uint8List?> cropPhotoToCard(
  BuildContext context,
  String sourcePath,
) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 88,
    uiSettings: [
      WebUiSettings(context: context),
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        lockAspectRatio: false,
        hideBottomControls: false,
      ),
      IOSUiSettings(title: 'Crop photo'),
    ],
  );
  if (cropped == null) return null;
  return cropped.readAsBytes();
}
