import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_essay_writing_repository.dart';

void main() {
  test(
    'submits real writing content and level to Backend without a fake score',
    () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: <String, Object?>{
                  'isSuccess': true,
                  'result': <String, Object?>{
                    'submissionId': 991,
                    'type': 'Writing',
                    'grading': null,
                    'gradingNote': 'Bài đã lưu, hiện chưa thể chấm.',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await ApiEssayWritingRepository(
        ApiClient(dio, const ApiErrorMapper()),
      ).submit(certificateLevelId: 84, textContent: ' 日本語を勉強します。 ');

      expect(captured.path, '/api/PracticeSubmission/submit');
      expect(captured.method, 'POST');
      expect(captured.data, <String, Object?>{
        'type': 'Writing',
        'textContent': '日本語を勉強します。',
        'certificateLevelId': 84,
      });
      expect(result.submissionId, 991);
      expect(result.grading, isNull);
      expect(result.gradingNote, 'Bài đã lưu, hiện chưa thể chấm.');
    },
  );

  test('maps actual Backend feedback and corrections', () {
    final result = parseEssayWritingResult(<String, Object?>{
      'result': <String, Object?>{
        'submissionId': 992,
        'grading': <String, Object?>{
          'overallScore': 82,
          'criteria': <Object?>[
            <String, Object?>{
              'name': 'Ngữ pháp',
              'score': 8,
              'comment': 'Dùng đúng mẫu câu.',
            },
          ],
          'strengths': <Object?>['Ý rõ ràng'],
          'improvements': <Object?>['Thêm liên từ'],
          'corrections': <Object?>[
            <String, Object?>{
              'original': '本を読むた',
              'suggestion': '本を読んだ',
              'reason': 'Sai dạng quá khứ',
            },
          ],
        },
      },
    });

    expect(result.grading?.overallScore, 82);
    expect(result.grading?.criteria.single.name, 'Ngữ pháp');
    expect(result.grading?.corrections.single.suggestion, '本を読んだ');
  });
}
