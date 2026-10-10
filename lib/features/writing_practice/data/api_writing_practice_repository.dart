import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/writing_practice/data/writing_api_paths.dart';
import 'package:rikipath_mobile/features/writing_practice/data/writing_dtos.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice_repository.dart';

class ApiWritingPracticeRepository implements WritingPracticeRepository {
  const ApiWritingPracticeRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<WritingCharacter>> loadQueue(WritingQueueRequest request) async {
    final path = switch ((request.script, request.kanjiCollection)) {
      (WritingScript.hiragana || WritingScript.katakana, _) =>
        WritingApiPaths.kanaDue,
      (WritingScript.kanji, KanjiWritingCollection.due) =>
        WritingApiPaths.kanjiDue,
      (WritingScript.kanji, KanjiWritingCollection.all) =>
        WritingApiPaths.kanjiAll,
    };
    final response = await _apiClient.get<Object?>(
      path,
      queryParameters: <String, Object?>{
        'count': request.count,
        if (request.script != WritingScript.kanji)
          'type': _kanaType(request.script),
      },
    );

    try {
      final result = readWritingResultList(response.data);
      return switch (request.script) {
        WritingScript.hiragana || WritingScript.katakana =>
          result
              .map(KanaWritingQueueItemDto.fromJson)
              .where((dto) => dto.type == request.script)
              .map((dto) => dto.toDomain())
              .toList(growable: false),
        WritingScript.kanji =>
          result
              .map(KanjiWritingQueueItemDto.fromJson)
              .map((dto) => dto.toDomain())
              .toList(growable: false),
      };
    } on FormatException {
      throw const UnknownError(
        message: 'The Writing queue response is malformed.',
      );
    }
  }

  @override
  Future<List<KanjiWritingScore>> loadKanjiScores() async {
    final response = await _apiClient.get<Object?>(WritingApiPaths.kanjiScores);
    try {
      return readWritingResultList(response.data)
          .map(KanjiWritingScoreDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
    } on FormatException {
      throw const UnknownError(
        message: 'The Kanji Writing score response is malformed.',
      );
    }
  }

  @override
  Future<WritingSubmissionReceipt> submitKana({
    required WritingCharacter character,
    required WritingPracticeResult result,
  }) async {
    if (character.script == WritingScript.kanji) {
      throw ArgumentError.value(character.script, 'character.script');
    }
    final response = await _apiClient.post<Object?>(
      WritingApiPaths.kanaSubmit,
      data: <String, Object?>{
        'kanaCharacterId': character.id,
        'totalMistakes': result.totalMistakes,
      },
    );
    try {
      return KanaWritingSubmissionDto.fromJson(
        readWritingResultObject(response.data),
      ).toDomain();
    } on FormatException {
      throw const UnknownError(
        message: 'The Kana Writing submit response is malformed.',
      );
    }
  }

  @override
  Future<WritingSubmissionReceipt> submitKanji({
    required WritingCharacter character,
    required WritingPracticeResult result,
    required WritingPracticeMode mode,
  }) async {
    if (character.script != WritingScript.kanji) {
      throw ArgumentError.value(character.script, 'character.script');
    }
    final totalStrokeCount = character.strokeCount > 0
        ? character.strokeCount
        : result.totalStrokeCount;
    final response = await _apiClient.post<Object?>(
      WritingApiPaths.kanjiSubmit,
      data: <String, Object?>{
        'kanjiId': character.id,
        'totalMistakes': result.totalMistakes,
        'score': result.scoreFor(totalStrokeCount),
        'correctStrokeCount': (totalStrokeCount - result.totalMistakes)
            .clamp(0, totalStrokeCount)
            .toInt(),
        'totalStrokeCount': totalStrokeCount,
        'practiceMode': mode.name,
      },
    );
    try {
      return KanjiWritingSubmissionDto.fromJson(
        readWritingResultObject(response.data),
      ).toDomain(character.id);
    } on FormatException {
      throw const UnknownError(
        message: 'The Kanji Writing submit response is malformed.',
      );
    }
  }
}

String _kanaType(WritingScript script) => switch (script) {
  WritingScript.hiragana => 'Hiragana',
  WritingScript.katakana => 'Katakana',
  WritingScript.kanji => throw ArgumentError.value(script, 'script'),
};
