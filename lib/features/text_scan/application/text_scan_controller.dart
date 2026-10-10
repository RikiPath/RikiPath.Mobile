import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/text_scan/data/api_text_scan_repository.dart';
import 'package:rikipath_mobile/features/text_scan/data/gallery_text_scan_image_picker.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

final textScanRepositoryProvider = Provider<TextScanRepository>((ref) {
  return ApiTextScanRepository(ref.watch(apiClientProvider));
});

final textScanImagePickerProvider = Provider<TextScanImagePicker>((ref) {
  return GalleryTextScanImagePicker(ImagePicker());
});

final textScanControllerProvider =
    NotifierProvider.autoDispose<TextScanController, TextScanState>(
      TextScanController.new,
    );

class TextScanController extends Notifier<TextScanState> {
  @override
  TextScanState build() => const TextScanState();

  Future<void> pickImage() async {
    if (state.isBusy) return;
    state = state.copyWith(
      status: TextScanStatus.selecting,
      clearInputError: true,
    );
    try {
      final image = await ref
          .read(textScanImagePickerProvider)
          .pickFromGallery();
      if (!ref.mounted) return;
      if (image == null) {
        state = state.copyWith(
          status: state.image == null
              ? TextScanStatus.idle
              : TextScanStatus.ready,
        );
        return;
      }
      state = TextScanState(status: TextScanStatus.ready, image: image);
    } on UnsupportedTextScanImageException {
      state = const TextScanState(
        inputError: TextScanInputError.unsupportedType,
      );
    } on TextScanImageTooLargeException {
      state = const TextScanState(inputError: TextScanInputError.tooLarge);
    } catch (_) {
      if (!ref.mounted) return;
      state = const TextScanState(status: TextScanStatus.pickerError);
    }
  }

  Future<void> scan() async {
    if (state.isBusy || state.image == null) return;
    state = state.copyWith(
      status: TextScanStatus.scanning,
      clearInputError: true,
    );
    try {
      final result = await ref
          .read(textScanRepositoryProvider)
          .scan(state.image!);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: TextScanStatus.completed,
        recognizedText: result.text,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: error is NetworkError
            ? TextScanStatus.networkError
            : TextScanStatus.providerError,
      );
    }
  }

  void updateRecognizedText(String value) {
    if (state.status != TextScanStatus.completed) return;
    state = state.copyWith(recognizedText: value);
  }

  void clear() {
    if (state.isBusy) return;
    state = const TextScanState();
  }

  Future<void> retry() async {
    if (state.image == null) {
      await pickImage();
      return;
    }
    await scan();
  }
}
