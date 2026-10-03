import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';

void main() {
  test('maps quality to the persisted label without choosing a UI value', () {
    expect(backendRatingLabelForQuality(1), ReviewRating.again);
    expect(backendRatingLabelForQuality(2), ReviewRating.again);
    expect(backendRatingLabelForQuality(3), ReviewRating.hard);
    expect(backendRatingLabelForQuality(4), ReviewRating.good);
    expect(backendRatingLabelForQuality(5), ReviewRating.easy);
  });

  test('does not fabricate quality values outside the backend range', () {
    expect(() => backendRatingLabelForQuality(0), throwsRangeError);
    expect(() => backendRatingLabelForQuality(6), throwsRangeError);
  });
}
