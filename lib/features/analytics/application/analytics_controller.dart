import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/analytics/data/analytics_api_paths.dart';
import 'package:rikipath_mobile/features/analytics/data/api_analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => ApiAnalyticsRepository(ref.watch(apiClientProvider)),
);

final learnerAnalyticsControllerProvider =
    AsyncNotifierProvider<LearnerAnalyticsController, LearnerAnalytics>(
      LearnerAnalyticsController.new,
      retry: (_, _) => null,
    );

class LearnerAnalyticsController extends AsyncNotifier<LearnerAnalytics> {
  @override
  Future<LearnerAnalytics> build() {
    ref.watch(authenticatedUserIdProvider);
    return ref.watch(analyticsRepositoryProvider).loadLearnerAnalytics();
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearnerAnalytics>();
    state = await AsyncValue.guard(build);
  }
}

@immutable
class SkillMonthlyPoint {
  const SkillMonthlyPoint({
    required this.month,
    required this.scorePercent,
    required this.attemptCount,
  });

  final String month;
  final double? scorePercent;
  final int attemptCount;
}

@immutable
class SkillMonthlyItem {
  const SkillMonthlyItem({
    required this.languageSkillName,
    required this.currentAssessment,
    this.currentScorePercent,
    this.changeFromPreviousMonth,
    this.comparedMonth,
    this.totalAttempts = 0,
    this.monthlyScores = const [],
  });

  final String languageSkillName;
  final String currentAssessment;
  final double? currentScorePercent;
  final double? changeFromPreviousMonth;
  final String? comparedMonth;
  final int totalAttempts;
  final List<SkillMonthlyPoint> monthlyScores;
}

@immutable
class SkillMonthlySummary {
  const SkillMonthlySummary({
    this.assessedJlptLevel,
    this.targetJlptLevel,
    this.totalAttempts = 0,
    this.currentOverallScorePercent,
    this.summary = '',
    this.skills = const [],
  });

  final String? assessedJlptLevel;
  final String? targetJlptLevel;
  final int totalAttempts;
  final double? currentOverallScorePercent;
  final String summary;
  final List<SkillMonthlyItem> skills;
}

@immutable
class MockHistoryEntry {
  const MockHistoryEntry({
    required this.attemptId,
    required this.title,
    required this.jlptLevelName,
    required this.totalScore,
    this.submittedAt,
  });

  final int attemptId;
  final String title;
  final String jlptLevelName;
  final double totalScore;
  final DateTime? submittedAt;
}

@immutable
class PracticeHistoryEntry {
  const PracticeHistoryEntry({
    required this.id,
    required this.type,
    required this.levelCode,
    required this.isGraded,
    this.overallScore,
    this.submittedAt,
  });

  final int id;
  final String type;
  final String levelCode;
  final bool isGraded;
  final double? overallScore;
  final DateTime? submittedAt;
}

@immutable
class HomeworkSummaryReport {
  const HomeworkSummaryReport({
    required this.assignedCount,
    required this.submittedCount,
    required this.sessionCount,
    required this.attendedCount,
    this.homeworkPercent,
    this.attendancePercent,
  });

  final int assignedCount;
  final int submittedCount;
  final double? homeworkPercent;
  final int sessionCount;
  final int attendedCount;
  final double? attendancePercent;
}

@immutable
class LearnerStudyHistory {
  const LearnerStudyHistory({
    this.mockTests = const [],
    this.practices = const [],
    this.homeworkReport,
  });

  final List<MockHistoryEntry> mockTests;
  final List<PracticeHistoryEntry> practices;
  final HomeworkSummaryReport? homeworkReport;
}

Object? _unwrapAnalytics(Object? raw) {
  if (raw is Map && raw.containsKey('result')) return raw['result'];
  return raw;
}

Map<String, Object?> _asAnalyticsMap(Object? raw) {
  final u = _unwrapAnalytics(raw);
  if (u is Map<String, Object?>) return u;
  if (u is Map) return u.map((k, v) => MapEntry(k.toString(), v));
  return const {};
}

