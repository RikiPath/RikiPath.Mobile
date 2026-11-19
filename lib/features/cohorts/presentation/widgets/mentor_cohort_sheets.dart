import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_binary_preview.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

final DateFormat _sheetDateTime = DateFormat('dd/MM/yyyy HH:mm');

/// Bottom sheet allowing the Mentor to confirm per-learner attendance for one
/// session of a cohort (`POST /api/study-courses/{id}/sessions/{sessionId}/attendance`).
class MentorSessionAttendanceSheet extends ConsumerStatefulWidget {
  const MentorSessionAttendanceSheet({
    required this.cohort,
    required this.slot,
    super.key,
  });

  final StudyCohortSummary cohort;
  final CohortSessionSlot slot;

  @override
  ConsumerState<MentorSessionAttendanceSheet> createState() =>
      _MentorSessionAttendanceSheetState();
}

class _MentorSessionAttendanceSheetState
    extends ConsumerState<MentorSessionAttendanceSheet> {
  final Map<int, String> _selectedStatus = {};
  final Map<int, TextEditingController> _noteControllers = {};
  final Set<int> _savingSessionIds = {};

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteFor(int sessionId, String? existingNote) {
    return _noteControllers.putIfAbsent(
      sessionId,
      () => TextEditingController(
        text: existingNote?.isNotEmpty == true
            ? existingNote
            : 'Xác nhận buổi ${widget.slot.number}',
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
    'Present' => 'Có mặt',
    'Absent' => 'Vắng không phép',
    'ExcusedAbsent' => 'Vắng có phép',
    'CancelledByMentor' => 'Mentor hủy buổi',
    'Scheduled' => 'Chờ điểm danh',
    final other => other,
  };

  static Color _statusColor(String status) => switch (status) {
    'Present' => AppColors.success,
    'Absent' || 'CancelledByMentor' => AppColors.error,
    'ExcusedAbsent' => AppColors.warningText,
    _ => AppColors.info,
  };

  Future<void> _confirm({
    required int courseId,
    required CourseSessionItem session,
  }) async {
    if (_savingSessionIds.contains(session.id)) return;
    final status = _selectedStatus[session.id] ?? 'Present';
    final note = _noteFor(session.id, session.note).text.trim();
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (note.isEmpty) {
      toasts.error(
        title: 'Thiếu ghi chú',
        description: 'Vui lòng nhập lý do hoặc ghi chú xác nhận buổi học.',
      );
      return;
    }

    setState(() => _savingSessionIds.add(session.id));
    try {
      await ref
          .read(mentorCohortActionsProvider)
          .confirmSessionAttendance(
            cohortId: widget.cohort.id,
            courseId: courseId,
            sessionId: session.id,
            status: status,
            note: note,
          );
      if (!mounted) return;
      toasts.success(title: 'Đã lưu điểm danh buổi ${session.number}');
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa lưu được điểm danh',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _savingSessionIds.remove(session.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(mentorCohortRosterProvider(widget.cohort.id));
    final slot = widget.slot;
    final rawMinutes = widget.cohort.sessionMinutes ?? 0;
    final sessionMinutes = rawMinutes > 0 ? rawMinutes : 90;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm danh · Buổi ${slot.number}', style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(
              '${_sheetDateTime.format(slot.startTime)} – ${DateFormat('HH:mm').format(slot.endTime)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.65,
              ),
              child: switch (rosterState) {
                AsyncLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                AsyncError(:final error) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RikiErrorBanner(
                      message: appErrorMessage(error, context.l10n),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(
                        mentorCohortRosterProvider(widget.cohort.id),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
                AsyncData(:final value) => value.isEmpty
                    ? Text(
                        'Chưa có học viên nào ghi danh trong lớp.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final learner in value)
                              _buildLearnerAttendanceRow(
                                context,
                                learner: learner,
                                sessionMinutes: sessionMinutes,
                              ),
                          ],
                        ),
                      ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnerAttendanceRow(
    BuildContext context, {
    required MentorCohortRosterEntry learner,
    required int sessionMinutes,
  }) {
    final matching = learner.sessions
        .where((s) => s.number == widget.slot.number)
        .toList();
    if (matching.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '${learner.learnerName.isEmpty ? 'Học viên #${learner.courseId}' : learner.learnerName}: Chưa có lịch buổi ${widget.slot.number}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final session in matching) ...[
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  learner.learnerName.isEmpty
                      ? 'Học viên #${learner.courseId}'
                      : learner.learnerName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MentorStatusBadge(
                label: _statusLabel(session.status),
                color: _statusColor(session.status),
              ),
            ],
          ),
          if (session.status != 'Scheduled') ...[
            if (session.note != null && session.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ghi chú: ${session.note}',
                  style: AppTypography.bodySmall,
                ),
              ),
            if (session.confirmedAt != null)
              Text(
                'Chốt lúc ${_sheetDateTime.format(session.confirmedAt!)}',
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ] else ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final code in const [
                  'Present',
                  'Absent',
                  'ExcusedAbsent',
                  'CancelledByMentor',
                ])
                  ChoiceChip(
                    key: ValueKey('att_${session.id}_$code'),
                    label: Text(_statusLabel(code)),
                    selected:
                        (_selectedStatus[session.id] ?? 'Present') == code,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        setState(() => _selectedStatus[session.id] = code),
                  ),
              ],
            ),
            if ((_selectedStatus[session.id] ?? 'Present') !=
                    'CancelledByMentor' &&
                session.scheduledAt
                    .add(Duration(minutes: sessionMinutes))
                    .isAfter(DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Lưu ý: Buổi học chưa kết thúc; chỉ xác nhận hoàn thành sau giờ kết thúc (trừ khi Mentor hủy buổi).',
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.warningText,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            TextField(
              key: ValueKey('att_note_${session.id}'),
              controller: _noteFor(session.id, session.note),
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / xác nhận (bắt buộc)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: ValueKey('att_submit_${session.id}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
                onPressed: _savingSessionIds.contains(session.id)
                    ? null
                    : () => _confirm(courseId: learner.courseId, session: session),
                child: Text(
                  _savingSessionIds.contains(session.id)
                      ? 'Đang lưu...'
                      : 'Xác nhận điểm danh',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Bottom sheet allowing the Mentor to assign homework to all learners in the
/// cohort or selected individuals, attaching catalog lessons & exercises.
class MentorCreateHomeworkSheet extends ConsumerStatefulWidget {
  const MentorCreateHomeworkSheet({required this.cohort, super.key});

  final StudyCohortSummary cohort;

  @override
  ConsumerState<MentorCreateHomeworkSheet> createState() =>
      _MentorCreateHomeworkSheetState();
}

class _MentorCreateHomeworkSheetState
    extends ConsumerState<MentorCreateHomeworkSheet> {
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime? _dueAt;
  bool _forAllCohort = true;
  final Set<int> _selectedLearnerIds = {};
  final Set<int> _selectedLessonIds = {};
  final Set<int> _selectedExerciseIds = {};
  bool _submitting = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (!mounted) return;
    final t = pickedTime ?? const TimeOfDay(hour: 23, minute: 59);
    setState(() {
      _dueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      toasts.error(title: 'Vui lòng nhập tiêu đề bài tập');
      return;
    }
    if (!_forAllCohort && _selectedLearnerIds.isEmpty) {
      toasts.error(title: 'Hãy chọn ít nhất 1 học viên nhận bài');
      return;
    }

    setState(() => _submitting = true);
    try {
      final instructions = _instructionsController.text.trim();
      await ref
          .read(mentorCohortActionsProvider)
          .createCohortHomework(
            cohortId: widget.cohort.id,
            title: title,
            instructions: instructions.isEmpty ? null : instructions,
            dueAt: _dueAt,
            lessonIds: _selectedLessonIds.toList(),
            practiceExerciseIds: _selectedExerciseIds.toList(),
            targetLearnerIds:
                _forAllCohort ? null : _selectedLearnerIds.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      toasts.success(title: 'Đã giao bài tập cho lớp');
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa giao được bài tập',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(mentorCohortRosterProvider(widget.cohort.id));
    final catalogArgs = (
      level: widget.cohort.level.isEmpty ? null : widget.cohort.level,
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
    );
    final catalogState = ref.watch(mentorHomeworkCatalogProvider(catalogArgs));

    final activeLearners = (rosterState.value ?? const <MentorCohortRosterEntry>[])
        .where((e) => e.learnerId != null && e.status == 'Active')
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            key: const Key('mentor_create_homework_sheet'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Giao bài tập · ${widget.cohort.name}',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('hw_scope_cohort'),
                      label: const Text('Giao chung cả lớp'),
                      selected: _forAllCohort,
                      onSelected: (_) => setState(() => _forAllCohort = true),
                    ),
                    ChoiceChip(
                      key: const Key('hw_scope_individual'),
                      label: const Text('Chọn học viên'),
                      selected: !_forAllCohort,
                      onSelected: (_) => setState(() => _forAllCohort = false),
                    ),
                  ],
                ),
                if (!_forAllCohort) ...[
                  const SizedBox(height: 8),
                  if (activeLearners.isEmpty)
                    Text(
                      'Chưa có học viên đang theo học để giao riêng.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final l in activeLearners)
                          FilterChip(
                            label: Text(
                              l.learnerName.isEmpty
                                  ? 'Học viên #${l.learnerId}'
                                  : l.learnerName,
                            ),
                            selected: _selectedLearnerIds.contains(l.learnerId),
                            onSelected: (checked) => setState(() {
                              if (checked) {
                                _selectedLearnerIds.add(l.learnerId!);
                              } else {
                                _selectedLearnerIds.remove(l.learnerId);
                              }
                            }),
                          ),
                      ],
                    ),
                ],
                const SizedBox(height: 10),
                TextField(
                  key: const Key('hw_title_field'),
                  controller: _titleController,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề bài tập *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('hw_instructions_field'),
                  controller: _instructionsController,
                  maxLines: 3,
                  maxLength: 10000,
                  decoration: const InputDecoration(
                    labelText: 'Hướng dẫn / yêu cầu bài làm',
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueAt == null
                            ? 'Hạn nộp: Mặc định (+7 ngày theo chính sách)'
                            : 'Hạn nộp: ${_sheetDateTime.format(_dueAt!)}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(_dueAt == null ? 'Chọn hạn' : 'Đổi hạn'),
                    ),
                    if (_dueAt != null)
                      IconButton(
                        tooltip: 'Xóa hạn tùy chọn',
                        onPressed: () => setState(() => _dueAt = null),
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Đính kèm bài học / bài tập hệ thống (tùy chọn)',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm bài học hoặc bài luyện tập...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                switch (catalogState) {
                  AsyncLoading() => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  AsyncError(:final error) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RikiErrorBanner(
                        message: appErrorMessage(error, context.l10n),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(
                          mentorHomeworkCatalogProvider(catalogArgs),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                  AsyncData(:final value) => value.isEmpty
                      ? Text(
                          'Không có mục học liệu khớp tìm kiếm.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (final item in value.take(12))
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: item.type == 'lesson'
                                    ? _selectedLessonIds.contains(item.id)
                                    : _selectedExerciseIds.contains(item.id),
                                title: Text(
                                  item.title,
                                  style: AppTypography.bodySmall,
                                ),
                                subtitle: Text(
                                  '${item.type == 'lesson' ? 'Bài học' : 'Bài luyện'} · ${item.level} · ${item.skill}'
                                  '${item.questionCount != null ? ' · ${item.questionCount} câu' : ''}',
                                  style: AppTypography.metadata.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                onChanged: (checked) => setState(() {
                                  final target = item.type == 'lesson'
                                      ? _selectedLessonIds
                                      : _selectedExerciseIds;
                                  if (checked == true) {
                                    target.add(item.id);
                                  } else {
                                    target.remove(item.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                },
                const SizedBox(height: 12),
                RikiPrimaryButton(
                  key: const Key('hw_create_submit'),
                  label: _submitting ? 'Đang giao bài...' : 'Xác nhận giao bài',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeRowDraft {
  _GradeRowDraft({double? initialScore, String? initialFeedback})
    : scoreController = TextEditingController(
        text: initialScore == null
            ? ''
            : initialScore.toStringAsFixed(initialScore % 1 == 0 ? 0 : 1),
      ),
      feedbackController = TextEditingController(text: initialFeedback ?? '');

  final TextEditingController scoreController;
  final TextEditingController feedbackController;
  bool dirty = false;
  bool aiLoading = false;
  bool publishing = false;
  String? aiNotice;
  String? ocrTranscription;

  void dispose() {
    scoreController.dispose();
    feedbackController.dispose();
  }
}

/// Bottom sheet showing each learner's submission in a cohort homework item,
/// binary scan preview, non-blocking AI/OCR draft generation, and canonical grade
/// publishing (`PUT /api/homework/{id}/grade`).
class MentorHomeworkGradingSheet extends ConsumerStatefulWidget {
  const MentorHomeworkGradingSheet({
    required this.cohortId,
    required this.initialItem,
    super.key,
  });

  final int cohortId;
  final MentorCohortHomeworkItem initialItem;

  @override
  ConsumerState<MentorHomeworkGradingSheet> createState() =>
      _MentorHomeworkGradingSheetState();
}

class _MentorHomeworkGradingSheetState
    extends ConsumerState<MentorHomeworkGradingSheet> {
  final Map<int, _GradeRowDraft> _drafts = {};

  @override
  void dispose() {
    for (final d in _drafts.values) {
      d.dispose();
    }
    super.dispose();
  }

  _GradeRowDraft _draftFor(MentorCohortHomeworkRow row) {
    final existing = _drafts[row.id];
    final seedScore =
        row.publishedGrade?.score ?? row.aiDraft?.suggestedScore;
    final seedFeedback =
        row.publishedGrade?.feedback ?? row.aiDraft?.feedback;
    if (existing != null) {
      if (!existing.dirty) {
        if (seedScore != null && existing.scoreController.text.isEmpty) {
          existing.scoreController.text = seedScore.toStringAsFixed(
            seedScore % 1 == 0 ? 0 : 1,
          );
        }
        if (seedFeedback != null &&
            seedFeedback.isNotEmpty &&
            existing.feedbackController.text.isEmpty) {
          existing.feedbackController.text = seedFeedback;
        }
      }
      return existing;
    }
    return _drafts[row.id] = _GradeRowDraft(
      initialScore: seedScore,
      initialFeedback: seedFeedback,
    );
  }

  MentorCohortHomeworkItem _resolveCurrentItem(
    List<MentorCohortHomeworkItem> list,
  ) {
    final targetKey = widget.initialItem.cohortAssignmentGroupKey;
    if (targetKey != null) {
      final match = list
          .where((e) => e.cohortAssignmentGroupKey == targetKey)
          .firstOrNull;
      if (match != null) return match;
    }
    return list.where((e) => e.id == widget.initialItem.id).firstOrNull ??
        widget.initialItem;
  }

  Future<void> _requestAiDraft(MentorCohortHomeworkRow row) async {
    final draft = _draftFor(row);
    if (draft.aiLoading) return;
    setState(() {
      draft.aiLoading = true;
      draft.aiNotice = null;
    });
    try {
      final ai = await ref
          .read(mentorCohortActionsProvider)
          .generateHomeworkAiDraft(row.id);
      if (!mounted) return;
      setState(() {
        if (ai.transcription != null && ai.transcription!.isNotEmpty) {
          draft.ocrTranscription = ai.transcription;
        }
        if (ai.suggestedScore != null) {
          draft.scoreController.text = ai.suggestedScore!.toStringAsFixed(
            ai.suggestedScore! % 1 == 0 ? 0 : 1,
          );
        }
        if (ai.feedback != null && ai.feedback!.isNotEmpty) {
          draft.feedbackController.text = ai.feedback!;
        }
        draft.dirty = true;
        draft.aiNotice = ai.unavailableReason ??
            'Đã tạo gợi ý AI. Vui lòng rà soát trước khi công bố.';
      });
    } catch (error) {
      if (!mounted) return;
      if (error is ApiError &&
          error.errorCode == 'HOMEWORK_AI_DRAFT_UNAVAILABLE') {
        ref.invalidate(mentorCohortHomeworkProvider(widget.cohortId));
      }
      setState(() {
        draft.aiNotice =
            '${appErrorMessage(error, context.l10n)} (Bạn vẫn có thể tự nhập điểm & nhận xét bên dưới)';
      });
    } finally {
      if (mounted) setState(() => draft.aiLoading = false);
    }
  }

  Future<void> _publishGrade(MentorCohortHomeworkRow row) async {
    final sub = row.submission;
    if (sub == null) return;
    final draft = _draftFor(row);
    if (draft.publishing) return;
    final toasts = ref.read(rikiToastServiceProvider.notifier);

    final score = double.tryParse(
      draft.scoreController.text.trim().replaceAll(',', '.'),
    );
    final feedback = draft.feedbackController.text.trim();
    if (score == null || score < 0 || score > 100) {
      toasts.error(title: 'Điểm phải nằm trong khoảng 0 đến 100');
      return;
    }
    if (feedback.isEmpty) {
      toasts.error(title: 'Vui lòng nhập nhận xét cho học viên');
      return;
    }

    setState(() => draft.publishing = true);
    try {
      await ref
          .read(mentorCohortActionsProvider)
          .publishHomeworkGrade(
            cohortId: widget.cohortId,
            assignmentId: row.id,
            submissionId: sub.id,
            score: score,
            feedback: feedback,
          );
      if (!mounted) return;
      draft.dirty = false;
      toasts.success(title: 'Đã công bố điểm cho ${row.learnerName}');
    } catch (error) {
      if (!mounted) return;
      if (error is ApiError &&
          error.errorCode == 'HOMEWORK_SUBMISSION_CHANGED') {
        ref.invalidate(mentorCohortHomeworkProvider(widget.cohortId));
        toasts.error(
          title: 'Học viên vừa nộp phiên bản mới',
          description:
              'Đã tải lại bài nộp mới nhất (nháp điểm và nhận xét của bạn vẫn được giữ nguyên).',
        );
      } else {
        toasts.error(
          title: 'Chưa công bố được điểm',
          description: appErrorMessage(error, context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => draft.publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorCohortHomeworkProvider(widget.cohortId));
    final item = state.when(
      data: _resolveCurrentItem,
      loading: () => widget.initialItem,
      error: (_, _) => widget.initialItem,
    );
    final rows = item.rows;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            key: const Key('mentor_homework_grading_sheet'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: AppTypography.cardTitle),
                if (item.instructions != null &&
                    item.instructions!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.instructions!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  Text(
                    'Chưa có danh sách bài nộp chi tiết cho bài tập này.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  for (final row in rows) _buildSubmissionRow(context, row),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionRow(
    BuildContext context,
    MentorCohortHomeworkRow row,
  ) {
    final draft = _draftFor(row);
    final sub = row.submission;

    return Container(
      key: ValueKey('hw_grade_row_${row.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.learnerName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MentorStatusBadge(
                label: switch (row.status) {
                  'Graded' => 'Đã chấm',
                  'Submitted' => 'Đã nộp',
                  _ => 'Chưa nộp',
                },
                color: switch (row.status) {
                  'Graded' => AppColors.success,
                  'Submitted' => AppColors.info,
                  _ => AppColors.textSecondary,
                },
              ),
            ],
          ),
          if (sub == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Học viên chưa nộp bài.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            Text(
              'Nộp lúc ${_sheetDateTime.format(sub.submittedAt)}'
              '${sub.revisionCount > 1 ? ' · Phiên bản ${sub.revisionCount}' : ''}',
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (sub.textContent != null && sub.textContent!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SelectableText(
                  sub.textContent!,
                  style: AppTypography.bodySmall,
                ),
              ),
            if (sub.hasScan)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: ValueKey('hw_view_scan_${row.id}'),
                  onPressed: () => showCohortBinaryAttachmentPreview(
                    context,
                    title: 'Bài scan · ${row.learnerName}',
                    loader: () => ref
                        .read(mentorCohortActionsProvider)
                        .downloadHomeworkScan(row.id),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Xem ảnh / PDF đã nộp'),
                ),
              ),
            if (draft.ocrTranscription != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'OCR trích xuất: ${draft.ocrTranscription}',
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (draft.aiNotice != null ||
                row.aiDraft?.unavailableReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  draft.aiNotice ?? row.aiDraft!.unavailableReason!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warningText,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('hw_score_${row.id}'),
              controller: draft.scoreController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => draft.dirty = true,
              decoration: const InputDecoration(
                labelText: 'Điểm (0 – 100)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('hw_feedback_${row.id}'),
              controller: draft.feedbackController,
              maxLines: 3,
              maxLength: 2000,
              onChanged: (_) => draft.dirty = true,
              decoration: const InputDecoration(
                labelText: 'Nhận xét công bố cho học viên',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('hw_ai_draft_${row.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: draft.aiLoading
                      ? null
                      : () => _requestAiDraft(row),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(
                    draft.aiLoading ? 'Đang tạo gợi ý...' : 'Gợi ý AI/OCR',
                  ),
                ),
                FilledButton.icon(
                  key: ValueKey('hw_publish_grade_${row.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                  onPressed: draft.publishing ? null : () => _publishGrade(row),
                  icon: const Icon(Icons.check_outlined, size: 18),
                  label: Text(
                    draft.publishing
                        ? 'Đang công bố...'
                        : (row.publishedGrade != null
                            ? 'Cập nhật điểm'
                            : 'Công bố điểm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
