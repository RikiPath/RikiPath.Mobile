import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_complaint_section.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_completion_summary_card.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_mentor_review_section.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_payment_status_card.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_transfer_section.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class LearnerCohortDetailScreen extends ConsumerStatefulWidget {
  const LearnerCohortDetailScreen({required this.courseId, super.key});

  final int courseId;

  @override
  ConsumerState<LearnerCohortDetailScreen> createState() =>
      _LearnerCohortDetailScreenState();
}

class _LearnerCohortDetailScreenState
    extends ConsumerState<LearnerCohortDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final courses = ref.read(learnerMyCoursesProvider).value;
    final awaiting =
        courses?.any((c) => c.id == widget.courseId && c.isAwaitingPayment) ??
        false;
    if (awaiting) ref.invalidate(learnerMyCoursesProvider);
  }

  final Map<int, TextEditingController> _hwTextControllers = {};
  final Map<int, ({Uint8List bytes, String name, String mime})?> _hwScans = {};

  final TextEditingController _retakeReasonController = TextEditingController();
  DateTime _examDate = DateTime.now().subtract(const Duration(days: 14));
  DateTime _resultPublishedDate =
      DateTime.now().subtract(const Duration(days: 3));
  ({Uint8List bytes, String name, String mime})? _retakeEvidence;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _hwTextControllers.values) {
      c.dispose();
    }
    _retakeReasonController.dispose();
    super.dispose();
  }

  TextEditingController _hwControllerFor(CohortHomeworkAssignment hw) {
    return _hwTextControllers.putIfAbsent(
      hw.id,
      () => TextEditingController(text: hw.submission?.textContent ?? ''),
    );
  }

  static const int _maxUploadBytes = 10 * 1024 * 1024;
  bool _cancellingEnrollment = false;

  static String _courseStatusLabel(String status) => switch (status) {
    'Active' || 'Ready' => 'Đang học',
    'PendingPayment' => 'Chờ thanh toán',
    'Completed' => 'Đã hoàn thành',
    'Cancelled' => 'Đã hủy',
    'PaymentFailed' => 'Thanh toán thất bại',
    'PaymentExpired' => 'Hết hạn giữ chỗ',
    'PaymentReview' => 'Đang xem xét thanh toán',
    'Transferred' => 'Đã chuyển lớp',
    _ => status,
  };

  static String _sessionStatusLabel(String status) => switch (status) {
    'Scheduled' || 'Upcoming' => 'Sắp diễn ra',
    'InProgress' => 'Đang diễn ra',
    'Completed' => 'Đã học',
    'Present' => 'Có mặt',
    'Absent' => 'Vắng',
    'Late' => 'Đi muộn',
    'Excused' || 'ExcusedAbsent' => 'Vắng có phép',
    'Cancelled' || 'CancelledByMentor' => 'Đã hủy',
    _ => status,
  };

  static String _homeworkStatusLabel(String status) => switch (status) {
    'Assigned' => 'Đã giao',
    'Submitted' => 'Đã nộp',
    'Graded' => 'Đã chấm điểm',
    'Overdue' => 'Quá hạn',
    _ => status,
  };

  static String _retakeStatusLabel(String status) => switch (status) {
    'Pending' => 'Chờ Admin duyệt',
    'Approved' => 'Đã duyệt',
    'Rejected' => 'Bị từ chối',
    _ => status,
  };

  Future<({Uint8List bytes, String name, String mime})?> _pickDocument() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > _maxUploadBytes) {
      if (mounted) {
        ref.read(rikiToastServiceProvider.notifier).error(
          title: 'Tệp quá lớn',
          description: 'Tệp đính kèm tối đa 10MB (PDF/PNG/JPG).',
        );
      }
      return null;
    }
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    return (bytes: bytes, name: name, mime: mime);
  }

  Future<void> _previewBinaryAttachment({
    required String title,
    required Future<({Uint8List bytes, String contentType})> Function() loader,
  }) async {
    try {
      final file = await runWithAppLoadingOverlay(
        context,
        title: 'Đang tải tệp đính kèm...',
        action: loader,
      );
      if (!mounted) return;
      final isImage = file.contentType.startsWith('image/');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: isImage
              ? InteractiveViewer(
                  child: Image.memory(
                    file.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'Không thể hiển thị ảnh xem trước.',
                    ),
                  ),
                )
              : Text(
                  'Tệp ${file.contentType} (${(file.bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB) đã được tải an toàn từ máy chủ.',
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Không thể tải tệp',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  Future<void> _submitHomework(
    LearnerStudyCourseDetail course,
    CohortHomeworkAssignment hw,
  ) async {
    final cohortId = course.cohortId;
    if (cohortId == null) return;
    final text = _hwControllerFor(hw).text.trim();
    final scan = _hwScans[hw.id];
    if (text.isEmpty && scan == null) {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Thiếu nội dung bài nộp',
        description: 'Vui lòng nhập nội dung hoặc đính kèm ảnh/PDF bài làm.',
      );
      return;
    }

    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang nộp bài tập...',
        action: () {
          if (scan != null) {
            return ref
                .read(learnerMyCoursesProvider.notifier)
                .submitHomeworkScan(
                  cohortId: cohortId,
                  assignmentId: hw.id,
                  textContent: text,
                  bytes: scan.bytes,
                  fileName: scan.name,
                  contentType: scan.mime,
                );
          }
          return ref
              .read(learnerMyCoursesProvider.notifier)
              .submitHomeworkText(
                cohortId: cohortId,
                assignmentId: hw.id,
                textContent: text,
              );
        },
      );
      if (!mounted) return;
      setState(() => _hwScans.remove(hw.id));
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã lưu bài nộp thành công.');
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: 'Nộp bài chưa thành công',
            description: appErrorMessage(error, context.l10n),
          );
    }
  }

  Future<void> _submitRetake(LearnerStudyCourseDetail course) async {
    final reason = _retakeReasonController.text.trim();
    if (reason.isEmpty) {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: 'Thiếu tường trình',
        description: 'Vui lòng nhập lý do/tường trình kết quả thi JLPT chính thức.',
      );
      return;
    }

    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang gửi yêu cầu ôn lại JLPT...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .requestJlptRetake(
              courseId: course.id,
              examDate: _examDate,
              resultPublishedAt: _resultPublishedDate,
              reason: reason,
              evidenceBytes: _retakeEvidence?.bytes,
              evidenceFileName: _retakeEvidence?.name,
              evidenceContentType: _retakeEvidence?.mime,
            ),
      );
      if (!mounted) return;
      _retakeReasonController.clear();
      setState(() => _retakeEvidence = null);
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã gửi yêu cầu hỗ trợ JLPT lên Admin.');
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: 'Không thể gửi yêu cầu',
            description: appErrorMessage(error, context.l10n),
          );
    }
  }

  Future<void> _cancelEnrollment(LearnerStudyCourseDetail course) async {
    if (_cancellingEnrollment) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy ghi danh cá nhân'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          decoration: const InputDecoration(hintText: 'Lý do hủy (tùy chọn)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted || _cancellingEnrollment) return;

    _cancellingEnrollment = true;
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang hủy ghi danh cá nhân...',
        action: () => ref
            .read(learnerMyCoursesProvider.notifier)
            .cancelCohortEnrollment(courseId: course.id, reason: reason),
      );
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã hủy ghi danh cá nhân.');
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: 'Chưa thể hủy ghi danh',
            description: appErrorMessage(error, context.l10n),
          );
    } finally {
      _cancellingEnrollment = false;
    }
  }

  static const Set<String> _deliveredStatuses = {
    'Present',
    'Absent',
    'Late',
    'Excused',
    'Completed',
    'InProgress',
  };

  bool _courseHasStarted(LearnerStudyCourseDetail course) {
    final now = DateTime.now();
    final startsAt = course.startsAt;
    if (startsAt != null && !startsAt.isAfter(now)) return true;
    return course.sessions.any(
      (s) =>
          _deliveredStatuses.contains(s.status) || !s.scheduledAt.isAfter(now),
    );
  }

  List<({int id, String name})> _complaintMentors(
    LearnerStudyCourseDetail course,
    CohortCompletionSummary? summary,
  ) {
    final byId = <int, String>{
      if (course.mentorId != null && course.mentorName.isNotEmpty)
        course.mentorId!: course.mentorName,
      for (final m in summary?.mentors ?? const <CompletionMentorItem>[])
        if (m.mentorId > 0) m.mentorId: m.mentorName,
    };
    return [for (final e in byId.entries) (id: e.key, name: e.value)];
  }

  List<Widget> _buildCourseRecordSections(LearnerStudyCourseDetail course) {
    final summaryState = ref.watch(learnerCompletionSummaryProvider(course.id));
    final summary = summaryState.value;
    return [
      const SizedBox(height: AppSpacing.space4),
      Text('Tổng kết & phản hồi', style: AppTypography.sectionTitle),
      const SizedBox(height: AppSpacing.space2),
      switch (summaryState) {
        AsyncData(:final value) => CohortCompletionSummaryCard(summary: value),
        AsyncError(:final error) => Row(
          children: [
            Expanded(
              child: Text(
                appErrorMessage(
                  error,
                  context.l10n,
                  fallback: 'Chưa thể tải tổng kết khóa học.',
                ),
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(learnerCompletionSummaryProvider(course.id)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
        _ => const LinearProgressIndicator(),
      },
      if (summary != null) ...[
        const SizedBox(height: AppSpacing.space3),
        CohortMentorReviewSection(
          courseId: course.id,
          mentors: summary.reviewableMentors,
        ),
      ],
      const SizedBox(height: AppSpacing.space3),
      CohortComplaintSection(
        course: course,
        mentors: _complaintMentors(course, summary),
        pickEvidence: _pickDocument,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(learnerMyCoursesProvider);

    return Scaffold(
      key: const Key('learner_cohort_detail_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Chi tiết lớp học')),
      body: SafeArea(
        top: false,
        child: switch (coursesState) {
          AsyncLoading() => const MentorListSkeleton(),
          AsyncError(:final error) => Center(
            child: MentorErrorState(
              message: appErrorMessage(error, context.l10n),
              onRetry: ref.read(learnerMyCoursesProvider.notifier).refresh,
            ),
          ),
          AsyncData(:final value) => Builder(
            builder: (context) {
              final course = value
                  .where((c) => c.id == widget.courseId)
                  .firstOrNull;
              if (course == null) {
                return const MentorEmptyState(
                  icon: Icons.school_outlined,
                  title: 'Không tìm thấy lớp học',
                  description: 'Lớp học này không còn khả dụng.',
                );
              }

              final cohortHwState = course.cohortId != null
                  ? ref.watch(learnerCohortHomeworkProvider(course.cohortId!))
                  : const AsyncData(<CohortHomeworkAssignment>[]);

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            MentorStatusBadge(
                              label: '${course.level} · ${course.sessionType}',
                              color: AppColors.brandPrimary,
                            ),
                            MentorStatusBadge(
                              label: _courseStatusLabel(course.status),
                              color: course.status == 'Active'
                                  ? AppColors.success
                                  : (course.status == 'Cancelled' ||
                                            course.status == 'PaymentFailed' ||
                                            course.status == 'PaymentExpired'
                                        ? AppColors.error
                                        : AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(course.name, style: AppTypography.sectionTitle),
                        Text(
                          'Mentor: ${course.mentorName}',
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          'BTVN đạt đúng hạn: ${course.eligibility.passedOnTimeHomework}/${course.eligibility.requiredHomework} · Vắng: ${course.eligibility.absentSessions}/${course.eligibility.countedSessions}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // Official rule: no self-cancel once the first
                        // session has started (server: 409
                        // COHORT_CANCELLATION_NOT_ALLOWED).
                        if (course.cohortId != null &&
                            course.status == 'Active' &&
                            !_courseHasStarted(course)) ...[
                          const SizedBox(height: 12),
                          RikiSecondaryButton(
                            label: 'Hủy ghi danh cá nhân',
                            onPressed: () => _cancelEnrollment(course),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (course.paymentState.isNotEmpty &&
                      course.paymentState != 'Confirmed') ...[
                    const SizedBox(height: AppSpacing.space4),
                    CohortPaymentStatusCard(course: course),
                  ],
                  if (course.cohortId != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    CohortTransferSection(course: course, pickEvidence: _pickDocument),
                  ],
                  const SizedBox(height: AppSpacing.space4),
                  Text('Lịch buổi học & Phòng học chung', style: AppTypography.sectionTitle),
                  const SizedBox(height: AppSpacing.space2),
                  for (final s in course.sessions) ...[
                    RikiCard(
                      backgroundColor: Colors.white,
                      borderColor: AppColors.cardBorderMuted,
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buổi ${s.number} · ${DateFormat('dd/MM/yyyy HH:mm').format(s.scheduledAt)}',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _sessionStatusLabel(s.status),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (s.roomId != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed: () => context.push(
                                AppRoutes.meetingRoom(s.roomId!),
                              ),
                              child: const Text('Vào phòng'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                  ],
                  if (course.cohortId != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text('Bài tập nhóm (chung & cá nhân)', style: AppTypography.sectionTitle),
                    const SizedBox(height: AppSpacing.space2),
                    switch (cohortHwState) {
                      AsyncLoading() => const LinearProgressIndicator(),
                      AsyncError(:final error) => Row(
                        children: [
                          Expanded(
                            child: Text(
                              appErrorMessage(error, context.l10n),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              learnerCohortHomeworkProvider(course.cohortId!),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                      AsyncData(value: final hwList) => hwList.isEmpty
                          ? const Text('Chưa có bài tập nhóm nào được giao.')
                          : Column(
                              children: [
                                for (final hw in hwList) ...[
                                  RikiCard(
                                    backgroundColor: Colors.white,
                                    borderColor: AppColors.cardBorderMuted,
                                    padding:
                                        const EdgeInsets.all(AppSpacing.space4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            MentorStatusBadge(
                                              label: hw.isCommon
                                                  ? 'Giao chung cả lớp'
                                                  : 'Bài riêng cá nhân',
                                              color: AppColors.brandPrimary,
                                            ),
                                            MentorStatusBadge(
                                              label: _homeworkStatusLabel(hw.status),
                                              color: hw.status == 'Graded'
                                                  ? AppColors.success
                                                  : AppColors.info,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          hw.title,
                                          style: AppTypography.cardTitle,
                                        ),
                                        if (hw.instructions != null)
                                          Text(
                                            hw.instructions!,
                                            style: AppTypography.bodySmall,
                                          ),
                                        if (hw.submission != null)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Đã nộp lần ${hw.submission!.revisionCount}${hw.submission!.hasScan ? " · Có tệp scan" : ""}',
                                                  style: AppTypography.metadata
                                                      .copyWith(
                                                        color: AppColors
                                                            .brandPrimary,
                                                      ),
                                                ),
                                              ),
                                              if (hw.submission!.hasScan)
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _previewBinaryAttachment(
                                                        title: hw.title,
                                                        loader: () => ref
                                                            .read(
                                                              learnerMyCoursesProvider
                                                                  .notifier,
                                                            )
                                                            .downloadHomeworkScan(
                                                              hw.id,
                                                            ),
                                                      ),
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Xem tệp đã nộp',
                                                  ),
                                                ),
                                            ],
                                          ),
                                        if (hw.publishedGrade != null)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.successBackground,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Nhận xét Mentor (${hw.publishedGrade!.passed == true ? "Đạt" : "Chưa đạt"}${hw.publishedGrade!.score != null ? " · ${hw.publishedGrade!.score}/100" : ""}): ${hw.publishedGrade!.feedback}',
                                              style: AppTypography.bodySmall,
                                            ),
                                          ),
                                        if (hw.status != 'Graded') ...[
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _hwControllerFor(hw),
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              labelText: 'Nội dung bài làm',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size(
                                                      0,
                                                      48,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    final picked =
                                                        await _pickDocument();
                                                    if (picked != null &&
                                                        mounted) {
                                                      setState(
                                                        () => _hwScans[hw.id] =
                                                            picked,
                                                      );
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.attach_file,
                                                  ),
                                                  label: Text(
                                                    _hwScans[hw.id]?.name ??
                                                        'Đính kèm ảnh/PDF',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    minimumSize: const Size(
                                                      0,
                                                      48,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _submitHomework(
                                                        course,
                                                        hw,
                                                      ),
                                                  child: Text(
                                                    hw.submission == null
                                                        ? 'Nộp bài'
                                                        : 'Cập nhật bài',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.space3),
                                ],
                              ],
                            ),
                    },
                  ],
                  const SizedBox(height: AppSpacing.space4),
                  Text('Hỗ trợ ôn lại JLPT chính thức', style: AppTypography.sectionTitle),
                  const SizedBox(height: AppSpacing.space2),
                  RikiCard(
                    backgroundColor: Colors.white,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.eligibility.reasons.isNotEmpty)
                          Text(
                            course.eligibility.reasons.join(' '),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (course.status == 'Completed' &&
                            !course.requests.any((r) => r.status == 'Pending')) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _examDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null && mounted) {
                                    setState(() => _examDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.event, size: 18),
                                label: Text(
                                  'Thi: ${DateFormat('dd/MM/yyyy').format(_examDate)}',
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _resultPublishedDate,
                                    firstDate: _examDate,
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null && mounted) {
                                    setState(
                                      () => _resultPublishedDate = picked,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.campaign_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'Công bố: ${DateFormat('dd/MM/yyyy').format(_resultPublishedDate)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _retakeReasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText:
                                  'Lý do / Tường trình kết quả thi JLPT (bắt buộc)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                onPressed: () async {
                                  final picked = await _pickDocument();
                                  if (picked != null && mounted) {
                                    setState(() => _retakeEvidence = picked);
                                  }
                                },
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _retakeEvidence?.name ??
                                      'Chọn minh chứng JLPT (PDF/PNG/JPG)',
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _submitRetake(course),
                                child: const Text('Gửi Admin xét duyệt'),
                              ),
                            ],
                          ),
                        ],
                        for (final r in course.requests) ...[
                          const Divider(height: 20),
                          Text(
                            'Yêu cầu #${r.id} · ${_retakeStatusLabel(r.status)}',
                            style: AppTypography.cardTitle,
                          ),
                          if (r.reason.isNotEmpty)
                            Text('Tường trình: ${r.reason}'),
                          if (r.response != null)
                            Text('Quyết định Admin: ${r.response!}'),
                          if (r.mentorSupportPlan != null)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.brandTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Lộ trình hỗ trợ từ Mentor: ${r.mentorSupportPlan!}',
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (course.cohortId != null)
                    ..._buildCourseRecordSections(course),
                ],
              );
            },
          ),
        },
      ),
    );
  }
}
