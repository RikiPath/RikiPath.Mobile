class EssayWritingResult {
  const EssayWritingResult({
    required this.submissionId,
    required this.grading,
    this.gradingNote,
  });

  final int submissionId;
  final EssayGrading? grading;
  final String? gradingNote;
}

class EssayGrading {
  const EssayGrading({
    required this.overallScore,
    required this.criteria,
    required this.strengths,
    required this.improvements,
    required this.corrections,
  });

  final double overallScore;
  final List<EssayCriterion> criteria;
  final List<String> strengths;
  final List<String> improvements;
  final List<EssayCorrection> corrections;
}

class EssayCriterion {
  const EssayCriterion({
    required this.name,
    required this.score,
    required this.comment,
  });

  final String name;
  final double score;
  final String comment;
}

class EssayCorrection {
  const EssayCorrection({
    required this.original,
    required this.suggestion,
    required this.reason,
  });

  final String original;
  final String suggestion;
  final String reason;
}

abstract interface class EssayWritingRepository {
  Future<EssayWritingResult> submit({
    required int certificateLevelId,
    required String textContent,
  });
}
