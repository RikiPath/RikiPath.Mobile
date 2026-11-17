import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

/// Envelope + JSON helpers shared by the cohort repositories. Every backend
/// response uses `{ isSuccess, statusCode, errorMessage, errorCode, result }`;
/// failures are already turned into `ApiError` by `ApiClient`.
abstract final class CohortJson {
  static Object? unwrap(Object? raw) {
    if (raw is Map && raw.containsKey('result')) return raw['result'];
    return raw;
  }

  static List<Map<String, Object?>> list(Object? raw) {
    final unwrapped = unwrap(raw);
    if (unwrapped is List) return rows(unwrapped);
    if (unwrapped is Map) {
      // Some list endpoints page their rows as { items: [...] }.
      final items = unwrapped['items'];
      if (items is List) return rows(items);
    }
    return const [];
  }

  static List<Map<String, Object?>> rows(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  static Map<String, Object?> map(Object? raw) {
    final unwrapped = unwrap(raw);
    if (unwrapped is Map) {
      return unwrapped.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  static Map<String, Object?>? optMap(Object? raw) {
    if (raw is! Map) return null;
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }

  static int integer(Object? v, [int fallback = 0]) => optInt(v) ?? fallback;

  static int? optInt(Object? v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? optDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String str(Object? v, [String fallback = '']) =>
      v?.toString() ?? fallback;

  static String? optStr(Object? v) {
    final s = v?.toString();
    if (s == null || s.trim().isEmpty) return null;
    return s;
  }

  static bool boolean(Object? v, [bool fallback = false]) =>
      v is bool ? v : fallback;

  static DateTime date(Object? v) =>
      optDate(v) ?? DateTime.now();

  static DateTime? optDate(Object? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  /// First non-empty string among [keys].
  static String firstStr(Map<String, Object?> j, List<String> keys) {
    for (final k in keys) {
      final s = optStr(j[k]);
      if (s != null) return s;
    }
    return '';
  }

  // -------------------------------------------------------------------------
  // Cohorts
  // -------------------------------------------------------------------------

  static StudyCohortSummary cohort(Map<String, Object?> j) {
    final sessions = rows(j['sessions'])
        .map(
          (s) => CohortSessionSlot(
            number: integer(s['number']),
            availabilityId: integer(s['availabilityId']),
            roomId: str(s['roomId']),
            startTime: date(s['startTime']),
            endTime: date(s['endTime']),
            status: str(s['status']),
          ),
        )
        .toList();
    final pattern = rows(j['schedulePattern'])
        .map(
          (p) => CohortSchedulePatternItem(
            weekday: integer(p['weekday']),
            weekdayLabel: str(p['weekdayLabel']),
            localStart: str(p['localStart']),
            localEnd: str(p['localEnd']),
          ),
        )
        .toList();
    return StudyCohortSummary(
      id: integer(j['id']),
      planId: integer(j['planId']),
      name: str(j['name']),
      mentorId: integer(j['mentorId']),
      mentorName: str(j['mentorName']),
      startsAt: date(j['startsAt']),
      endsAt: date(j['endsAt']),
      capacity: integer(j['capacity']),
      enrolledCount: integer(j['enrolledCount']),
      seatsAvailable: integer(j['seatsAvailable']),
      status: str(j['status']),
      level: str(j['level']),
      totalSessions: optInt(j['totalSessions']),
      sessionMinutes: optInt(j['sessionMinutes']),
      price: (j['price'] as num?) ?? 0,
      enrollmentClosesAtUtc: date(j['enrollmentClosesAtUtc']),
      requiresEntitlement: boolean(j['requiresEntitlement']),
      hasApprovedEntitlement: boolean(j['hasApprovedEntitlement']),
      entitlementReference: j['entitlementReference']?.toString(),
      entitlementStatusMessage: j['entitlementStatusMessage']?.toString(),
      myEnrollmentCourseId: optInt(j['myEnrollmentCourseId']),
      myEnrollmentStatus: j['myEnrollmentStatus']?.toString(),
      enrollmentOpen: boolean(j['enrollmentOpen']),
      sessions: sessions,
      checkoutMode: str(j['checkoutMode'], 'PayOS'),
      myEnrollmentPaymentState: j['myEnrollmentPaymentState']?.toString(),
      intensity: str(j['intensity']),
      intensityLabel: str(j['intensityLabel']),
      isRecommendedIntensity: boolean(j['isRecommendedIntensity']),
      totalTeachingHours: optDouble(j['totalTeachingHours']),
      sessionsPerWeek: optInt(j['sessionsPerWeek']),
      schedulePattern: pattern,
    );
  }

  static List<CohortTransferHistoryItem> history(Object? raw) {
    return rows(raw)
        .map(
          (h) => CohortTransferHistoryItem(
            action: str(h['action']),
            actorRole: str(h['actorRole']),
            detail: str(h['detail']),
            atUtc: date(h['atUtc']),
          ),
        )
        .toList();
  }

  // -------------------------------------------------------------------------
  // Reviews / complaints / completion
  // -------------------------------------------------------------------------

  static MentorCohortReviewSummary reviewSummary(
    Map<String, Object?> j, {
    required int mentorId,
  }) {
    return MentorCohortReviewSummary(
      mentorId: optInt(j['mentorId']) ?? mentorId,
      averageRating: optDouble(j['averageRating']) ?? 0,
      reviewCount: integer(j['reviewCount']),
      comments: rows(j['comments'])
          .map(
            (c) => CohortReviewComment(
              rating: integer(c['rating']),
              comment: str(c['comment']),
              createdAtUtc: optDate(c['createdAtUtc']),
            ),
          )
          .toList(),
    );
  }

  static CohortMentorReview review(Map<String, Object?> j) {
    return CohortMentorReview(
      id: integer(j['id']),
      mentorId: integer(j['mentorId']),
      mentorName: str(j['mentorName']),
      rating: integer(j['rating']),
      comment: str(j['comment']),
      createdAtUtc: optDate(j['createdAtUtc']),
      updatedAtUtc: optDate(j['updatedAtUtc']),
    );
  }

  static CohortComplaint complaint(Map<String, Object?> j) {
    return CohortComplaint(
      id: integer(j['id']),
      courseId: integer(j['courseId']),
      cohortId: optInt(j['cohortId']),
      cohortName: optStr(j['cohortName']),
      mentorId: optInt(j['mentorId']),
      mentorName: optStr(j['mentorName']),
      category: str(j['category'], CohortComplaintCategory.other),
      message: str(j['message']),
      status: str(j['status'], 'Open'),
      refundReviewRequested: boolean(j['refundReviewRequested']),
      hasEvidence: boolean(j['hasEvidence']),
      mentorResponse: optStr(j['mentorResponse']),
      decision: optStr(j['decision']),
      createdAtUtc: optDate(j['createdAtUtc']),
      decidedAtUtc: optDate(j['decidedAtUtc']),
      revision: integer(j['revision']),
      history: history(j['history']),
    );
  }

  static CohortCompletionSummary completion(Map<String, Object?> j) {
    final sessions = map(j['sessions']);
    final homework = map(j['homework']);
    return CohortCompletionSummary(
      courseId: integer(j['courseId']),
      cohortId: optInt(j['cohortId']),
      cohortName: str(j['cohortName']),
      level: str(j['level']),
      intensity: str(j['intensity']),
      intensityLabel: str(j['intensityLabel']),
      isCompleted: boolean(j['isCompleted']),
      mentors: rows(j['mentors'])
          .map(
            (m) => CompletionMentorItem(
              mentorId: integer(m['mentorId']),
              mentorName: str(m['mentorName']),
              sessionNumbers: (m['sessionNumbers'] is List
                      ? m['sessionNumbers'] as List
                      : const [])
                  .map(optInt)
                  .whereType<int>()
                  .toList(),
              isPrimary: boolean(m['isPrimary']),
            ),
          )
          .toList(),
      sessions: CompletionSessionCounts(
        total: integer(sessions['total']),
        delivered: integer(sessions['delivered']),
        absent: integer(sessions['absent']),
        cancelled: integer(sessions['cancelled']),
        upcoming: integer(sessions['upcoming']),
      ),
      attendance: rows(j['attendance'])
          .map(
            (a) => CompletionAttendanceItem(
              number: integer(a['number']),
              scheduledAt: optDate(a['scheduledAt']),
              status: str(a['status']),
            ),
          )
          .toList(),
      homework: CompletionHomeworkCounts(
        assigned: integer(homework['assigned']),
        submitted: integer(homework['submitted']),
        graded: integer(homework['graded']),
        outstanding: integer(homework['outstanding']),
      ),
      mentorFeedback: rows(j['mentorFeedback'])
          .map(
            (f) => CompletionFeedbackItem(
              title: str(f['title']),
              feedback: str(f['feedback']),
              score: optDouble(f['score']),
              publishedAtUtc: optDate(f['publishedAtUtc']),
            ),
          )
          .toList(),
      skillProgressAvailable: boolean(j['skillProgressAvailable']),
      skillProgress: j['skillProgress'],
      note: str(j['note']),
    );
  }

  // -------------------------------------------------------------------------
  // Schedule requests / conflicts
  // -------------------------------------------------------------------------

  static ScheduleConflictItem conflict(Map<String, Object?> j) {
    return ScheduleConflictItem(
      code: str(j['code']),
      message: str(j['message']),
      sessionNumber: optInt(j['sessionNumber']),
      proposedStartUtc: optDate(j['proposedStartUtc']),
      proposedEndUtc: optDate(j['proposedEndUtc']),
      commitmentKind: optStr(j['commitmentKind']),
      cohortId: optInt(j['cohortId']),
      cohortName: optStr(j['cohortName']),
      commitmentStartUtc: optDate(j['commitmentStartUtc']),
      commitmentEndUtc: optDate(j['commitmentEndUtc']),
    );
  }

  static CohortShiftPreview shiftPreview(Map<String, Object?> j) {
    final rawBlockers = j['blockers'];
    final blockers = <String>[
      if (rawBlockers is List)
        for (final b in rawBlockers)
          if (b is Map)
            str(b['message'] ?? b['code'])
          else if (b != null)
            b.toString(),
    ].where((b) => b.trim().isNotEmpty).toList();
    return CohortShiftPreview(
      eligible: boolean(j['eligible']),
      checks: rows(j['checks'])
          .map(
            (c) => ShiftPreviewCheck(
              code: str(c['code']),
              passed: boolean(c['passed']),
              message: str(c['message']),
            ),
          )
          .toList(),
      blockers: blockers,
      proposedSessions: rows(j['proposedSessions'])
          .map(
            (s) => ShiftPreviewSession(
              number: integer(s['number']),
              startTime: optDate(s['startTime']),
              endTime: optDate(s['endTime']),
            ),
          )
          .toList(),
      conflicts: rows(j['conflicts']).map(conflict).toList(),
      newEnrollmentClosesAtUtc: optDate(j['newEnrollmentClosesAtUtc']),
    );
  }

  static CohortScheduleRequest scheduleRequest(Map<String, Object?> j) {
    return CohortScheduleRequest(
      id: integer(j['id']),
      cohortId: integer(j['cohortId']),
      cohortName: str(j['cohortName']),
      kind: str(j['kind']),
      shiftWeeks: optInt(j['shiftWeeks']),
      reason: str(j['reason']),
      status: str(j['status']),
      requestedByRole: str(j['requestedByRole']),
      createdAtUtc: optDate(j['createdAtUtc']),
      reviewedAtUtc: optDate(j['reviewedAtUtc']),
      decisionNote: optStr(j['decisionNote']),
      revision: integer(j['revision']),
      history: history(j['history']),
    );
  }

  // -------------------------------------------------------------------------
  // Mentor operations
  // -------------------------------------------------------------------------

  static MentorCohortRosterEntry rosterEntry(Map<String, Object?> j) {
    final learner = optMap(j['learner']) ?? const <String, Object?>{};
    return MentorCohortRosterEntry(
      courseId: integer(j['id']),
      learnerId: optInt(j['learnerId']) ??
          optInt(j['userId']) ??
          optInt(learner['id']),
      learnerName: firstStr({
        ...j,
        'learnerNestedName': learner['fullName'] ?? learner['name'],
      }, const [
        'learnerName',
        'learnerFullName',
        'learnerDisplayName',
        'learnerNestedName',
      ]),
      status: str(j['status']),
    );
  }

  static MentorCohortHomeworkItem homework(Map<String, Object?> j) {
    final stats = optMap(j['stats']) ??
        optMap(j['summary']) ??
        const <String, Object?>{};
    int? pick(String key, [String? alt]) =>
        optInt(j[key]) ??
        (alt != null ? optInt(j[alt]) : null) ??
        optInt(stats[key]) ??
        (alt != null ? optInt(stats[alt]) : null);
    return MentorCohortHomeworkItem(
      id: integer(j['id']),
      title: str(j['title']),
      status: str(j['status'], 'Assigned'),
      assignmentScope: str(j['assignmentScope'], 'CohortCommon'),
      dueAt: optDate(j['dueAt']),
      submittedCount: pick('submittedCount', 'submissionCount'),
      gradedCount: pick('gradedCount'),
      totalCount: pick('totalLearners', 'assignedCount'),
    );
  }

  static CohortMentorAssignment mentorAssignment(Map<String, Object?> j) {
    final role = str(j['role'] ?? j['kind']);
    return CohortMentorAssignment(
      mentorId: integer(j['mentorId']),
      mentorName: str(j['mentorName']),
      isPrimary: j['isPrimary'] is bool
          ? j['isPrimary'] as bool
          : role.toLowerCase() == 'primary',
      fromSessionNumber:
          optInt(j['fromSessionNumber']) ?? optInt(j['effectiveFromSession']),
      assignedAtUtc: optDate(j['assignedAtUtc'] ?? j['createdAtUtc']),
      reason: optStr(j['reason'] ?? j['note']),
    );
  }
}
