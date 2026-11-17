import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_json.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

abstract interface class CohortRepository {
  /// All filters are optional and map 1:1 to the backend query string
  /// (`mentorId`, `level`, `intensity`, `weekday` 0..6, `fromTime`/`toTime`
  /// as "HH:mm").
  Future<List<StudyCohortSummary>> fetchCohorts({
    int? mentorId,
    String? level,
    String? intensity,
    int? weekday,
    String? fromTime,
    String? toTime,
  });
  Future<MentorCohortReviewSummary> fetchMentorReviewSummary(int mentorId);
  Future<CohortCompletionSummary> fetchCompletionSummary(int courseId);
  Future<List<CohortMentorReview>> fetchCourseMentorReviews(int courseId);
  Future<CohortMentorReview?> submitMentorReview({
    required int courseId,
    required int mentorId,
    required int rating,
    required String comment,
  });
  Future<CohortMentorReview?> updateMentorReview({
    required int courseId,
    required int reviewId,
    required int mentorId,
    required int rating,
    required String comment,
  });
  Future<List<CohortComplaint>> fetchMyComplaints({String? status});
  Future<CohortComplaint?> submitComplaint({
    required int courseId,
    required String category,
    required String message,
    int? mentorId,
    bool refundReviewRequested = false,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  });
  Future<List<CohortEntitlementItem>> fetchMyEntitlements();
  Future<int> enrollCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  });
  Future<CohortCheckoutResult> checkoutCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  });
  Future<void> reconcileCoursePayment(int courseId);
  Future<List<LearnerStudyCourseDetail>> fetchMyCourses();
  Future<void> cancelCohortEnrollment({
    required int courseId,
    String? reason,
  });
  Future<List<CohortHomeworkAssignment>> fetchCohortHomework(int cohortId);
  Future<void> submitHomeworkText({
    required int assignmentId,
    required String textContent,
  });
  Future<void> submitHomeworkScan({
    required int assignmentId,
    String? textContent,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });
  Future<void> requestJlptRetake({
    required int courseId,
    required DateTime examDate,
    required DateTime resultPublishedAt,
    required String reason,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  });
  Future<List<CohortTransferRequestItem>> fetchMyTransferRequests();
  Future<CohortTransferRequestItem> requestCohortTransfer({
    required int courseId,
    int? targetCohortId,
    required String reason,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  });
  Future<void> withdrawCohortTransfer(int requestId);
}

final cohortRepositoryProvider = Provider<CohortRepository>((ref) {
  return ApiCohortRepository(ref.watch(apiClientProvider));
});

class ApiCohortRepository implements CohortRepository {
  const ApiCohortRepository(this._apiClient);

  final ApiClient _apiClient;

  static Object? _unwrap(Object? raw) {
    if (raw is Map<String, Object?> && raw.containsKey('result')) {
      return raw['result'];
    }
    if (raw is Map && raw.containsKey('result')) {
      return raw['result'];
    }
    return raw;
  }

  static List<Map<String, Object?>> _asList(Object? raw) {
    final unwrapped = _unwrap(raw);
    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return const [];
  }

