import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';

/// Opens the crop UI on a picked photo, defaulting to the entry card's 16:10
/// frame. The ratio is locked so the crop always matches how the card renders,
/// while the user manually positions and sizes the crop box. Returns the
/// cropped JPEG bytes, or null if the user cancels.
Future<Uint8List?> cropPhotoToCard(
  BuildContext context,
  String sourcePath,
) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 10),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 88,
    uiSettings: [
      WebUiSettings(context: context),
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        lockAspectRatio: true,
        hideBottomControls: false,
      ),
      IOSUiSettings(title: 'Crop photo', aspectRatioLockEnabled: true),
    ],
  );
  if (cropped == null) return null;
  return cropped.readAsBytes();
}
