enum AnalyticsSection { streak, completion, skills }

class LearnerAnalytics {
  const LearnerAnalytics({
    required this.streakDays,
    required this.completedLessons,
    required this.totalLessons,
    required this.skills,
    this.unavailableSections = const <AnalyticsSection>{},
  });

  final int streakDays;
  final int completedLessons;
  final int totalLessons;
  final List<SkillBreakdown> skills;
  final Set<AnalyticsSection> unavailableSections;

  bool isAvailable(AnalyticsSection section) =>
      !unavailableSections.contains(section);

  bool get isEmpty =>
      streakDays == 0 &&
      completedLessons == 0 &&
      totalLessons == 0 &&
      skills.isEmpty;
}

class SkillBreakdown {
  const SkillBreakdown({
    required this.skill,
    required this.averageScore,
    required this.attemptCount,
  });

  final String skill;
  final double averageScore;
  final int attemptCount;

  double get progress => (averageScore / 100).clamp(0, 1);
}
