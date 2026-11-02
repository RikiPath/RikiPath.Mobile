import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';

class _CaptureUploadClient extends ApiClient {
  _CaptureUploadClient() : super(Dio(), const ApiErrorMapper());

  String? path;
  FormData? payload;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    this.path = path;
    payload = data as FormData;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data:
          <String, Object?>{
                'result': <String, Object?>{
                  'mentorId': 42,
                  'email': 'qa@rikipath.local',
                  'hasVerificationDocument': true,
                },
              }
              as T,
    );
  }
}

void main() {
  test(
    'private certificate upload sends matching MIME in multipart request',
    () async {
      final client = _CaptureUploadClient();
      final result = await ApiMentorRepository(client)
          .uploadVerificationDocument(
            bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
            fileName: 'certificate.pdf',
          );

      expect(client.path, MentorApiPaths.verificationDocument);
      expect(client.payload!.files.single.key, 'file');
      expect(
        client.payload!.files.single.value.contentType.toString(),
        'application/pdf',
      );
      expect(result.hasVerificationDocument, isTrue);
    },
  );

  test('unsupported certificate extension never reaches API', () async {
    final client = _CaptureUploadClient();
    await expectLater(
      ApiMentorRepository(client).uploadVerificationDocument(
        bytes: Uint8List.fromList([0x00]),
        fileName: 'unsafe.txt',
      ),
      throwsArgumentError,
    );
    expect(client.path, isNull);
  });
}
