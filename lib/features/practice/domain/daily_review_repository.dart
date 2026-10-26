import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';

abstract interface class DailyReviewRepository {
  Future<DailyReviewQueue> loadDailyQueue();

  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  });
}
