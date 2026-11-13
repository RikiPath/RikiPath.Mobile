import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

class ApiEssayWritingRepository implements EssayWritingRepository {
  const ApiEssayWritingRepository(this._client);

  final ApiClient _client;

  @override
  Future<EssayWritingResult> submit({
    required int certificateLevelId,
    required String textContent,
  }) async {
    final response = await _client.post<Object?>(
      '/api/PracticeSubmission/submit',
      data: <String, Object?>{
        'type': 'Writing',
        'textContent': textContent.trim(),
        'certificateLevelId': certificateLevelId,
      },
    );
    return parseEssayWritingResult(response.data);
  }
}

EssayWritingResult parseEssayWritingResult(Object? body) {
  final envelope = _object(body);
  final data = _object(envelope['data'] ?? envelope['result']);
  final id = data['submissionId'];
  if (id is! int || id <= 0) {
    throw const FormatException('Invalid essay submission ID.');
  }
  final rawGrading = data['grading'];
  EssayGrading? grading;
  if (rawGrading != null) {
    final value = _object(rawGrading);
    final score = value['overallScore'];
    if (score is! num) throw const FormatException('Invalid essay score.');
    grading = EssayGrading(
      overallScore: score.toDouble(),
      criteria: _list(value['criteria'])
          .map((item) {
            final criterion = _object(item);
            return EssayCriterion(
              name: _string(criterion['name']),
              score: (criterion['score'] as num).toDouble(),
              comment: _string(criterion['comment']),
            );
          })
          .toList(growable: false),
      strengths: _list(value['strengths']).map(_string).toList(growable: false),
      improvements: _list(
        value['improvements'],
      ).map(_string).toList(growable: false),
      corrections: _list(value['corrections'])
          .map((item) {
            final correction = _object(item);
            return EssayCorrection(
              original: _string(correction['original']),
              suggestion: _string(correction['suggestion']),
              reason: _string(correction['reason']),
            );
          })
          .toList(growable: false),
    );
  }
  return EssayWritingResult(
    submissionId: id,
    grading: grading,
    gradingNote: data['gradingNote'] is String
        ? data['gradingNote'] as String
        : null,
  );
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected JSON object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> _list(Object? value) {
  if (value is! List) throw const FormatException('Expected JSON list.');
  return value;
}

String _string(Object? value) {
  if (value is! String) throw const FormatException('Expected JSON string.');
  return value;
}
