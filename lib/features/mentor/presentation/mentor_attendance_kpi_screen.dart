import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_kpi_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';

class MentorAttendanceKpiScreen extends ConsumerStatefulWidget {
  const MentorAttendanceKpiScreen({super.key});

  @override
  ConsumerState<MentorAttendanceKpiScreen> createState() =>
      _MentorAttendanceKpiScreenState();
}

class _MentorAttendanceKpiScreenState
    extends ConsumerState<MentorAttendanceKpiScreen> {
  bool _showWeekly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = ref.watch(mentorKpiPresetProvider);
    final kpiAsync = ref.watch(mentorKpiSummaryProvider);

    return Scaffold(
      key: const Key('mentor_attendance_kpi_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Chấm công & KPI'),
      ),
      body: kpiAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: 'Chấm công & KPI',
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () => ref.invalidate(mentorKpiSummaryProvider),
            ),
          ),
        ),
        data: (summary) {
          final periods = _showWeekly
              ? summary.weeklyBreakdown
              : summary.monthlyBreakdown;

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () => ref.refresh(mentorKpiSummaryProvider.future),
            child: ListView(
              key: const Key('mentor_attendance_kpi_list'),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                _PresetSelector(
                  selected: preset,
                  onSelect: (next) =>
                      ref.read(mentorKpiPresetProvider.notifier).select(next),
                ),
                const SizedBox(height: AppSpacing.space3),
                if (summary.teachingJlptLevels.isNotEmpty) ...[
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    child: Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Phân quyền JLPT:',
                          style: AppTypography.metadata.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        ...summary.teachingJlptLevels.map(
                          (level) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              level,
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _KpiStatCard(
                        key: const Key('kpi_assigned_sessions'),
                        icon: Icons.calendar_today_outlined,
                        label: 'Buổi được giao',
                        value: '${summary.totalAssignedSessions}',
                        caption:
                            'Lớp nhóm: ${summary.assignedCourseSessionsCount} buổi',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: _KpiStatCard(
                        key: const Key('kpi_completed_sessions'),
                        icon: Icons.verified_outlined,
                        label: 'Hoàn thành hợp lệ',
                        value: '${summary.completedValidSessions}',
                        caption:
                            'Tỷ lệ ${formatKpiCompletionRate(summary.completedValidSessions, summary.totalAssignedSessions)}',
                        accentColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    Expanded(
                      child: _KpiStatCard(
                        key: const Key('kpi_confirmed_minutes'),
                        icon: Icons.timer_outlined,
                        label: 'Thời lượng xác nhận',
                        value: formatKpiMinutes(
                          summary.confirmedTeachingMinutes,
                        ),
                        caption:
                            'Kế hoạch đạt: ${formatKpiMinutes(summary.scheduledCompletedMinutes)}',
                        accentColor: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: _KpiStatCard(
                        key: const Key('kpi_cancelled_missed'),
                        icon: Icons.event_busy_outlined,
                        label: 'Hủy / Vắng / Chờ',
                        value:
                            '${summary.cancelledSessionsCount + summary.missedOrNoShowSessionsCount}',
                        caption:
                            'Hủy ${summary.cancelledSessionsCount} • Vắng ${summary.missedOrNoShowSessionsCount} • Chờ ${summary.upcomingOrIncompleteSessionsCount}',
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiCard(
                  backgroundColor: AppColors.cardWarmWhite,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bài tập & Phản hồi học viên',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _DetailRow(
                        label: 'Đã giao / Đã nộp',
                        value:
                            '${summary.homeworkAssignedCount} / ${summary.homeworkSubmittedCount}',
                      ),
                      _DetailRow(
                        label: 'Đã chấm & phản hồi',
                        value: '${summary.homeworkGradedCount}',
                      ),
                      _DetailRow(
                        key: const Key('kpi_turnaround_row'),
                        label: 'Thời gian phản hồi TB',
                        value:
                            summary.feedbackTurnaroundSampleCount > 0
                                ? '${formatKpiTurnaround(summary.averageFeedbackTurnaroundMinutes)} (${summary.feedbackTurnaroundSampleCount} mẫu)'
                                : formatKpiTurnaround(
                                    summary.averageFeedbackTurnaroundMinutes,
                                  ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiCard(
                  backgroundColor: AppColors.cardWarmWhite,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh giá & Khiếu nại',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      _DetailRow(
                        label: 'Đánh giá trung bình',
                        value: summary.averageRating != null
                            ? '${summary.averageRating} ★ (${summary.totalReviewsCount} lượt)'
                            : 'Chưa có đánh giá',
                      ),
                      _DetailRow(
                        label: 'Khiếu nại',
                        value:
                            '${summary.totalDisputesCount} (Đang xử lý: ${summary.openDisputesCount})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    Text(
                      'Thống kê theo chu kỳ',
                      style: AppTypography.cardTitle,
                    ),
                    SegmentedButton<bool>(
                      key: const Key('kpi_period_toggle'),
                      segments: const [
                        ButtonSegment<bool>(value: false, label: Text('Tháng')),
                        ButtonSegment<bool>(value: true, label: Text('Tuần')),
                      ],
                      selected: <bool>{_showWeekly},
                      onSelectionChanged: (values) {
                        setState(() => _showWeekly = values.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                if (periods.isEmpty)
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: const Text('Chưa có hoạt động giảng dạy trong kỳ.'),
                  )
                else
                  ...periods.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: RikiCard(
                        backgroundColor: AppColors.cardWarmWhite,
                        borderColor: AppColors.cardBorderMuted,
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.periodKey,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${p.completedValidSessions}/${p.totalAssignedSessions} buổi đạt',
                                  style: AppTypography.metadata.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Xác nhận: ${formatKpiMinutes(p.confirmedTeachingMinutes)} • BTVN chấm: ${p.homeworkGradedCount}/${p.homeworkSubmittedCount} • Hủy/Vắng: ${p.cancelledSessionsCount}/${p.missedOrNoShowSessionsCount}',
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Buổi dạy & điểm danh gần đây',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                if (summary.recentSessions.isEmpty)
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: const Text('Chưa có buổi dạy nào trong kỳ.'),
                  )
                else
                  ...summary.recentSessions.map((s) {
                    final dt = s.scheduledStartUtc != null
                        ? DateFormat('dd/MM HH:mm')
                            .format(s.scheduledStartUtc!.toLocal())
                        : '—';
                    final typeLabel = s.sourceType == 'StudyCourse'
                        ? 'Khóa học'
                        : 'Lớp nhóm';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: RikiCard(
                        backgroundColor: AppColors.cardWarmWhite,
                        borderColor: AppColors.cardBorderMuted,
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$typeLabel #${s.bookingOrSessionId} • ${s.learnerName ?? "Học viên"}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  s.status,
                                  style: AppTypography.metadata.copyWith(
                                    color: s.isValidCompleted
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dt${s.jlptLevel != null ? ' • JLPT ${s.jlptLevel}' : ''} • Xác nhận ${s.observedMentorMinutes}p / ${s.scheduledMinutes}p',
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.space3),
                RikiCard(
                  backgroundColor: AppColors.surfaceSubtle,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyên tắc thống kê',
                        style: AppTypography.metadata.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RikiPath ghi nhận chấm công, thời lượng giảng dạy và KPI thực tế để đảm bảo chất lượng học tập. Hệ thống không quản lý bảng lương hay chi trả thù lao.',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({required this.selected, required this.onSelect});

  final MentorKpiPreset selected;
  final ValueChanged<MentorKpiPreset> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      children: [
        ChoiceChip(
          label: const Text('Tháng này'),
          selected: selected == MentorKpiPreset.currentMonth,
          onSelected: (_) => onSelect(MentorKpiPreset.currentMonth),
        ),
        ChoiceChip(
          label: const Text('30 ngày'),
          selected: selected == MentorKpiPreset.last30Days,
          onSelected: (_) => onSelect(MentorKpiPreset.last30Days),
        ),
        ChoiceChip(
          label: const Text('3 tháng'),
          selected: selected == MentorKpiPreset.last90Days,
          onSelected: (_) => onSelect(MentorKpiPreset.last90Days),
        ),
      ],
    );
  }
}

class _KpiStatCard extends StatelessWidget {
  const _KpiStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.accentColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: accentColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.sectionTitle.copyWith(
              color: accentColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