final learnerSkillMonthlyProvider =
    FutureProvider.autoDispose<SkillMonthlySummary>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      final api = ref.watch(apiClientProvider);
      final res = await api.get<Object?>(AnalyticsApiPaths.skillMonthly(12));
      final m = _asAnalyticsMap(res.data);
      final rawSkills = m['skills'];
      final skills = rawSkills is Iterable
          ? rawSkills.whereType<Map>().map((raw) {
              final s = raw.map((k, v) => MapEntry(k.toString(), v));
              final rawPoints = s['monthlyScores'];
              final pts = rawPoints is Iterable
                  ? rawPoints.whereType<Map>().map((pRaw) {
                      final p = pRaw.map((k, v) => MapEntry(k.toString(), v));
                      return SkillMonthlyPoint(
                        month: p['month']?.toString() ?? '',
                        scorePercent: (p['scorePercent'] as num?)?.toDouble(),
                        attemptCount: (p['attemptCount'] as num?)?.toInt() ?? 0,
                      );
                    }).toList()
                  : const <SkillMonthlyPoint>[];
              return SkillMonthlyItem(
                languageSkillName: s['languageSkillName']?.toString() ?? '',
                currentAssessment: s['currentAssessment']?.toString() ?? '',
                currentScorePercent:
                    (s['currentScorePercent'] as num?)?.toDouble(),
                changeFromPreviousMonth:
                    (s['changeFromPreviousRecordedMonth'] as num?)?.toDouble(),
                comparedMonth: s['comparedMonth']?.toString(),
                totalAttempts: (s['totalAttempts'] as num?)?.toInt() ?? 0,
                monthlyScores: pts,
              );
            }).toList()
          : const <SkillMonthlyItem>[];

      return SkillMonthlySummary(
        assessedJlptLevel: m['assessedJlptLevel']?.toString(),
        targetJlptLevel: m['targetJlptLevel']?.toString(),
        totalAttempts: (m['totalAttempts'] as num?)?.toInt() ?? 0,
        currentOverallScorePercent:
            (m['currentOverallScorePercent'] as num?)?.toDouble(),
        summary: m['summary']?.toString() ?? '',
        skills: skills,
      );
    });

final learnerStudyHistoryProvider =
    FutureProvider.autoDispose<LearnerStudyHistory>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      final api = ref.watch(apiClientProvider);
      final now = DateTime.now();
      final fmt = DateFormat('yyyy-MM-dd');
      final from = fmt.format(now.subtract(const Duration(days: 90)));
      final to = fmt.format(now);

      var mocks = const <MockHistoryEntry>[];
      var practices = const <PracticeHistoryEntry>[];
      HomeworkSummaryReport? hwReport;

      await Future.wait([
        api
            .get<Object?>(AnalyticsApiPaths.mockTestHistory)
            .then((res) {
              final list = _unwrapAnalytics(res.data);
              if (list is Iterable) {
                mocks = list.whereType<Map>().map((raw) {
                  final j = raw.map((k, v) => MapEntry(k.toString(), v));
                  return MockHistoryEntry(
                    attemptId: (j['attemptId'] as num?)?.toInt() ?? 0,
                    title: j['title']?.toString() ?? 'Mock Test',
                    jlptLevelName: j['jlptLevelName']?.toString() ?? '',
                    totalScore: (j['totalScore'] as num?)?.toDouble() ?? 0,
                    submittedAt: DateTime.tryParse(
                      j['submittedAt']?.toString() ?? '',
                    )?.toLocal(),
                  );
                }).toList();
              }
            })
            .catchError((_) {}),
        api
            .get<Object?>(AnalyticsApiPaths.practiceHistory)
            .then((res) {
              final list = _unwrapAnalytics(res.data);
              if (list is Iterable) {
                practices = list.whereType<Map>().map((raw) {
                  final j = raw.map((k, v) => MapEntry(k.toString(), v));
                  final rawType = j['type']?.toString() ?? '';
                  final typeLabel = switch (rawType) {
                    '1' || 'Writing' => 'Luyện viết AI',
                    '2' || 'Speaking' => 'Luyện nói AI',
                    _ => rawType,
                  };
                  return PracticeHistoryEntry(
                    id: (j['id'] as num?)?.toInt() ?? 0,
                    type: typeLabel,
                    levelCode: j['certificateLevelCode']?.toString() ?? '',
                    isGraded: j['isGraded'] == true,
                    overallScore: (j['overallScore'] as num?)?.toDouble(),
                    submittedAt: DateTime.tryParse(
                      j['submittedAt']?.toString() ?? '',
                    )?.toLocal(),
                  );
                }).toList();
              }
            })
            .catchError((_) {}),
        api
            .get<Object?>(AnalyticsApiPaths.homeworkReport(from, to))
            .then((res) {
              final j = _asAnalyticsMap(res.data);
              if (j.isNotEmpty) {
                hwReport = HomeworkSummaryReport(
                  assignedCount: (j['assignedCount'] as num?)?.toInt() ?? 0,
                  submittedCount: (j['submittedCount'] as num?)?.toInt() ?? 0,
                  homeworkPercent: (j['homeworkPercent'] as num?)?.toDouble(),
                  sessionCount: (j['sessionCount'] as num?)?.toInt() ?? 0,
                  attendedCount: (j['attendedCount'] as num?)?.toInt() ?? 0,
                  attendancePercent: (j['attendancePercent'] as num?)
                      ?.toDouble(),
                );
              }
            })
            .catchError((_) {}),
      ]);

      return LearnerStudyHistory(
        mockTests: mocks,
        practices: practices,
        homeworkReport: hwReport,
      );
    });
