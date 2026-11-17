import 'package:flutter/foundation.dart';

String formatKpiMinutes(int minutes) {
  if (minutes <= 0) return '0 phút';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours <= 0) return '$mins phút';
  if (mins == 0) return '$hours giờ';
  return '${hours}g ${mins}p';
}

String formatKpiTurnaround(double? minutes) {
  if (minutes == null || minutes < 0) {
    return 'Chưa đủ dữ liệu';
  }
  if (minutes < 60) {
    return '${minutes.round()} phút';
  }
  final hours = (minutes / 60 * 10).round() / 10;
  return '$hours giờ (${minutes.round()} phút)';
}

String formatKpiCompletionRate(int completed, int assigned) {
  if (assigned <= 0) return '0%';
  return '${((completed / assigned) * 100).round()}%';
}

@immutable
class MentorKpiPeriodItem {
  const MentorKpiPeriodItem({
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
    required this.totalAssignedSessions,
    required this.completedValidSessions,
    required this.confirmedTeachingMinutes,
    required this.scheduledCompletedMinutes,
    required this.cancelledSessionsCount,
    required this.missedOrNoShowSessionsCount,
    required this.upcomingOrIncompleteSessionsCount,
    required this.homeworkAssignedCount,
    required this.homeworkSubmittedCount,
    required this.homeworkGradedCount,
    this.averageFeedbackTurnaroundMinutes,
    required this.feedbackTurnaroundSampleCount,
    required this.reviewsCount,
    this.averageRating,
    required this.disputesCount,
  });

  final String periodKey;
  final String periodStart;
  final String periodEnd;
  final int totalAssignedSessions;
  final int completedValidSessions;
  final int confirmedTeachingMinutes;
  final int scheduledCompletedMinutes;
  final int cancelledSessionsCount;
  final int missedOrNoShowSessionsCount;
  final int upcomingOrIncompleteSessionsCount;
  final int homeworkAssignedCount;
  final int homeworkSubmittedCount;
  final int homeworkGradedCount;
  final double? averageFeedbackTurnaroundMinutes;
  final int feedbackTurnaroundSampleCount;
  final int reviewsCount;
  final double? averageRating;
  final int disputesCount;
}

@immutable
class MentorKpiRecentSessionItem {
  const MentorKpiRecentSessionItem({
    required this.sourceType,
    required this.bookingOrSessionId,
    this.roomId,
    this.learnerName,
    this.jlptLevel,
    required this.status,
    this.scheduledStartUtc,
    this.scheduledEndUtc,
    required this.scheduledMinutes,
    required this.observedMentorMinutes,
    this.attendedAtUtc,
    required this.isValidCompleted,
  });

  final String sourceType;
  final int bookingOrSessionId;
  final String? roomId;
  final String? learnerName;
  final String? jlptLevel;
  final String status;
  final DateTime? scheduledStartUtc;
  final DateTime? scheduledEndUtc;
  final int scheduledMinutes;
  final int observedMentorMinutes;
  final DateTime? attendedAtUtc;
  final bool isValidCompleted;
}

@immutable
class MentorKpiSummary {
  const MentorKpiSummary({
    required this.mentorId,
    required this.mentorName,
    required this.fromDate,
    required this.toDate,
    this.teachingJlptLevels = const <String>[],
    this.totalAssignedSessions = 0,
    this.assignedBookingsCount = 0,
    this.assignedCourseSessionsCount = 0,
    this.completedValidSessions = 0,
    this.confirmedTeachingMinutes = 0,
    this.scheduledCompletedMinutes = 0,
    this.cancelledSessionsCount = 0,
    this.cancelledByMentorCount = 0,
    this.cancelledByLearnerCount = 0,
    this.missedOrNoShowSessionsCount = 0,
    this.upcomingOrIncompleteSessionsCount = 0,
    this.homeworkAssignedCount = 0,
    this.homeworkSubmittedCount = 0,
    this.homeworkGradedCount = 0,
    this.bookingHomeworkAssignedCount = 0,
    this.bookingHomeworkSubmittedCount = 0,
    this.bookingHomeworkGradedCount = 0,
    this.courseHomeworkAssignedCount = 0,
    this.courseHomeworkSubmittedCount = 0,
    this.courseHomeworkGradedCount = 0,
    this.averageFeedbackTurnaroundMinutes,
    this.feedbackTurnaroundSampleCount = 0,
    this.averageRating,
    this.totalReviewsCount = 0,
    this.ratingDistribution = const <int, int>{},
    this.totalDisputesCount = 0,
    this.openDisputesCount = 0,
    this.resolvedRefundCount = 0,
    this.weeklyBreakdown = const <MentorKpiPeriodItem>[],
    this.monthlyBreakdown = const <MentorKpiPeriodItem>[],
    this.recentSessions = const <MentorKpiRecentSessionItem>[],
    this.metricSources = const <String, String>{},
  });

  final int mentorId;
  final String mentorName;
  final String fromDate;
  final String toDate;
  final List<String> teachingJlptLevels;

  final int totalAssignedSessions;
  final int assignedBookingsCount;
  final int assignedCourseSessionsCount;
  final int completedValidSessions;
  final int confirmedTeachingMinutes;
  final int scheduledCompletedMinutes;
  final int cancelledSessionsCount;
  final int cancelledByMentorCount;
  final int cancelledByLearnerCount;
  final int missedOrNoShowSessionsCount;
  final int upcomingOrIncompleteSessionsCount;

  final int homeworkAssignedCount;
  final int homeworkSubmittedCount;
  final int homeworkGradedCount;
  final int bookingHomeworkAssignedCount;
  final int bookingHomeworkSubmittedCount;
  final int bookingHomeworkGradedCount;
  final int courseHomeworkAssignedCount;
  final int courseHomeworkSubmittedCount;
  final int courseHomeworkGradedCount;

  final double? averageFeedbackTurnaroundMinutes;
  final int feedbackTurnaroundSampleCount;

  final double? averageRating;
  final int totalReviewsCount;
  final Map<int, int> ratingDistribution;
  final int totalDisputesCount;
  final int openDisputesCount;
  final int resolvedRefundCount;

  final List<MentorKpiPeriodItem> weeklyBreakdown;
  final List<MentorKpiPeriodItem> monthlyBreakdown;
  final List<MentorKpiRecentSessionItem> recentSessions;
  final Map<String, String> metricSources;
}
