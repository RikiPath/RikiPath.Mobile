import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/analytics/data/analytics_api_paths.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';

class ApiAnalyticsRepository implements AnalyticsRepository {
  const ApiAnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async {
    final responses = await (
      _load(AnalyticsApiPaths.studyStreak, _parseStreak),
      _load(AnalyticsApiPaths.completionStats, _parseCompletion),
      _load(AnalyticsApiPaths.skillBreakdown, _parseSkills),
    ).wait;
    final unavailable = <AnalyticsSection>{
      if (responses.$1.error != null) AnalyticsSection.streak,
      if (responses.$2.error != null) AnalyticsSection.completion,
      if (responses.$3.error != null) AnalyticsSection.skills,
    };
    if (unavailable.length == AnalyticsSection.values.length) {
      throw responses.$1.error!;
    }

    final completion = responses.$2.data;
    return LearnerAnalytics(
      streakDays: responses.$1.data ?? 0,
      completedLessons: completion?.completed ?? 0,
      totalLessons: completion?.total ?? 0,
      skills: responses.$3.data ?? const <SkillBreakdown>[],
      unavailableSections: unavailable,
    );
  }

  Future<_LoadResult<T>> _load<T>(
    String path,
    T Function(Object? body) parse,
  ) async {
    try {
      final response = await _apiClient.get<Object?>(path);
      return _LoadResult<T>.success(parse(_unwrap(response.data)));
    } catch (error) {
      return _LoadResult<T>.failure(error);
    }
  }

  Object? _unwrap(Object? body) {
    if (body is Map && body.containsKey('result')) return body['result'];
    return body;
  }

  int _parseStreak(Object? body) {
    final map = _requireMap(body);
    return _requiredNonNegativeInt(map, 'currentStreakDays');
  }

  ({int completed, int total}) _parseCompletion(Object? body) {
    final map = _requireMap(body);
    final completed = _requiredNonNegativeInt(map, 'completedLessons');
    final total = _requiredNonNegativeInt(map, 'totalLessons');
    if (completed > total) throw _malformedAnalytics;
    return (completed: completed, total: total);
  }

  List<SkillBreakdown> _parseSkills(Object? body) {
    if (body is! List) throw _malformedAnalytics;
    final skills = <SkillBreakdown>[];
    for (final item in body) {
      try {
        skills.add(_parseSkill(item));
      } catch (_) {
        // One corrupt record must not erase valid sibling skill metrics.
      }
    }
    if (body.isNotEmpty && skills.isEmpty) throw _malformedAnalytics;
    return List<SkillBreakdown>.unmodifiable(skills);
  }

  SkillBreakdown _parseSkill(Object? item) {
    final map = _requireMap(item);
    final skill = map['languageSkillName'];
    if (skill is! String || skill.trim().isEmpty) {
      throw _malformedAnalytics;
    }
    final averageScore = _requiredNumber(map, 'averageScore');
    final attemptCount = _requiredNonNegativeInt(map, 'attemptCount');
    if (!averageScore.isFinite || averageScore < 0 || averageScore > 100) {
      throw _malformedAnalytics;
    }
    return SkillBreakdown(
      skill: skill.trim(),
      averageScore: averageScore,
      attemptCount: attemptCount,
    );
  }

  Map<String, Object?> _requireMap(Object? value) {
    if (value is! Map) throw _malformedAnalytics;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  int _requiredNonNegativeInt(Map<String, Object?> map, String key) {
    final value = map[key];
    final parsed = switch (value) {
      int value => value,
      num value when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      _ => null,
    };
    if (parsed == null || parsed < 0) throw _malformedAnalytics;
    return parsed;
  }

  double _requiredNumber(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! num) throw _malformedAnalytics;
    return value.toDouble();
  }
}

const _malformedAnalytics = UnknownError(
  message: 'The analytics response was malformed.',
);

class _LoadResult<T> {
  const _LoadResult.success(this.data) : error = null;

  const _LoadResult.failure(this.error) : data = null;

  final T? data;
  final Object? error;
}
