import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';

int _asInt(Object? raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

double? _asNullableDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return null;
}

String _asString(Object? raw, {String fallback = ''}) {
  if (raw is String) return raw.trim();
  return raw?.toString() ?? fallback;
}

String? _asNullableString(Object? raw) {
  if (raw == null) return null;
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}

DateTime? _asNullableDateTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}

List<Map<String, Object?>> _asObjectList(Object? raw) {
  if (raw is! List<Object?>) return const <Map<String, Object?>>[];
  final items = <Map<String, Object?>>[];
  for (final item in raw) {
    if (item is Map<Object?, Object?>) {
      items.add(item.map((k, v) => MapEntry(k.toString(), v)));
    }
  }
  return items;
}

MentorKpiPeriodItem parseMentorKpiPeriodItem(Map<String, Object?> json) {
  return MentorKpiPeriodItem(
    periodKey: _asString(json['periodKey']),
    periodStart: _asString(json['periodStart']),
    periodEnd: _asString(json['periodEnd']),
    totalAssignedSessions: _asInt(json['totalAssignedSessions']),
    completedValidSessions: _asInt(json['completedValidSessions']),
    confirmedTeachingMinutes: _asInt(json['confirmedTeachingMinutes']),
    scheduledCompletedMinutes: _asInt(json['scheduledCompletedMinutes']),
    cancelledSessionsCount: _asInt(json['cancelledSessionsCount']),
    missedOrNoShowSessionsCount: _asInt(json['missedOrNoShowSessionsCount']),
    upcomingOrIncompleteSessionsCount: _asInt(
      json['upcomingOrIncompleteSessionsCount'],
    ),
    homeworkAssignedCount: _asInt(json['homeworkAssignedCount']),
    homeworkSubmittedCount: _asInt(json['homeworkSubmittedCount']),
    homeworkGradedCount: _asInt(json['homeworkGradedCount']),
    averageFeedbackTurnaroundMinutes: _asNullableDouble(
      json['averageFeedbackTurnaroundMinutes'],
    ),
    feedbackTurnaroundSampleCount: _asInt(
      json['feedbackTurnaroundSampleCount'],
    ),
    reviewsCount: _asInt(json['reviewsCount']),
    averageRating: _asNullableDouble(json['averageRating']),
    disputesCount: _asInt(json['disputesCount']),
  );
}

MentorKpiRecentSessionItem parseMentorKpiRecentSessionItem(
  Map<String, Object?> json,
) {
  return MentorKpiRecentSessionItem(
    sourceType: _asString(json['sourceType'], fallback: 'Booking1on1'),
    bookingOrSessionId: _asInt(json['bookingOrSessionId']),
    roomId: _asNullableString(json['roomId']),
    learnerName: _asNullableString(json['learnerName']),
    jlptLevel: _asNullableString(json['jlptLevel']),
    status: _asString(json['status']),
    scheduledStartUtc: _asNullableDateTime(json['scheduledStartUtc']),
    scheduledEndUtc: _asNullableDateTime(json['scheduledEndUtc']),
    scheduledMinutes: _asInt(json['scheduledMinutes']),
    observedMentorMinutes: _asInt(json['observedMentorMinutes']),
    attendedAtUtc: _asNullableDateTime(json['attendedAtUtc']),
    isValidCompleted: json['isValidCompleted'] as bool? ?? false,
  );
}

MentorKpiSummary parseMentorKpiSummary(Map<String, Object?> json) {
  final levelsRaw = json['teachingJlptLevels'];
  final levels = levelsRaw is List<Object?>
      ? levelsRaw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
      : const <String>[];

  final dist = <int, int>{};
  final rawDist = json['ratingDistribution'];
  if (rawDist is Map<Object?, Object?>) {
    for (final entry in rawDist.entries) {
      final star = int.tryParse(entry.key.toString());
      if (star != null) {
        dist[star] = _asInt(entry.value);
      }
    }
  }

  final sources = <String, String>{};
  final rawSources = json['metricSources'];
  if (rawSources is Map<Object?, Object?>) {
    for (final entry in rawSources.entries) {
      final val = _asNullableString(entry.value);
      if (val != null) {
        sources[entry.key.toString()] = val;
      }
    }
  }

  return MentorKpiSummary(
    mentorId: _asInt(json['mentorId']),
    mentorName: _asString(json['mentorName'], fallback: 'Cố vấn'),
    fromDate: _asString(json['fromDate']),
    toDate: _asString(json['toDate']),
    teachingJlptLevels: levels,
    totalAssignedSessions: _asInt(json['totalAssignedSessions']),
    assignedBookingsCount: _asInt(json['assignedBookingsCount']),
    assignedCourseSessionsCount: _asInt(json['assignedCourseSessionsCount']),
    completedValidSessions: _asInt(json['completedValidSessions']),
    confirmedTeachingMinutes: _asInt(json['confirmedTeachingMinutes']),
    scheduledCompletedMinutes: _asInt(json['scheduledCompletedMinutes']),
    cancelledSessionsCount: _asInt(json['cancelledSessionsCount']),
    cancelledByMentorCount: _asInt(json['cancelledByMentorCount']),
    cancelledByLearnerCount: _asInt(json['cancelledByLearnerCount']),
    missedOrNoShowSessionsCount: _asInt(json['missedOrNoShowSessionsCount']),
    upcomingOrIncompleteSessionsCount: _asInt(
      json['upcomingOrIncompleteSessionsCount'],
    ),
    homeworkAssignedCount: _asInt(json['homeworkAssignedCount']),
    homeworkSubmittedCount: _asInt(json['homeworkSubmittedCount']),
    homeworkGradedCount: _asInt(json['homeworkGradedCount']),
    bookingHomeworkAssignedCount: _asInt(json['bookingHomeworkAssignedCount']),
    bookingHomeworkSubmittedCount: _asInt(
      json['bookingHomeworkSubmittedCount'],
    ),
    bookingHomeworkGradedCount: _asInt(json['bookingHomeworkGradedCount']),
    courseHomeworkAssignedCount: _asInt(json['courseHomeworkAssignedCount']),
    courseHomeworkSubmittedCount: _asInt(json['courseHomeworkSubmittedCount']),
    courseHomeworkGradedCount: _asInt(json['courseHomeworkGradedCount']),
    averageFeedbackTurnaroundMinutes: _asNullableDouble(
      json['averageFeedbackTurnaroundMinutes'],
    ),
    feedbackTurnaroundSampleCount: _asInt(
      json['feedbackTurnaroundSampleCount'],
    ),
    averageRating: _asNullableDouble(json['averageRating']),
    totalReviewsCount: _asInt(json['totalReviewsCount']),
    ratingDistribution: dist,
    totalDisputesCount: _asInt(json['totalDisputesCount']),
    openDisputesCount: _asInt(json['openDisputesCount']),
    resolvedRefundCount: _asInt(json['resolvedRefundCount']),
    weeklyBreakdown: _asObjectList(
      json['weeklyBreakdown'],
    ).map(parseMentorKpiPeriodItem).toList(growable: false),
    monthlyBreakdown: _asObjectList(
      json['monthlyBreakdown'],
    ).map(parseMentorKpiPeriodItem).toList(growable: false),
    recentSessions: _asObjectList(
      json['recentSessions'],
    ).map(parseMentorKpiRecentSessionItem).toList(growable: false),
    metricSources: sources,
  );
}
