import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_api_paths.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_dtos.dart';
import 'package:rikipath_mobile/features/practice/data/daily_review_mapper.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';

class ApiDailyReviewRepository implements DailyReviewRepository {
  const ApiDailyReviewRepository(this._client);

  final ApiClient _client;

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    final response = await _client.get<Object?>(DailyReviewApiPaths.queue);
    try {
      return DailyReviewMapper.queue(readDailyReviewQueue(response.data));
    } on FormatException {
      throw const UnknownError(
        message: 'The daily review queue did not match the API contract.',
      );
    }
  }

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) async {
    if (reviewCardId <= 0) {
      throw ArgumentError.value(reviewCardId, 'reviewCardId');
    }
    if (quality < 1 || quality > 5) {
      throw RangeError.range(quality, 1, 5, 'quality');
    }
    final response = await _client.post<Object?>(
      DailyReviewApiPaths.submit,
      data: <String, Object?>{'reviewCardId': reviewCardId, 'quality': quality},
    );
    try {
      return DailyReviewMapper.submit(
        readDailyReviewSubmitResult(response.data),
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The daily review result did not match the API contract.',
      );
    }
  }
}
