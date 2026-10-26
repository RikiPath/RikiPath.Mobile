import 'package:rikipath_mobile/features/practice/data/daily_review_dtos.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';

abstract final class DailyReviewMapper {
  static DailyReviewQueue queue(DailyReviewQueueDto dto) {
    if (dto.totalDue < 0 || dto.totalDue != dto.items.length) {
      throw const FormatException('Invalid daily review queue totals.');
    }
    return DailyReviewQueue(
      totalDue: dto.totalDue,
      items: dto.items.map(card).toList(growable: false),
    );
  }

  static DailyReviewCard card(DailyReviewCardDto dto) {
    final type = switch (dto.contentType.trim().toLowerCase()) {
      'vocabulary' => DailyReviewContentType.vocabulary,
      'kanji' => DailyReviewContentType.kanji,
      'grammar' => DailyReviewContentType.grammar,
      _ => null,
    };
    if (dto.reviewCardId <= 0 ||
        type == null ||
        dto.term.trim().isEmpty ||
        dto.meaning.trim().isEmpty ||
        dto.repetitions < 0) {
      throw const FormatException('Invalid daily review card.');
    }
    return DailyReviewCard(
      reviewCardId: dto.reviewCardId,
      contentType: type,
      term: dto.term,
      reading: dto.reading,
      meaning: dto.meaning,
      note: dto.note,
      repetitions: dto.repetitions,
      nextReviewDate: dto.nextReviewDate,
    );
  }

  static DailyReviewSubmitResult submit(DailyReviewSubmitResultDto dto) {
    if (dto.reviewCardId <= 0 ||
        dto.qualitySubmitted < 1 ||
        dto.qualitySubmitted > 5 ||
        dto.newEaseFactor < 1.3 ||
        dto.newIntervalDays < 1 ||
        dto.repetitions < 0) {
      throw const FormatException('Invalid daily review submit result.');
    }
    return DailyReviewSubmitResult(
      reviewCardId: dto.reviewCardId,
      qualitySubmitted: dto.qualitySubmitted,
      shouldRepeatInSession: dto.shouldRepeatInSession,
      newEaseFactor: dto.newEaseFactor,
      newIntervalDays: dto.newIntervalDays,
      repetitions: dto.repetitions,
      nextReviewDate: dto.nextReviewDate,
    );
  }
}
