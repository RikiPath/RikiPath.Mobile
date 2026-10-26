enum ReviewRating { again, hard, good, easy }

extension ReviewRatingSubmission on ReviewRating {
  int get quality => switch (this) {
    ReviewRating.again => 1,
    ReviewRating.hard => 3,
    ReviewRating.good => 4,
    ReviewRating.easy => 5,
  };
}

/// Maps the backend's five numeric quality values to its persisted four-value
/// rating label. This is deliberately not an inverse UI-button mapping:
/// qualities 1 and 2 both persist as `Again` but change ease factor differently.
ReviewRating backendRatingLabelForQuality(int quality) {
  if (quality < 1 || quality > 5) {
    throw RangeError.range(quality, 1, 5, 'quality');
  }
  return switch (quality) {
    1 || 2 => ReviewRating.again,
    3 => ReviewRating.hard,
    4 => ReviewRating.good,
    5 => ReviewRating.easy,
    _ => throw StateError('Validated review quality was not mapped.'),
  };
}
