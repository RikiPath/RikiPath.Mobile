import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';

enum DailyReviewContentType { vocabulary, kanji, grammar }

class DailyReviewCard {
  const DailyReviewCard({
    required this.reviewCardId,
    required this.contentType,
    required this.term,
    required this.reading,
    required this.meaning,
    required this.note,
    required this.repetitions,
    required this.nextReviewDate,
  });

  final int reviewCardId;
  final DailyReviewContentType contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final int repetitions;
  final DateTime nextReviewDate;
}

class DailyReviewQueue {
  const DailyReviewQueue({required this.totalDue, required this.items});

  final int totalDue;
  final List<DailyReviewCard> items;
}

class DailyReviewSubmitResult {
  const DailyReviewSubmitResult({
    required this.reviewCardId,
    required this.qualitySubmitted,
    required this.shouldRepeatInSession,
    required this.newEaseFactor,
    required this.newIntervalDays,
    required this.repetitions,
    required this.nextReviewDate,
  });

  final int reviewCardId;
  final int qualitySubmitted;
  final bool shouldRepeatInSession;
  final double newEaseFactor;
  final int newIntervalDays;
  final int repetitions;
  final DateTime nextReviewDate;
}

class DailyReviewResponse {
  const DailyReviewResponse({required this.reviewCardId, required this.rating});

  final int reviewCardId;
  final ReviewRating rating;
}
