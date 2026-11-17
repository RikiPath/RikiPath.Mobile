import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

/// Learner-facing course summary: every Mentor who taught (including
/// substitutes), attendance, homework, published Mentor feedback.
///
/// This is an internal learning record only — it is never presented as a
/// certificate, and always says so explicitly.
class CohortCompletionSummaryCard extends StatelessWidget {
  const CohortCompletionSummaryCard({required this.summary, super.key});

  final CohortCompletionSummary summary;

  static const String certificateDisclaimer =
      'Bản tổng kết này chỉ ghi nhận quá trình học tại RikiPath, '
      'không phải chứng chỉ JLPT chính thức.';

  static String attendanceLabel(String status) => switch (status) {
    'Present' => 'Có mặt',
    'Late' => 'Đi muộn',
    'Absent' => 'Vắng',
    'Excused' => 'Vắng có phép',
    'Cancelled' => 'Đã hủy',
    'Upcoming' || 'Scheduled' || 'Pending' => 'Sắp diễn ra',
    'Completed' => 'Đã học',
    _ => status,
  };

  static Color _attendanceColor(String status) => switch (status) {
    'Present' || 'Completed' => AppColors.success,
    'Late' || 'Excused' => AppColors.warning,
    'Absent' => AppColors.error,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final note = s.note.trim();
    final showServerNote =
        note.isNotEmpty && !note.toLowerCase().contains('chứng chỉ jlpt');
    final labelStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );

    return RikiCard(
      key: const Key('cohort_completion_summary_card'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng kết khóa học',
                  style: AppTypography.cardTitle,
                ),
              ),
              MentorStatusBadge(
                label: s.isCompleted ? 'Đã hoàn thành' : 'Đang học',
                color: s.isCompleted ? AppColors.success : AppColors.info,
              ),
            ],
          ),
          if (s.intensityLabel.isNotEmpty || s.level.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (s.level.isNotEmpty) s.level,
                if (s.intensityLabel.isNotEmpty) 'Cường độ ${s.intensityLabel}',
              ].join(' · '),
              style: labelStyle,
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Text('Mentor đã giảng dạy', style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          )),
          if (s.mentors.isEmpty)
            Text('Chưa có buổi học nào được giảng dạy.', style: labelStyle)
          else
            for (final m in s.mentors)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    m.mentorName,
                    if (m.isPrimary) 'Mentor chính' else 'Mentor dạy thay',
                    if (m.sessionNumbers.isNotEmpty)
                      'Buổi ${m.sessionNumbers.join(', ')}',
                  ].join(' · '),
                  style: AppTypography.bodySmall,
                ),
              ),
          const SizedBox(height: AppSpacing.space3),
          Text('Chuyên cần', style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          )),
          Text(
            'Đã học ${s.sessions.delivered}/${s.sessions.total} buổi · '
            'Vắng ${s.sessions.absent} · Hủy ${s.sessions.cancelled} · '
            'Sắp tới ${s.sessions.upcoming}',
            key: const Key('cohort_completion_sessions'),
            style: labelStyle,
          ),
          if (s.attendance.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in s.attendance)
                  Tooltip(
                    message: a.scheduledAt == null
                        ? attendanceLabel(a.status)
                        : '${DateFormat('dd/MM/yyyy HH:mm').format(a.scheduledAt!)} · ${attendanceLabel(a.status)}',
                    child: MentorStatusBadge(
                      label: 'B${a.number}: ${attendanceLabel(a.status)}',
                      color: _attendanceColor(a.status),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Text('Bài tập', style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          )),
          Text(
            'Được giao ${s.homework.assigned} · Đã nộp ${s.homework.submitted} · '
            'Đã chấm ${s.homework.graded} · Còn thiếu ${s.homework.outstanding}',
            key: const Key('cohort_completion_homework'),
            style: labelStyle,
          ),
          if (s.mentorFeedback.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Text('Nhận xét từ Mentor', style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            )),
            for (final f in s.mentorFeedback)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${f.title}${f.score != null ? ' (${f.score!.toStringAsFixed(f.score! % 1 == 0 ? 0 : 1)}/100)' : ''}: ${f.feedback}',
                  style: AppTypography.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Text(
            s.skillProgressAvailable
                ? 'Tiến bộ kỹ năng đã được Mentor cập nhật trong hồ sơ học tập.'
                : 'Chưa có dữ liệu tiến bộ kỹ năng cho khóa học này.',
            style: labelStyle,
          ),
          if (showServerNote) ...[
            const SizedBox(height: 6),
            Text(note, style: labelStyle),
          ],
          const SizedBox(height: AppSpacing.space3),
          Container(
            key: const Key('cohort_completion_disclaimer'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              border: Border.all(color: AppColors.warningBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warningText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    certificateDisclaimer,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warningText,
                      fontWeight: FontWeight.w600,
                    ),
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