  static Map<String, Object?> _asMap(Object? raw) {
    final unwrapped = _unwrap(raw);
    if (unwrapped is Map) {
      return unwrapped.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  static DateTime _parseDate(Object? v) =>
      DateTime.parse(v?.toString() ?? DateTime.now().toUtc().toIso8601String())
          .toLocal();

  static DateTime? _optDate(Object? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  @override
  Future<List<StudyCohortSummary>> fetchCohorts({
    int? mentorId,
    String? level,
    String? intensity,
    int? weekday,
    String? fromTime,
    String? toTime,
  }) async {
    final query = <String, dynamic>{
      if (mentorId != null && mentorId > 0) 'mentorId': mentorId,
      if (level != null && level.isNotEmpty) 'level': level,
      if (intensity != null && intensity.isNotEmpty) 'intensity': intensity,
      if (weekday != null && weekday >= 0 && weekday <= 6) 'weekday': weekday,
      if (fromTime != null && fromTime.isNotEmpty) 'fromTime': fromTime,
      if (toTime != null && toTime.isNotEmpty) 'toTime': toTime,
    };
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/cohorts',
      queryParameters: query.isEmpty ? null : query,
    );
    return _asList(res.data).map(CohortJson.cohort).toList();
  }

  @override
  Future<MentorCohortReviewSummary> fetchMentorReviewSummary(
    int mentorId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/mentors/$mentorId/cohort-review-summary',
    );
    return CohortJson.reviewSummary(_asMap(res.data), mentorId: mentorId);
  }

  @override
  Future<CohortCompletionSummary> fetchCompletionSummary(int courseId) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/$courseId/completion-summary',
    );
    return CohortJson.completion(_asMap(res.data));
  }

  @override
  Future<List<CohortMentorReview>> fetchCourseMentorReviews(
    int courseId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/$courseId/mentor-reviews',
    );
    return _asList(res.data).map(CohortJson.review).toList();
  }

  @override
  Future<CohortMentorReview?> submitMentorReview({
    required int courseId,
    required int mentorId,
    required int rating,
    required String comment,
  }) async {
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/mentor-reviews',
      data: {
        'mentorId': mentorId,
        'rating': rating,
        'comment': comment.trim(),
      },
    );
    final map = _asMap(res.data);
    return map.isEmpty ? null : CohortJson.review(map);
  }

  @override
  Future<CohortMentorReview?> updateMentorReview({
    required int courseId,
    required int reviewId,
    required int mentorId,
    required int rating,
    required String comment,
  }) async {
    final res = await _apiClient.put<Object?>(
      '/api/study-courses/$courseId/mentor-reviews/$reviewId',
      data: {
        'mentorId': mentorId,
        'rating': rating,
        'comment': comment.trim(),
      },
    );
    final map = _asMap(res.data);
    return map.isEmpty ? null : CohortJson.review(map);
  }

  @override
  Future<List<CohortComplaint>> fetchMyComplaints({String? status}) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/complaints',
      queryParameters: status == null || status.isEmpty
          ? null
          : {'status': status},
    );
    return _asList(res.data).map(CohortJson.complaint).toList();
  }

  @override
  Future<CohortComplaint?> submitComplaint({
    required int courseId,
    required String category,
    required String message,
    int? mentorId,
    bool refundReviewRequested = false,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    final isPayment = category == CohortComplaintCategory.paymentEnrollment;
    final form = FormData.fromMap({
      'category': category,
      'message': message.trim(),
      'idempotencyKey': idempotencyKey,
      if (mentorId != null && mentorId > 0) 'mentorId': mentorId.toString(),
      // Refund review only exists for payment/enrollment complaints.
      if (isPayment) 'refundReviewRequested': refundReviewRequested.toString(),
      if (evidenceBytes != null &&
          evidenceFileName != null &&
          evidenceContentType != null)
        'evidence': MultipartFile.fromBytes(
          evidenceBytes,
          filename: evidenceFileName,
          contentType: DioMediaType.parse(evidenceContentType),
        ),
    });
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/complaints',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    final map = _asMap(res.data);
    return map.isEmpty ? null : CohortJson.complaint(map);
  }

  @override
  Future<List<CohortEntitlementItem>> fetchMyEntitlements() async {
    final res = await _apiClient.get<Object?>('/api/study-courses/my-entitlements');
    return _asList(res.data).map((j) {
      return CohortEntitlementItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        studyCohortId: (j['studyCohortId'] as num?)?.toInt() ?? 0,
        cohortName: j['cohortName']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        startsAt: _parseDate(j['startsAt']),
        entitlementReference: j['entitlementReference']?.toString() ?? '',
        sourceType: j['sourceType']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        isUsable: j['isUsable'] as bool? ?? false,
        note: j['note']?.toString(),
        grantedAtUtc: _optDate(j['grantedAtUtc']),
        expiresAtUtc: _optDate(j['expiresAtUtc']),
      );
    }).toList();
  }

  @override
  Future<int> enrollCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/cohorts/$cohortId/enroll',
      data: {
        'idempotencyKey': idempotencyKey,
        if (entitlementReference != null && entitlementReference.isNotEmpty)
          'entitlementReference': entitlementReference,
      },
    );
    final map = _asMap(res.data);
    return (map['id'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<CohortCheckoutResult> checkoutCohort({
    required int cohortId,
    required String idempotencyKey,
    String? entitlementReference,
  }) async {
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/cohorts/$cohortId/enroll',
      data: {
        'idempotencyKey': idempotencyKey,
        if (entitlementReference != null && entitlementReference.isNotEmpty)
          'entitlementReference': entitlementReference,
      },
    );
    final map = _asMap(res.data);
    final url = map['checkoutUrl']?.toString();
    return CohortCheckoutResult(
      courseId: (map['id'] as num?)?.toInt() ?? 0,
      cohortId: (map['cohortId'] as num?)?.toInt() ?? cohortId,
      checkoutUrl: (url == null || url.isEmpty) ? null : url,
      paymentStatus: map['paymentStatus']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      resumed: map['resumed'] as bool? ?? false,
    );
  }

  @override
  Future<void> reconcileCoursePayment(int courseId) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/payment/reconcile',
    );
  }

  @override
  Future<List<LearnerStudyCourseDetail>> fetchMyCourses() async {
    final res = await _apiClient.get<Object?>('/api/study-courses');
    return _asList(res.data).map((j) {
      final eligMap = _asMap(j['eligibility']);
      final rawReasons = eligMap['reasons'];
      final reasons = rawReasons is List
          ? rawReasons.map((e) => e.toString()).toList()
          : const <String>[];

      final rawSessions = j['sessions'];
      final sessions = (rawSessions is List ? rawSessions : const [])
          .whereType<Map>()
          .map((s) => s.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (s) => CourseSessionItem(
              id: (s['id'] as num?)?.toInt() ?? 0,
              number: (s['number'] as num?)?.toInt() ?? 0,
              attempt: (s['attempt'] as num?)?.toInt() ?? 1,
              scheduledAt: _parseDate(s['scheduledAt']),
              status: s['status']?.toString() ?? '',
              note: s['note']?.toString(),
              meetingUrl: s['meetingUrl']?.toString(),
              confirmedAt: _optDate(s['confirmedAt']),
            ),
          )
          .toList();

      final rawReqs = j['requests'];
      final reqs = (rawReqs is List ? rawReqs : const [])
          .whereType<Map>()
          .map((r) => r.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (r) => CourseRetakeRequestItem(
              id: (r['id'] as num?)?.toInt() ?? 0,
              status: r['status']?.toString() ?? '',
              examDate: _parseDate(r['examDate']),
              resultPublishedAt: _parseDate(r['resultPublishedAt']),
              reason: r['reason']?.toString() ?? '',
              submittedAt: _parseDate(r['submittedAt']),
              reviewedAt: _optDate(r['reviewedAt']),
              response: r['response']?.toString(),
              mentorSupportPlan: r['mentorSupportPlan']?.toString(),
              mentorSupportPlanAtUtc: _optDate(r['mentorSupportPlanAtUtc']),
            ),
          )
          .toList();

      return LearnerStudyCourseDetail(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        planId: (j['planId'] as num?)?.toInt() ?? 0,
        cohortId: (j['cohortId'] as num?)?.toInt(),
        sessionType: j['sessionType']?.toString() ?? 'Group',
        level: j['level']?.toString() ?? '',
        mentorId: (j['mentorId'] as num?)?.toInt(),
        mentorName: j['mentorName']?.toString() ?? '',
        durationMonths: (j['durationMonths'] as num?)?.toInt() ?? 0,
        sessionsPerWeek: (j['sessionsPerWeek'] as num?)?.toInt() ?? 0,
        totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
        sessionMinutes: (j['sessionMinutes'] as num?)?.toInt() ?? 0,
        amount: (j['amount'] as num?) ?? 0,
        paymentStatus: j['paymentStatus']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        startsAt: _optDate(j['startsAt']),
        endsAt: _optDate(j['endsAt']),
        completedAt: _optDate(j['completedAt']),
        eligibility: CourseEligibilitySummary(
          canClaim: eligMap['canClaim'] as bool? ?? false,
          passedOnTimeHomework:
              (eligMap['passedOnTimeHomework'] as num?)?.toInt() ?? 0,
          requiredHomework: (eligMap['requiredHomework'] as num?)?.toInt() ?? 0,
          absentSessions: (eligMap['absentSessions'] as num?)?.toInt() ?? 0,
          countedSessions: (eligMap['countedSessions'] as num?)?.toInt() ?? 0,
          reasons: reasons,
        ),
        sessions: sessions,
        requests: reqs,
        paymentState: j['paymentState']?.toString() ?? '',
        checkoutUrl: j['checkoutUrl']?.toString(),
        paymentExpiresAt: _optDate(j['paymentExpiresAt']),
        paymentConfirmedAtUtc: _optDate(j['paymentConfirmedAtUtc']),
      );
    }).toList();
  }

  @override
  Future<void> cancelCohortEnrollment({
    required int courseId,
    String? reason,
  }) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/cancel-enrollment',
      data: {'reason': reason?.trim().isEmpty == true ? null : reason?.trim()},
    );
  }

  @override
  Future<List<CohortHomeworkAssignment>> fetchCohortHomework(
    int cohortId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/homework',
      queryParameters: {'cohortId': cohortId},
    );
    return _asList(res.data).map((j) {
      final subMap = j['submission'] is Map ? _asMap(j['submission']) : null;
      final gradeMap =
          j['publishedGrade'] is Map ? _asMap(j['publishedGrade']) : null;
      return CohortHomeworkAssignment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        instructions: j['instructions']?.toString(),
        assignedAt: _optDate(j['assignedAt']),
        dueAt: _optDate(j['dueAt']),
        status: j['status']?.toString() ?? 'Assigned',
        assignmentScope: j['assignmentScope']?.toString() ?? 'CohortCommon',
        cohortId: (j['cohortId'] as num?)?.toInt(),
        submission: subMap == null
            ? null
            : CohortHomeworkSubmission(
                id: (subMap['id'] as num?)?.toInt() ?? 0,
                textContent: subMap['textContent']?.toString(),
                submittedAt: _parseDate(subMap['submittedAt']),
                revisionCount: (subMap['revisionCount'] as num?)?.toInt() ?? 1,
                lastRevisedAtUtc: _optDate(subMap['lastRevisedAtUtc']),
                hasScan: subMap['hasScan'] as bool? ?? false,
              ),
        publishedGrade: gradeMap == null
            ? null
            : CohortHomeworkPublishedGrade(
                passed: gradeMap['passed'] as bool?,
                score: (gradeMap['score'] as num?)?.toDouble(),
                feedback: gradeMap['feedback']?.toString() ?? '',
                publishedAtUtc: _parseDate(gradeMap['publishedAtUtc']),
              ),
      );
    }).toList();
  }

  @override
  Future<void> submitHomeworkText({
    required int assignmentId,
    required String textContent,
  }) async {
    await _apiClient.post<Object?>(
      '/api/homework/$assignmentId/submit',
      data: {'textContent': textContent.trim(), 'fileUrl': null},
    );
  }

  @override
  Future<void> submitHomeworkScan({
    required int assignmentId,
    String? textContent,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final form = FormData.fromMap({
      if (textContent != null && textContent.trim().isNotEmpty)
        'textContent': textContent.trim(),
      'scan': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    await _apiClient.post<Object?>(
      '/api/homework/$assignmentId/submit-scan',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  @override
  Future<void> requestJlptRetake({
    required int courseId,
    required DateTime examDate,
    required DateTime resultPublishedAt,
    required String reason,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    final form = FormData.fromMap({
      'examDate': examDate.toUtc().toIso8601String(),
      'resultPublishedAt': resultPublishedAt.toUtc().toIso8601String(),
      'reason': reason.trim(),
      if (evidenceBytes != null &&
          evidenceFileName != null &&
          evidenceContentType != null)
        'evidence': MultipartFile.fromBytes(
          evidenceBytes,
          filename: evidenceFileName,
          contentType: DioMediaType.parse(evidenceContentType),
        ),
    });
    await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/retake',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  static CohortTransferRequestItem _transferFromJson(Map<String, Object?> j) {
    final rawHistory = j['history'];
    return CohortTransferRequestItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      status: j['status']?.toString() ?? '',
      sourceCourseId: (j['sourceCourseId'] as num?)?.toInt() ?? 0,
      sourceCohortId: (j['sourceCohortId'] as num?)?.toInt() ?? 0,
      sourceCohortName: j['sourceCohortName']?.toString(),
      requestedTargetCohortId: (j['requestedTargetCohortId'] as num?)?.toInt(),
      requestedTargetCohortName: j['requestedTargetCohortName']?.toString(),
      targetCohortId: (j['targetCohortId'] as num?)?.toInt(),
      targetCohortName: j['targetCohortName']?.toString(),
      reason: j['reason']?.toString() ?? '',
      hasEvidence: j['hasEvidence'] as bool? ?? false,
      createdAtUtc: _parseDate(j['createdAtUtc']),
      reviewedAtUtc: _optDate(j['reviewedAtUtc']),
      decisionNote: j['decisionNote']?.toString(),
      destinationCourseId: (j['destinationCourseId'] as num?)?.toInt(),
      history: (rawHistory is List ? rawHistory : const [])
          .whereType<Map>()
          .map((h) => h.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (h) => CohortTransferHistoryItem(
              action: h['action']?.toString() ?? '',
              actorRole: h['actorRole']?.toString() ?? '',
              detail: h['detail']?.toString() ?? '',
              atUtc: _parseDate(h['atUtc']),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<CohortTransferRequestItem>> fetchMyTransferRequests() async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/transfer-requests',
    );
    return _asList(res.data).map(_transferFromJson).toList();
  }

  @override
  Future<CohortTransferRequestItem> requestCohortTransfer({
    required int courseId,
    int? targetCohortId,
    required String reason,
    required String idempotencyKey,
    Uint8List? evidenceBytes,
    String? evidenceFileName,
    String? evidenceContentType,
  }) async {
    final form = FormData.fromMap({
      'idempotencyKey': idempotencyKey,
      'reason': reason.trim(),
      if (targetCohortId != null) 'targetCohortId': targetCohortId.toString(),
      if (evidenceBytes != null &&
          evidenceFileName != null &&
          evidenceContentType != null)
        'evidence': MultipartFile.fromBytes(
          evidenceBytes,
          filename: evidenceFileName,
          contentType: DioMediaType.parse(evidenceContentType),
        ),
    });
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/transfer-requests',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return _transferFromJson(_asMap(res.data));
  }

  @override
  Future<void> withdrawCohortTransfer(int requestId) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/transfer-requests/$requestId/withdraw',
    );
  }
}
