import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';

abstract interface class WritingPracticeRepository {
  Future<List<WritingCharacter>> loadQueue(WritingQueueRequest request);

  Future<List<KanjiWritingScore>> loadKanjiScores();

  Future<WritingSubmissionReceipt> submitKana({
    required WritingCharacter character,
    required WritingPracticeResult result,
  });

  Future<WritingSubmissionReceipt> submitKanji({
    required WritingCharacter character,
    required WritingPracticeResult result,
    required WritingPracticeMode mode,
  });
}
