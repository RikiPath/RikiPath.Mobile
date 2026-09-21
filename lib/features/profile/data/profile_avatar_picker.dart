import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

const int maxProfileAvatarBytes = 5 * 1024 * 1024;

final profileAvatarPickerProvider = Provider<ProfileAvatarPicker>((ref) {
  return ImagePickerProfileAvatarPicker(ImagePicker());
});

abstract interface class ProfileAvatarPicker {
  Future<ProfileAvatarUpload?> pickFromGallery();
}

class ImagePickerProfileAvatarPicker implements ProfileAvatarPicker {
  ImagePickerProfileAvatarPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<ProfileAvatarUpload?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    if (await file.length() > maxProfileAvatarBytes) {
      throw const AvatarTooLargeException();
    }

    return profileAvatarUploadFromBytes(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      reportedContentType: file.mimeType,
    );
  }
}

ProfileAvatarUpload profileAvatarUploadFromBytes({
  required Uint8List bytes,
  required String fileName,
  String? reportedContentType,
}) {
  if (bytes.length > maxProfileAvatarBytes) {
    throw const AvatarTooLargeException();
  }

  final contentType = _supportedContentType(
    fileName: fileName,
    reportedContentType: reportedContentType,
  );
  if (contentType == null) {
    throw const UnsupportedAvatarTypeException();
  }
  return ProfileAvatarUpload(
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
