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
    final hwItems = rows(homework['items'])
        .where(
          (f) =>
              optStr(f['publishedFeedback']) != null ||
              optDouble(f['score']) != null ||
              boolean(f['graded']),
        )
        .map(
          (f) => CompletionFeedbackItem(
            title: str(f['title']),
            feedback: str(f['publishedFeedback'] ?? f['feedback']),
            score: optDouble(f['score']),
            publishedAtUtc: optDate(
              f['publishedFeedbackAtUtc'] ?? f['publishedAtUtc'],
            ),
          ),
        )
        .toList();
    final legacyFeedback = rows(j['mentorFeedback'])
        .map(
          (f) => CompletionFeedbackItem(
            title: str(f['title']),
            feedback: str(f['feedback'] ?? f['publishedFeedback']),
            score: optDouble(f['score']),
            publishedAtUtc: optDate(f['publishedAtUtc']),
          ),
        )
        .toList();
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
              isPrimary: boolean(m['isCurrentPrimary'] ?? m['isPrimary']),
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
              scheduledAt: optDate(a['date'] ?? a['scheduledAt']),
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
      mentorFeedback: hwItems.isNotEmpty ? hwItems : legacyFeedback,
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
            _formatShiftBlocker(b.map((k, v) => MapEntry(k.toString(), v)))
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
              startTime: optDate(s['proposedStart'] ?? s['startTime']),
              endTime: optDate(s['proposedEnd'] ?? s['endTime']),
              currentStart: optDate(s['currentStart']),
              currentEnd: optDate(s['currentEnd']),
            ),
          )
          .toList(),
      conflicts: rows(j['conflicts']).map(conflict).toList(),
      newEnrollmentClosesAtUtc: optDate(
        j['newEnrollmentCutoffUtc'] ?? j['newEnrollmentClosesAtUtc'],
      ),
    );
  }

  static String _formatShiftBlocker(Map<String, Object?> b) {
    final explicit = optStr(b['message']) ?? optStr(b['code']);
    if (explicit != null) return explicit;
    final courseId = optInt(b['courseId']);
    final kind = optStr(b['kind']) ?? optStr(b['status']) ?? '';
    final paymentStatus = optStr(b['paymentStatus']);
    final prefix = courseId != null ? 'Hồ sơ #$courseId' : 'Ghi danh';
    return paymentStatus != null && paymentStatus.isNotEmpty
        ? '$prefix ($kind · $paymentStatus)'
        : '$prefix ($kind)';
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

  static List<CourseSessionItem> courseSessions(Object? raw) {
    return rows(raw)
        .map(
          (s) => CourseSessionItem(
            id: integer(s['id']),
            number: integer(s['number']),
            attempt: integer(s['attempt'], 1),
            scheduledAt: date(s['scheduledAt']),
            status: str(s['status'], 'Scheduled'),
            note: optStr(s['note']),
            meetingUrl: optStr(s['meetingUrl']),
            confirmedAt: optDate(s['confirmedAt']),
          ),
        )
        .toList();
  }

  static List<CourseRetakeRequestItem> courseRetakeRequests(Object? raw) {
    return rows(raw)
        .map(
          (r) => CourseRetakeRequestItem(
            id: integer(r['id']),
            status: str(r['status'], 'Pending'),
            examDate: date(r['examDate']),
            resultPublishedAt: date(r['resultPublishedAt']),
            reason: str(r['reason']),
            submittedAt: date(r['submittedAt']),
            reviewedAt: optDate(r['reviewedAt']),
            response: optStr(r['response']),
            mentorSupportPlan: optStr(r['mentorSupportPlan']),
            mentorSupportPlanAtUtc: optDate(r['mentorSupportPlanAtUtc']),
          ),
        )
        .toList();
  }

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
      sessions: courseSessions(j['sessions']),
      retakeRequests: courseRetakeRequests(j['requests'] ?? j['retakeRequests']),
    );
  }

  static MentorCohortHomeworkRow homeworkRow(Map<String, Object?> j) {
    final subMap = optMap(j['submission']);
    final gradeMap = optMap(j['publishedGrade']) ?? optMap(subMap?['grade']);
    final aiMap = optMap(j['aiDraft']);
    return MentorCohortHomeworkRow(
      id: integer(j['id']),
      title: str(j['title']),
      instructions: optStr(j['instructions']),
      learnerId: optInt(j['learnerId']),
      learnerName: optStr(j['learnerName']) ?? 'Học viên #${integer(j['learnerId'])}',
      status: str(j['status'], 'Assigned'),
      assignmentScope: str(j['assignmentScope'], 'CohortCommon'),
      cohortAssignmentGroupKey: optStr(j['cohortAssignmentGroupKey']),
      assignedAt: optDate(j['assignedAt']),
      dueAt: optDate(j['dueAt']),
      submission: subMap == null
          ? null
          : CohortHomeworkSubmission(
              id: integer(subMap['id']),
              textContent: optStr(subMap['textContent']),
              submittedAt: date(subMap['submittedAt']),
              revisionCount: integer(subMap['revisionCount'], 1),
              lastRevisedAtUtc: optDate(subMap['lastRevisedAtUtc']),
              hasScan: boolean(subMap['hasScan']),
            ),
      aiDraft: aiMap == null
          ? null
          : MentorHomeworkAiDraft(
              suggestedScore: optDouble(aiMap['suggestedScore'] ?? aiMap['score']),
              feedback: optStr(aiMap['feedback']),
              generatedAtUtc: optDate(aiMap['generatedAtUtc']),
              unavailableReason: optStr(aiMap['unavailableReason']),
              transcription: optStr(aiMap['transcription']),
            ),
      publishedGrade: gradeMap == null
          ? null
          : CohortHomeworkPublishedGrade(
              passed: gradeMap['passed'] is bool ? gradeMap['passed'] as bool : null,
              score: optDouble(gradeMap['score']),
              feedback: str(gradeMap['feedback']),
              publishedAtUtc: date(gradeMap['publishedAtUtc'] ?? gradeMap['publishedAt']),
            ),
      lessonTitles: rows(j['lessons']).map((e) => str(e['title'])).where((e) => e.isNotEmpty).toList(),
      exerciseTitles: rows(j['exercises']).map((e) => str(e['title'])).where((e) => e.isNotEmpty).toList(),
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
    final submitted = pick('submittedCount', 'submissionCount');
    final graded = pick('gradedCount');
    final total = pick('totalLearners', 'assignedCount');
    final row = homeworkRow(j);
    return MentorCohortHomeworkItem(
      id: integer(j['id']),
      title: str(j['title']),
      status: str(j['status'], 'Assigned'),
      assignmentScope: str(j['assignmentScope'], 'CohortCommon'),
      cohortAssignmentGroupKey: row.cohortAssignmentGroupKey,
      instructions: row.instructions,
      dueAt: optDate(j['dueAt']),
      submittedCount: submitted ?? (row.submission != null ? 1 : 0),
      gradedCount: graded ?? (row.publishedGrade != null || row.status == 'Graded' ? 1 : 0),
      totalCount: total ?? 1,
      rows: [row],
    );
  }

  /// Groups flat per-learner backend `HomeworkItem` rows by
  /// `cohortAssignmentGroupKey` (or single assignment when null) while
  /// preserving pre-aggregated payloads.
  static List<MentorCohortHomeworkItem> homeworkList(Object? raw) {
    final items = list(raw);
    if (items.isEmpty) return const [];
    final isPreAggregated = items.any(
      (j) =>
          j.containsKey('stats') ||
          j.containsKey('summary') ||
          j.containsKey('submittedCount') ||
          j.containsKey('submissionCount') ||
          j.containsKey('totalLearners'),
    );
    if (isPreAggregated) {
      return items.map(homework).toList();
    }
    final grouped = <String, List<MentorCohortHomeworkRow>>{};
    for (final j in items) {
      final row = homeworkRow(j);
      final key = row.cohortAssignmentGroupKey ?? 'single:${row.id}';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.values.map((groupRows) {
      final first = groupRows.first;
      final submitted = groupRows.where((r) => r.submission != null).length;
      final graded = groupRows
          .where((r) => r.publishedGrade != null || r.status == 'Graded')
          .length;
      final allGraded = graded == groupRows.length && groupRows.isNotEmpty;
      return MentorCohortHomeworkItem(
        id: first.id,
        title: first.title,
        status: allGraded ? 'Graded' : (submitted > 0 ? 'Submitted' : first.status),
        assignmentScope: first.assignmentScope,
        cohortAssignmentGroupKey: first.cohortAssignmentGroupKey,
        instructions: first.instructions,
        dueAt: first.dueAt,
        submittedCount: submitted,
        gradedCount: graded,
        totalCount: groupRows.length,
        rows: groupRows,
      );
    }).toList();
  }

  static CohortMentorAssignment mentorAssignment(Map<String, Object?> j) {
    final role = str(j['role'] ?? j['kind']);
    final prevId = optInt(j['previousMentorId']);
    final mentorId = integer(j['mentorId']);
    return CohortMentorAssignment(
      mentorId: mentorId,
      mentorName: optStr(j['mentorName']) ?? 'Mentor #$mentorId',
      isPrimary: j['isPrimary'] is bool
          ? j['isPrimary'] as bool
          : (prevId == null || prevId == 0) && role.toLowerCase() != 'substitute',
      fromSessionNumber: optInt(j['effectiveFromSessionNumber']) ??
          optInt(j['fromSessionNumber']) ??
          optInt(j['effectiveFromSession']),
      assignedAtUtc: optDate(j['assignedAtUtc'] ?? j['createdAtUtc']),
      reason: optStr(j['reason'] ?? j['note']),
      previousMentorId: prevId,
      affectedSessionCount: optInt(j['affectedSessionCount']),
      effectiveFromUtc: optDate(j['effectiveFromUtc']),
    );
  }

  static MentorLearnerSkillProfile skillProfile(Map<String, Object?> j) {
    final hw = optMap(j['homeworkStats']) ?? const <String, Object?>{};
    return MentorLearnerSkillProfile(
      learnerId: integer(j['learnerId']),
      learnerName: optStr(j['learnerName']) ?? 'Học viên',
      cohortId: optInt(j['cohortId']),
      assessedJlptLevel: optStr(j['assessedJlptLevel']),
      skills: rows(j['skills'])
          .map(
            (s) => MentorLearnerSkillMetric(
              skill: str(s['skill']),
              averageScorePercent: optDouble(s['averageScorePercent']),
              sampleCount: integer(s['sampleCount']),
              latestAssessedAtUtc: optDate(s['latestAssessedAtUtc']),
              dataSource: optStr(s['dataSource']),
            ),
          )
          .toList(),
      assignedCount: integer(hw['assignedCount']),
      submittedCount: integer(hw['submittedCount']),
      onTimeCount: integer(hw['onTimeCount']),
      passedCount: integer(hw['passedCount']),
      onTimePercent: optDouble(hw['onTimePercent']),
      latestActivityAtUtc: optDate(hw['latestActivityAtUtc']),
    );
  }
}
