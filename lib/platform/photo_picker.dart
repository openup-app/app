import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PhotoPicker {
  Future<Uint8List?> pickPhoto(bool useCamera) async {
    final a = ImagePicker();
    final image = await a.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery);
    return image?.readAsBytes();
  }
}
