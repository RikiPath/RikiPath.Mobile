import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/mentor_cohorts_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
final DateFormat _time = DateFormat('HH:mm');

/// Mentor view of one assigned cohort (`/mentor/cohorts/:cohortId`).
class MentorCohortDetailScreen extends ConsumerWidget {
  const MentorCohortDetailScreen({required this.cohortId, super.key});

  final int cohortId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortState = ref.watch(mentorCohortByIdProvider(cohortId));
    final hasRouter = GoRouter.maybeOf(context) != null;

    return Scaffold(
      key: const Key('mentor_cohort_detail_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: hasRouter
            ? BackButton(
                onPressed: () => popOrGo(context, AppRoutes.mentorCohorts),
              )
            : null,
        title: const Text('Chi tiết lớp nhóm'),
      ),
      body: SafeArea(
        top: false,
        child: switch (cohortState) {
          AsyncData(value: final cohort?) => RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () async {
              ref.read(mentorCohortActionsProvider).refreshCohort(cohortId);
              await ref.read(mentorCohortByIdProvider(cohortId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                _CohortHeaderCard(cohort: cohort),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Lịch buổi học'),
                _SessionScheduleCard(cohort: cohort),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Học viên trong lớp'),
                _RosterCard(cohortId: cohort.id),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Bài tập & chấm điểm'),
                _HomeworkCard(cohortId: cohort.id),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Lịch sử phân công Mentor chính'),
                _AssignmentHistoryCard(cohortId: cohort.id),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Khiếu nại liên quan đến bạn'),
                _ComplaintsCard(cohortId: cohort.id),
                const SizedBox(height: AppSpacing.space4),
                _SectionTitle('Yêu cầu dời lịch / hủy lớp trống'),
                _ScheduleRequestsCard(cohort: cohort),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
          AsyncData() => const Center(
            child: MentorEmptyState(
              icon: Icons.groups_outlined,
              title: 'Không tìm thấy lớp',
              description:
                  'Lớp này không còn nằm trong danh sách lớp được phân công cho bạn.',
            ),
          ),
          AsyncError(:final error) => Center(
            child: MentorErrorState(
              message: appErrorMessage(error, context.l10n),
              onRetry: () => ref.invalidate(mentorAssignedCohortsProvider),
            ),
          ),
          _ => const MentorListSkeleton(),
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Text(title, style: AppTypography.sectionTitle),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: child,
    );
  }
}

/// Inline async helper so each panel loads/fails independently.
Widget _asyncPanel<T>(
  BuildContext context,
  AsyncValue<T> state, {
  required Widget Function(T value) data,
  required VoidCallback onRetry,
}) {
  return switch (state) {
    AsyncData(:final value) => data(value),
    AsyncError(:final error) => Row(
      children: [
        Expanded(
          child: Text(
            appErrorMessage(error, context.l10n),
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
    _ => const LinearProgressIndicator(),
  };
}

TextStyle get _muted =>
    AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);

// ---------------------------------------------------------------------------
// Header & sessions
// ---------------------------------------------------------------------------

class _CohortHeaderCard extends StatelessWidget {
  const _CohortHeaderCard({required this.cohort});

  final StudyCohortSummary cohort;

  @override
  Widget build(BuildContext context) {
    final overview = MentorCohortOverview(cohort);
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              MentorStatusBadge(
                label: cohort.level,
                color: AppColors.brandPrimary,
              ),
              if (cohort.intensityLabel.isNotEmpty)
                MentorStatusBadge(
                  label: cohort.intensityLabel,
                  color: AppColors.info,
                ),
              MentorStatusBadge(
                label: MentorCohortsScreen.cohortStatusLabel(cohort.status),
                color: MentorCohortsScreen.cohortStatusColor(cohort.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(cohort.name, style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          if (cohort.schedulePattern.isNotEmpty)
            Text(
              'Lịch cố định: ${cohort.schedulePattern.map((p) => p.display).join(' · ')}',
              style: _muted,
            ),
          Text(
            [
              if (overview.sessionsPerWeek > 0)
                '${overview.sessionsPerWeek} buổi/tuần',
              if (cohort.totalSessions != null) '${cohort.totalSessions} buổi',
              if (cohort.sessionMinutes != null) '${cohort.sessionMinutes}p/buổi',
            ].join(' · '),
            style: _muted,
          ),
          Text(
            'Khai giảng ${_dateTime.format(cohort.startsAt)} · Kết thúc ${_dateTime.format(cohort.endsAt)}',
            style: _muted,
          ),
          const SizedBox(height: 4),
          Text(
            'Sĩ số: ${cohort.enrolledCount}/${cohort.capacity} học viên',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionScheduleCard extends StatelessWidget {
  const _SessionScheduleCard({required this.cohort});

  final StudyCohortSummary cohort;

  static (String, Color) _status(CohortSessionSlot s, DateTime now) {
    return switch (s.status) {
      'Completed' || 'Delivered' => ('Đã dạy', AppColors.success),
      'Cancelled' => ('Đã hủy', AppColors.error),
      'InProgress' => ('Đang diễn ra', AppColors.warning),
      'Scheduled' || 'Upcoming' => ('Sắp diễn ra', AppColors.info),
      '' when s.endTime.isBefore(now) => ('Đã qua', AppColors.textSecondary),
      '' => ('Sắp diễn ra', AppColors.info),
      final other => (other, AppColors.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [...cohort.sessions]
      ..sort((a, b) => a.number.compareTo(b.number));
    final now = DateTime.now();
    return _PanelCard(
      key: const Key('mentor_cohort_sessions'),
      child: sessions.isEmpty
          ? Text('Lớp chưa có lịch buổi học.', style: _muted)
          : Column(
              children: [
                for (final s in sessions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Buổi ${s.number} · ${formatCohortSessionTime(s.startTime)}–${_time.format(s.endTime)}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Builder(
                          builder: (_) {
                            final (label, color) = _status(s, now);
                            return MentorStatusBadge(
                              label: label,
                              color: color,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roster & skill profile
// ---------------------------------------------------------------------------

class _RosterCard extends ConsumerWidget {
  const _RosterCard({required this.cohortId});

  final int cohortId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCohortRosterProvider(cohortId));
    return _PanelCard(
      key: const Key('mentor_cohort_roster'),
      child: _asyncPanel<List<MentorCohortRosterEntry>>(
        context,
        state,
        onRetry: () => ref.invalidate(mentorCohortRosterProvider(cohortId)),
        data: (roster) => roster.isEmpty
            ? Text('Chưa có học viên ghi danh.', style: _muted)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${roster.length} học viên', style: _muted),
                  for (final learner in roster)
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            learner.learnerName.isEmpty
                                ? 'Học viên #${learner.courseId}'
                                : learner.learnerName,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        if (learner.learnerId != null)
                          TextButton(
                            key: ValueKey(
                              'mentor_skill_profile_${learner.learnerId}',
                            ),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => _SkillProfileSheet(
                                learnerId: learner.learnerId!,
                                learnerName: learner.learnerName,
                                cohortId: cohortId,
                              ),
                            ),
                            child: const Text('Hồ sơ kỹ năng'),
                          ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _SkillProfileSheet extends ConsumerWidget {
  const _SkillProfileSheet({
    required this.learnerId,
    required this.learnerName,
    required this.cohortId,
  });

  final int learnerId;
  final String learnerName;
  final int cohortId;

  static String _scalar(Object? v) => switch (v) {
    double d => d.toStringAsFixed(d % 1 == 0 ? 0 : 1),
    bool b => b ? 'Có' : 'Không',
    _ => v.toString(),
  };

  List<Widget> _render(Map<String, Object?> profile) {
    final rows = <Widget>[];
    final skills = profile['skills'] ?? profile['items'];
    if (skills is List) {
      for (final s in skills.whereType<Map>()) {
        final name = (s['skill'] ?? s['name'] ?? s['label'] ?? '').toString();
        final score = s['score'] ?? s['level'] ?? s['value'];
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(name, style: AppTypography.bodyMedium)),
                if (score != null)
                  MentorStatusBadge(
                    label: _scalar(score),
                    color: AppColors.brandPrimary,
                  ),
              ],
            ),
          ),
        );
      }
    }
    for (final e in profile.entries) {
      final v = e.value;
      if (v == null || v is Map || v is List) continue;
      if (e.key.toLowerCase().endsWith('id')) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('${e.key}: ${_scalar(v)}', style: _muted),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (learnerId: learnerId, cohortId: cohortId);
    final state = ref.watch(mentorLearnerSkillProfileProvider(args));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hồ sơ kỹ năng · ${learnerName.isEmpty ? 'Học viên' : learnerName}',
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 8),
            _asyncPanel<Map<String, Object?>>(
              context,
              state,
              onRetry: () =>
                  ref.invalidate(mentorLearnerSkillProfileProvider(args)),
              data: (profile) {
                final rows = _render(profile);
                if (rows.isEmpty) {
                  return Text(
                    'Chưa có dữ liệu kỹ năng cho học viên này.',
                    style: _muted,
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rows,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Homework & assignment history
// ---------------------------------------------------------------------------

class _HomeworkCard extends ConsumerWidget {
  const _HomeworkCard({required this.cohortId});

  final int cohortId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCohortHomeworkProvider(cohortId));
    return _PanelCard(
      key: const Key('mentor_cohort_homework'),
      child: _asyncPanel<List<MentorCohortHomeworkItem>>(
        context,
        state,
        onRetry: () => ref.invalidate(mentorCohortHomeworkProvider(cohortId)),
        data: (items) => items.isEmpty
            ? Text('Chưa giao bài tập cho lớp này.', style: _muted)
            : Column(
                children: [
                  for (final hw in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hw.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [
                                    hw.assignmentScope == 'CohortCommon'
                                        ? 'Giao chung'
                                        : 'Bài riêng',
                                    if (hw.dueAt != null)
                                      'Hạn ${_dateTime.format(hw.dueAt!)}',
                                  ].join(' · '),
                                  style: _muted,
                                ),
                              ],
                            ),
                          ),
                          MentorStatusBadge(
                            label: hw.progressLabel,
                            color: hw.status == 'Graded'
                                ? AppColors.success
                                : AppColors.info,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AssignmentHistoryCard extends ConsumerWidget {
  const _AssignmentHistoryCard({required this.cohortId});

  final int cohortId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCohortAssignmentsProvider(cohortId));
    return _PanelCard(
      key: const Key('mentor_cohort_assignments'),
      child: _asyncPanel<List<CohortMentorAssignment>>(
        context,
        state,
        onRetry: () =>
            ref.invalidate(mentorCohortAssignmentsProvider(cohortId)),
        data: (items) => items.isEmpty
            ? Text('Chưa có thay đổi phân công Mentor.', style: _muted)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.mentorName} · ${a.isPrimary ? 'Mentor chính' : 'Mentor dạy thay'}'
                            '${a.fromSessionNumber != null ? ' · từ buổi ${a.fromSessionNumber}' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (a.assignedAtUtc != null || a.reason != null)
                            Text(
                              [
                                if (a.assignedAtUtc != null)
                                  _dateTime.format(a.assignedAtUtc!),
                                if (a.reason != null) a.reason!,
                              ].join(' · '),
                              style: _muted,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Complaints targeting the Mentor
// ---------------------------------------------------------------------------

class _ComplaintsCard extends ConsumerWidget {
  const _ComplaintsCard({required this.cohortId});

  final int cohortId;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    CohortComplaint complaint,
  ) async {
    final controller = TextEditingController();
    final response = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phản hồi khiếu nại'),
        content: TextField(
          key: const Key('mentor_complaint_response_field'),
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Trình bày khách quan, lịch sự (Admin sẽ xem xét).',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (response == null || !context.mounted) return;
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (response.length < 5) {
      toasts.error(
        title: 'Phản hồi quá ngắn',
        description: 'Vui lòng nhập nội dung phản hồi rõ ràng.',
      );
      return;
    }
    try {
      await runWithAppLoadingOverlay<void>(
        context,
        title: 'Đang gửi phản hồi...',
        action: () => ref
            .read(mentorCohortActionsProvider)
            .respondToComplaint(complaintId: complaint.id, response: response),
      );
      toasts.success(title: 'Đã gửi phản hồi cho Admin');
    } catch (error) {
      if (!context.mounted) return;
      toasts.error(
        title: 'Chưa gửi được phản hồi',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCohortComplaintsProvider);
    return _PanelCard(
      key: const Key('mentor_cohort_complaints'),
      child: _asyncPanel<List<CohortComplaint>>(
        context,
        state,
        onRetry: () => ref.invalidate(mentorCohortComplaintsProvider),
        data: (all) {
          final items = all.where((c) => c.cohortId == cohortId).toList();
          if (items.isEmpty) {
            return Text('Không có khiếu nại nào trong lớp này.', style: _muted);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in items)
                Padding(
                  key: ValueKey('mentor_complaint_${c.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: [
                          MentorStatusBadge(
                            label: c.categoryLabel,
                            color: AppColors.brandPrimary,
                          ),
                          MentorStatusBadge(
                            label: c.statusLabel,
                            color: c.isTerminal
                                ? AppColors.textSecondary
                                : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.message, style: AppTypography.bodySmall),
                      if (c.hasMentorResponse)
                        Text(
                          'Phản hồi của bạn: ${c.mentorResponse}',
                          style: _muted,
                        ),
                      if (c.decision != null)
                        Text('Kết luận Admin: ${c.decision}', style: _muted),
                      if (c.category ==
                          CohortComplaintCategory.paymentEnrollment)
                        Text(
                          'Khiếu nại thanh toán/ghi danh do Admin xử lý trực tiếp.',
                          style: _muted,
                        )
                      else if (c.mentorCanRespond)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: ValueKey('mentor_complaint_respond_${c.id}'),
                            onPressed: () => _respond(context, ref, c),
                            icon: const Icon(Icons.reply_outlined, size: 18),
                            label: const Text('Phản hồi'),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule requests (shift weeks / cancel empty cohort)
// ---------------------------------------------------------------------------

class _ScheduleRequestsCard extends ConsumerWidget {
  const _ScheduleRequestsCard({required this.cohort});

  final StudyCohortSummary cohort;

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    CohortScheduleRequest request,
  ) async {
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    try {
      await ref
          .read(mentorCohortActionsProvider)
          .withdrawScheduleRequest(cohortId: cohort.id, requestId: request.id);
      toasts.success(title: 'Đã rút yêu cầu');
    } catch (error) {
      if (!context.mounted) return;
      toasts.error(
        title: 'Chưa rút được yêu cầu',
        description: appErrorMessage(error, context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorCohortScheduleRequestsProvider(cohort.id));
    final requests = state.value ?? const <CohortScheduleRequest>[];
    final hasPending = requests.any((r) => r.isPending);

    return _PanelCard(
      key: const Key('mentor_cohort_schedule_requests'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chỉ dời lịch hoặc hủy được khi lớp chưa bắt đầu; Admin sẽ duyệt mọi yêu cầu.',
            style: _muted,
          ),
          const SizedBox(height: 8),
          RikiSecondaryButton(
            key: const Key('mentor_schedule_request_open'),
            label: hasPending
                ? 'Đang có yêu cầu chờ duyệt'
                : 'Yêu cầu dời lịch / hủy lớp trống',
            onPressed: hasPending
                ? null
                : () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => MentorScheduleRequestSheet(cohort: cohort),
                  ),
          ),
          const SizedBox(height: 8),
          _asyncPanel<List<CohortScheduleRequest>>(
            context,
            state,
            onRetry: () => ref.invalidate(
              mentorCohortScheduleRequestsProvider(cohort.id),
            ),
            data: (items) => items.isEmpty
                ? Text('Chưa có yêu cầu nào.', style: _muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in items)
                        Padding(
                          key: ValueKey('mentor_schedule_request_${r.id}'),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.kindLabel,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  MentorStatusBadge(
                                    label: r.statusLabel,
                                    color: switch (r.status) {
                                      'Approved' => AppColors.success,
                                      'Rejected' => AppColors.error,
                                      'Pending' => AppColors.warning,
                                      _ => AppColors.textSecondary,
                                    },
                                  ),
                                ],
                              ),
                              Text('Lý do: ${r.reason}', style: _muted),
                              if (r.createdAtUtc != null)
                                Text(
                                  'Gửi lúc ${_dateTime.format(r.createdAtUtc!)}',
                                  style: _muted,
                                ),
                              if (r.decisionNote != null)
                                Text(
                                  'Ghi chú Admin: ${r.decisionNote}',
                                  style: AppTypography.bodySmall,
                                ),
                              for (final h in r.history)
                                Text(
                                  '• ${_dateTime.format(h.atUtc)} ${h.action}: ${h.detail}',
                                  style: AppTypography.metadata.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (r.isPending)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: ValueKey(
                                      'mentor_schedule_request_withdraw_${r.id}',
                                    ),
                                    onPressed: () => _withdraw(context, ref, r),
                                    child: const Text('Rút yêu cầu'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: pick "dời N tuần" (with server shift-preview: checks,
/// blockers, proposed sessions, conflicts) or "hủy lớp trống", give a reason,
/// submit an idempotent request for Admin approval.
class MentorScheduleRequestSheet extends ConsumerStatefulWidget {
  const MentorScheduleRequestSheet({required this.cohort, super.key});

  final StudyCohortSummary cohort;

  @override
  ConsumerState<MentorScheduleRequestSheet> createState() =>
      _MentorScheduleRequestSheetState();
}

class _MentorScheduleRequestSheetState
    extends ConsumerState<MentorScheduleRequestSheet> {
  final TextEditingController _reason = TextEditingController();
  String _kind = CohortScheduleRequestKind.shiftWeeks;
  int _weeks = 1;
  String? _idempotencyKey;
  bool _submitting = false;

  bool get _isShift => _kind == CohortScheduleRequestKind.shiftWeeks;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _draftChanged(VoidCallback change) {
    setState(() {
      change();
      _idempotencyKey = null;
    });
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    final toasts = ref.read(rikiToastServiceProvider.notifier);
    if (reason.length < 10) {
      toasts.error(
        title: 'Thiếu lý do',
        description: 'Vui lòng nhập lý do từ 10 ký tự để Admin xem xét.',
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    _idempotencyKey ??= generateClientIdempotencyKey();
    try {
      await ref
          .read(mentorCohortActionsProvider)
          .createScheduleRequest(
            cohortId: widget.cohort.id,
            kind: _kind,
            shiftWeeks: _isShift ? _weeks : null,
            reason: reason,
            idempotencyKey: _idempotencyKey!,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      toasts.success(
        title: 'Đã gửi yêu cầu',
        description: 'Admin sẽ xem xét và thông báo kết quả cho bạn.',
      );
    } catch (error) {
      if (!mounted) return;
      toasts.error(
        title: 'Chưa gửi được yêu cầu',
        description: appErrorMessage(error, context.l10n),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _preview() {
    final args = (cohortId: widget.cohort.id, weeks: _weeks);
    final state = ref.watch(mentorCohortShiftPreviewProvider(args));
    return _asyncPanel<CohortShiftPreview>(
      context,
      state,
      onRetry: () => ref.invalidate(mentorCohortShiftPreviewProvider(args)),
      data: (p) => Column(
        key: const Key('mentor_shift_preview'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MentorStatusBadge(
            label: p.eligible ? 'Đủ điều kiện dời lịch' : 'Chưa đủ điều kiện',
            color: p.eligible ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 6),
          for (final c in p.checks)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  c.passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 16,
                  color: c.passed ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.message, style: AppTypography.bodySmall),
                ),
              ],
            ),
          for (final b in p.blockers)
            Text(
              '• $b',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          for (final c in p.conflicts)
            Text(
              '• ${c.message}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningText,
              ),
            ),
          if (p.proposedSessions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Lịch mới dự kiến', style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            )),
            for (final s in p.proposedSessions.take(6))
              Text(
                'Buổi ${s.number}: ${s.startTime == null ? '—' : formatCohortSessionTime(s.startTime!)}'
                '${s.endTime == null ? '' : '–${_time.format(s.endTime!)}'}',
                style: _muted,
              ),
            if (p.proposedSessions.length > 6)
              Text(
                '… và ${p.proposedSessions.length - 6} buổi khác',
                style: _muted,
              ),
          ],
          if (p.newEnrollmentClosesAtUtc != null)
            Text(
              'Hạn ghi danh mới: ${_dateTime.format(p.newEnrollmentClosesAtUtc!)}',
              style: _muted,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cohort = widget.cohort;
    final previewEligible = !_isShift ||
        (ref
                .watch(
                  mentorCohortShiftPreviewProvider((
                    cohortId: cohort.id,
                    weeks: _weeks,
                  )),
                )
                .value
                ?.eligible ??
            false);
    final cancelBlocked = !_isShift && cohort.enrolledCount > 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('mentor_schedule_request_sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yêu cầu dời lịch / hủy lớp trống',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 4),
              Text(cohort.name, style: _muted),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final kind in [
                    CohortScheduleRequestKind.shiftWeeks,
                    CohortScheduleRequestKind.cancelEmptyCohort,
                  ])
                    ChoiceChip(
                      key: ValueKey('mentor_schedule_kind_$kind'),
                      label: Text(CohortScheduleRequestKind.label(kind)),
                      selected: _kind == kind,
                      onSelected: (_) => _draftChanged(() => _kind = kind),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isShift) ...[
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Dời', style: AppTypography.bodySmall),
                    for (final w in const [1, 2, 3, 4])
                      ChoiceChip(
                        key: ValueKey('mentor_schedule_weeks_$w'),
                        label: Text('$w tuần'),
                        selected: _weeks == w,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _draftChanged(() => _weeks = w),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _preview(),
              ] else
                Text(
                  cancelBlocked
                      ? 'Lớp đang có ${cohort.enrolledCount} học viên nên không thể hủy. Chỉ lớp chưa có học viên mới được hủy.'
                      : 'Lớp chưa có học viên ghi danh. Admin sẽ xác nhận trước khi hủy lớp.',
                  style: AppTypography.bodySmall.copyWith(
                    color: cancelBlocked
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('mentor_schedule_reason_field'),
                controller: _reason,
                maxLines: 3,
                maxLength: 1000,
                onChanged: (_) => _idempotencyKey = null,
                decoration: const InputDecoration(
                  labelText: 'Lý do (bắt buộc)',
                  border: OutlineInputBorder(),
                ),
              ),
              RikiPrimaryButton(
                key: const Key('mentor_schedule_request_submit'),
                label: 'Gửi Admin duyệt',
                onPressed: _submitting || !previewEligible || cancelBlocked
                    ? null
                    : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
