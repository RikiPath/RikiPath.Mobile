import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_json.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';

/// Mentor-facing cohort operations. The backend scopes every call to the
/// authenticated Mentor (assigned cohorts, own roster, complaints targeting
/// them); the client never filters by another Mentor's id.
abstract interface class MentorCohortRepository {
  Future<List<StudyCohortSummary>> fetchAssignedCohorts();
  Future<List<MentorCohortRosterEntry>> fetchRoster(int cohortId);
  Future<List<MentorCohortHomeworkItem>> fetchCohortHomework(int cohortId);
  Future<List<HomeworkCatalogItem>> fetchHomeworkCatalog({
    String? level,
    String? search,
  });
  Future<void> createCohortHomework({
    required int cohortId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<int> lessonIds = const [],
    List<int> practiceExerciseIds = const [],
    List<int>? targetLearnerIds,
  });
  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  );
  Future<MentorHomeworkAiDraft> generateHomeworkAiDraft(int assignmentId);
  Future<void> publishHomeworkGrade({
    required int assignmentId,
    required int submissionId,
    required double score,
    required String feedback,
  });
  Future<void> confirmSessionAttendance({
    required int courseId,
    required int sessionId,
    required String status,
    required String note,
  });
  Future<void> saveRetakeSupportPlan({
    required int courseId,
    required int requestId,
    required String supportPlan,
  });
  Future<MentorLearnerSkillProfile> fetchLearnerSkillProfile({
    required int learnerId,
    required int cohortId,
  });
  Future<List<CohortMentorAssignment>> fetchMentorAssignments(int cohortId);
  Future<List<CohortComplaint>> fetchComplaints({String? status});
  Future<void> respondToComplaint({
    required int complaintId,
    required String response,
  });
  Future<CohortShiftPreview> fetchShiftPreview({
    required int cohortId,
    int weeks = 1,
  });
  Future<List<CohortScheduleRequest>> fetchScheduleRequests(int cohortId);
  Future<CohortScheduleRequest?> createScheduleRequest({
    required int cohortId,
    required String kind,
    int? shiftWeeks,
    required String reason,
    required String idempotencyKey,
  });
  Future<void> withdrawScheduleRequest(int requestId);
}

final mentorCohortRepositoryProvider = Provider<MentorCohortRepository>((ref) {
  return ApiMentorCohortRepository(ref.watch(apiClientProvider));
});

class ApiMentorCohortRepository implements MentorCohortRepository {
  const ApiMentorCohortRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<StudyCohortSummary>> fetchAssignedCohorts() async {
    final res = await _apiClient.get<Object?>('/api/study-courses/cohorts');
    return CohortJson.list(res.data).map(CohortJson.cohort).toList();
  }

  @override
  Future<List<MentorCohortRosterEntry>> fetchRoster(int cohortId) async {
    final res = await _apiClient.get<Object?>('/api/study-courses');
    return CohortJson.list(res.data)
        .where((j) {
          final id = CohortJson.optInt(j['cohortId']);
          return id == cohortId;
        })
        .map(CohortJson.rosterEntry)
        .toList();
  }

