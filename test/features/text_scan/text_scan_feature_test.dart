import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/text_scan/application/text_scan_controller.dart';
import 'package:rikipath_mobile/features/text_scan/data/api_text_scan_repository.dart';
import 'package:rikipath_mobile/features/text_scan/data/gallery_text_scan_image_picker.dart';
import 'package:rikipath_mobile/features/text_scan/data/text_scan_api_paths.dart';
import 'package:rikipath_mobile/features/text_scan/data/text_scan_dto.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

void main() {
  final image = TextScanImage(
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    fileName: 'writing.png',
    contentType: 'image/png',
  );

  group('Text Scan contract', () {
    test('maps the verified preview-only response', () {
      final dto = TextScanResultDto.fromEnvelope(_scanEnvelope());

      expect(dto.text, '今日は日本語を勉強します。');
      expect(dto.scannedAt, DateTime.utc(2026, 10, 9));
    });

    test('uses exact route and multipart Image key', () async {
      final client = _TextScanApiClient(_scanEnvelope());
      final repository = ApiTextScanRepository(client);

      await repository.scan(image);

      expect(client.lastPath, TextScanApiPaths.scan);
      final formData = client.lastData! as FormData;
      expect(formData.files.single.key, 'Image');
      expect(formData.files.single.value.filename, 'writing.png');
      expect(formData.files.single.value.contentType.toString(), 'image/png');
    });

    test('accepts only source-backed image formats', () {
      final upload = textScanImageFromBytes(
        bytes: Uint8List.fromList(<int>[1]),
        fileName: 'essay.webp',
      );
      expect(upload.contentType, 'image/webp');
      expect(
        () => textScanImageFromBytes(
          bytes: Uint8List.fromList(<int>[1]),
          fileName: 'essay.gif',
        ),
        throwsA(isA<UnsupportedTextScanImageException>()),
      );
    });

    test('enforces the verified 10 MB image limit', () {
      expect(
        () => textScanImageFromBytes(
          bytes: Uint8List(maxTextScanImageBytes + 1),
          fileName: 'essay.jpg',
        ),
        throwsA(isA<TextScanImageTooLargeException>()),
      );
    });
  });

  group('Text Scan controller', () {
    test('selects an image then publishes OCR text', () async {
      final repository = _TextScanRepository(
        const TextScanResult(text: '桜の季節が好きです。'),
      );
      final container = _container(
        repository: repository,
        picker: _TextScanPicker(image),
      );
      final controller = container.read(textScanControllerProvider.notifier);

      await controller.pickImage();
      expect(
        container.read(textScanControllerProvider).status,
        TextScanStatus.ready,
      );
      await controller.scan();

      final state = container.read(textScanControllerProvider);
      expect(state.status, TextScanStatus.completed);
      expect(state.recognizedText, '桜の季節が好きです。');
    });

    test('reports a safe state when the gallery cannot open', () async {
      final container = _container(
        repository: _TextScanRepository(const TextScanResult(text: '')),
        picker: const _ThrowingTextScanPicker(),
      );

      await container.read(textScanControllerProvider.notifier).pickImage();

      expect(
        container.read(textScanControllerProvider).status,
        TextScanStatus.pickerError,
      );
    });

    test('preserves selected image after provider failure for retry', () async {
      final container = _container(
        repository: _TextScanRepository(
          const TextScanResult(text: ''),
          error: const ServerError(statusCode: 500),
        ),
        picker: _TextScanPicker(image),
      );
      final controller = container.read(textScanControllerProvider.notifier);
      await controller.pickImage();
      await controller.scan();

      final state = container.read(textScanControllerProvider);
      expect(state.status, TextScanStatus.providerError);
      expect(state.image, same(image));
    });

    test('prevents duplicate scan submissions', () async {
      final repository = _DeferredTextScanRepository();
      final container = _container(
        repository: repository,
        picker: _TextScanPicker(image),
      );
      final controller = container.read(textScanControllerProvider.notifier);
      await controller.pickImage();

      final first = controller.scan();
      final second = controller.scan();
      repository.complete(const TextScanResult(text: '日本語'));
      await Future.wait(<Future<void>>[first, second]);

      expect(repository.calls, 1);
    });

    test('keeps edited OCR text in session state only', () async {
      final container = _container(
        repository: _TextScanRepository(const TextScanResult(text: '日本語')),
        picker: _TextScanPicker(image),
      );
      final controller = container.read(textScanControllerProvider.notifier);
      await controller.pickImage();
      await controller.scan();
      controller.updateRecognizedText('日本語を勉強します。');

      expect(
        container.read(textScanControllerProvider).recognizedText,
        '日本語を勉強します。',
      );
    });
  });
}

ProviderContainer _container({
  required TextScanRepository repository,
  required TextScanImagePicker picker,
}) {
  final container = ProviderContainer(
    overrides: [
      textScanRepositoryProvider.overrideWithValue(repository),
      textScanImagePickerProvider.overrideWithValue(picker),
    ],
  );
  final subscription = container.listen(
    textScanControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  addTearDown(container.dispose);
  return container;
}

Map<String, Object?> _scanEnvelope() => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': <String, Object?>{
    'text': '今日は日本語を勉強します。',
    'scannedAt': '2026-10-09T00:00:00Z',
  },
};

class _TextScanApiClient extends ApiClient {
  _TextScanApiClient(this.body) : super(Dio(), const ApiErrorMapper());

  final Object? body;
  String? lastPath;
  Object? lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: body as T,
    );
  }
}

class _TextScanRepository implements TextScanRepository {
  _TextScanRepository(this.result, {this.error});

  final TextScanResult result;
  final Object? error;

  @override
  Future<TextScanResult> scan(TextScanImage image) async {
    if (error != null) throw error!;
    return result;
  }
}

class _DeferredTextScanRepository implements TextScanRepository {
  final Completer<TextScanResult> _completer = Completer<TextScanResult>();
  int calls = 0;

  void complete(TextScanResult result) => _completer.complete(result);

  @override
  Future<TextScanResult> scan(TextScanImage image) {
    calls++;
    return _completer.future;
  }
}

class _TextScanPicker implements TextScanImagePicker {
  const _TextScanPicker(this.image);

  final TextScanImage? image;

  @override
  Future<TextScanImage?> pickFromGallery() async => image;
}

class _ThrowingTextScanPicker implements TextScanImagePicker {
  const _ThrowingTextScanPicker();

  @override
  Future<TextScanImage?> pickFromGallery() {
    throw StateError('Gallery unavailable');
  }
}
