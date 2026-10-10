import 'package:flutter/foundation.dart';

const int maxTextScanImageBytes = 10 * 1024 * 1024;

enum TextScanStatus {
  idle,
  selecting,
  ready,
  scanning,
  completed,
  pickerError,
  networkError,
  providerError,
}

@immutable
class TextScanImage {
  const TextScanImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

@immutable
class TextScanResult {
  const TextScanResult({required this.text, this.scannedAt});

  final String text;
  final DateTime? scannedAt;
}

@immutable
class TextScanState {
  const TextScanState({
    this.status = TextScanStatus.idle,
    this.image,
    this.recognizedText = '',
    this.inputError,
  });

  final TextScanStatus status;
  final TextScanImage? image;
  final String recognizedText;
  final TextScanInputError? inputError;

  bool get isBusy =>
      status == TextScanStatus.selecting || status == TextScanStatus.scanning;

  TextScanState copyWith({
    TextScanStatus? status,
    TextScanImage? image,
    bool clearImage = false,
    String? recognizedText,
    TextScanInputError? inputError,
    bool clearInputError = false,
  }) {
    return TextScanState(
      status: status ?? this.status,
      image: clearImage ? null : image ?? this.image,
      recognizedText: recognizedText ?? this.recognizedText,
      inputError: clearInputError ? null : inputError ?? this.inputError,
    );
  }
}

enum TextScanInputError { unsupportedType, tooLarge }

class UnsupportedTextScanImageException implements Exception {
  const UnsupportedTextScanImageException();
}

class TextScanImageTooLargeException implements Exception {
  const TextScanImageTooLargeException();
}

abstract interface class TextScanImagePicker {
  Future<TextScanImage?> pickFromGallery();
}

abstract interface class TextScanRepository {
  Future<TextScanResult> scan(TextScanImage image);
}
