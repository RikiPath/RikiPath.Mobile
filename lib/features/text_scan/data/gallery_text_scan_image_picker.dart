import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

class GalleryTextScanImagePicker implements TextScanImagePicker {
  GalleryTextScanImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<TextScanImage?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    if (await file.length() > maxTextScanImageBytes) {
      throw const TextScanImageTooLargeException();
    }
    return textScanImageFromBytes(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      reportedContentType: file.mimeType,
    );
  }
}

TextScanImage textScanImageFromBytes({
  required Uint8List bytes,
  required String fileName,
  String? reportedContentType,
}) {
  if (bytes.length > maxTextScanImageBytes) {
    throw const TextScanImageTooLargeException();
  }
  final contentType = _supportedContentType(
    fileName: fileName,
    reportedContentType: reportedContentType,
  );
  if (contentType == null) {
    throw const UnsupportedTextScanImageException();
  }
  return TextScanImage(
    bytes: bytes,
    fileName: fileName,
    contentType: contentType,
  );
}

String? _supportedContentType({
  required String fileName,
  required String? reportedContentType,
}) {
  final reported = reportedContentType?.toLowerCase();
  if (reported == 'image/jpeg' ||
      reported == 'image/png' ||
      reported == 'image/webp') {
    return reported;
  }

  final name = fileName.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  return null;
}