  @override
  Future<List<MentorCohortHomeworkItem>> fetchCohortHomework(
    int cohortId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/homework',
      queryParameters: {'cohortId': cohortId},
    );
    return CohortJson.homeworkList(res.data);
  }

  @override
  Future<List<HomeworkCatalogItem>> fetchHomeworkCatalog({
    String? level,
    String? search,
  }) async {
    final res = await _apiClient.get<Object?>(
      '/api/homework/catalog',
      queryParameters: {
        if (level != null && level.isNotEmpty) 'level': level,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return CohortJson.list(res.data)
        .map(
          (j) => HomeworkCatalogItem(
            type: CohortJson.str(j['type']),
            id: CohortJson.integer(j['id']),
            title: CohortJson.str(j['title']),
            level: CohortJson.str(j['level']),
            skill: CohortJson.str(j['skill']),
            questionCount: CohortJson.optInt(j['questionCount']),
          ),
        )
        .toList();
  }

  @override
  Future<void> createCohortHomework({
    required int cohortId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<int> lessonIds = const [],
    List<int> practiceExerciseIds = const [],
    List<int>? targetLearnerIds,
  }) async {
    await _apiClient.post<Object?>(
      '/api/homework/cohorts/$cohortId',
      data: {
        'cohortId': cohortId,
        'title': title.trim(),
        if (instructions != null && instructions.trim().isNotEmpty)
          'instructions': instructions.trim(),
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
        if (lessonIds.isNotEmpty) 'lessonIds': lessonIds,
        if (practiceExerciseIds.isNotEmpty)
          'practiceExerciseIds': practiceExerciseIds,
        if (targetLearnerIds != null && targetLearnerIds.isNotEmpty)
          'targetLearnerIds': targetLearnerIds,
      },
    );
  }

  @override
  Future<({Uint8List bytes, String contentType})> downloadHomeworkScan(
    int assignmentId,
  ) async {
    final res = await _apiClient.get<List<int>>(
      '/api/homework/$assignmentId/scan',
      options: Options(responseType: ResponseType.bytes),
    );
    final raw = res.data ?? const <int>[];
    final header =
        res.headers.value(Headers.contentTypeHeader) ?? 'application/octet-stream';
    return (
      bytes: Uint8List.fromList(raw),
      contentType: header.split(';').first.trim(),
    );
  }

  @override
  Future<MentorHomeworkAiDraft> generateHomeworkAiDraft(
    int assignmentId,
  ) async {
    final res = await _apiClient.post<Object?>(
      '/api/homework/$assignmentId/ai-draft',
    );
    final j = CohortJson.map(res.data);
    return MentorHomeworkAiDraft(
      suggestedScore: CohortJson.optDouble(j['score'] ?? j['suggestedScore']),
      feedback: CohortJson.optStr(j['feedback']),
      transcription: CohortJson.optStr(j['transcription']),
      generatedAtUtc: DateTime.now(),
    );
  }

  @override
  Future<void> publishHomeworkGrade({
    required int assignmentId,
    required int submissionId,
    required double score,
    required String feedback,
  }) async {
    await _apiClient.put<Object?>(
      '/api/homework/$assignmentId/grade',
      data: {
        'submissionId': submissionId,
        'score': score,
        'feedback': feedback.trim(),
      },
    );
  }

  @override
  Future<void> confirmSessionAttendance({
    required int courseId,
    required int sessionId,
    required String status,
    required String note,
  }) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/sessions/$sessionId/attendance',
      data: {
        'status': status,
        'note': note.trim(),
      },
    );
  }

  @override
  Future<void> saveRetakeSupportPlan({
    required int courseId,
    required int requestId,
    required String supportPlan,
  }) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/$courseId/retake/$requestId/support-plan',
      data: {'supportPlan': supportPlan.trim()},
    );
  }

  @override
  Future<MentorLearnerSkillProfile> fetchLearnerSkillProfile({
    required int learnerId,
    required int cohortId,
  }) async {
    final res = await _apiClient.get<Object?>(
      '/api/mentor/learners/$learnerId/skill-profile',
      queryParameters: {'cohortId': cohortId},
    );
    return CohortJson.skillProfile(CohortJson.map(res.data));
  }

  @override
  Future<List<CohortMentorAssignment>> fetchMentorAssignments(
    int cohortId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/cohorts/$cohortId/mentor-assignments',
    );
    return CohortJson.list(res.data).map(CohortJson.mentorAssignment).toList();
  }

  @override
  Future<List<CohortComplaint>> fetchComplaints({String? status}) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/complaints',
      queryParameters: status == null || status.isEmpty
          ? null
          : {'status': status},
    );
    return CohortJson.list(res.data).map(CohortJson.complaint).toList();
  }

  @override
  Future<void> respondToComplaint({
    required int complaintId,
    required String response,
  }) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/complaints/$complaintId/mentor-response',
      data: {'response': response.trim()},
    );
  }

  @override
  Future<CohortShiftPreview> fetchShiftPreview({
    required int cohortId,
    int weeks = 1,
  }) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/cohorts/$cohortId/shift-preview',
      queryParameters: {'weeks': weeks},
    );
    return CohortJson.shiftPreview(CohortJson.map(res.data));
  }

  @override
  Future<List<CohortScheduleRequest>> fetchScheduleRequests(
    int cohortId,
  ) async {
    final res = await _apiClient.get<Object?>(
      '/api/study-courses/cohorts/$cohortId/schedule-requests',
    );
    return CohortJson.list(res.data).map(CohortJson.scheduleRequest).toList();
  }

  @override
  Future<CohortScheduleRequest?> createScheduleRequest({
    required int cohortId,
    required String kind,
    int? shiftWeeks,
    required String reason,
    required String idempotencyKey,
  }) async {
    final res = await _apiClient.post<Object?>(
      '/api/study-courses/cohorts/$cohortId/schedule-requests',
      data: {
        'kind': kind,
        if (kind == CohortScheduleRequestKind.shiftWeeks && shiftWeeks != null)
          'shiftWeeks': shiftWeeks,
        'reason': reason.trim(),
        'idempotencyKey': idempotencyKey,
      },
    );
    final map = CohortJson.map(res.data);
    return map.isEmpty ? null : CohortJson.scheduleRequest(map);
  }

  @override
  Future<void> withdrawScheduleRequest(int requestId) async {
    await _apiClient.post<Object?>(
      '/api/study-courses/cohort-schedule-requests/$requestId/withdraw',
    );
  }
}
