import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/cohorts/data/cohort_repository.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';

/// Lớp đang mở của một Mentor (dùng bộ lọc mentorId sẵn có của API Tìm lớp).
final mentorPublishedCohortsProvider = FutureProvider.autoDispose
    .family<List<StudyCohortSummary>, int>((ref, mentorId) async {
      final rows = await ref
          .watch(cohortRepositoryProvider)
          .fetchCohorts(mentorId: mentorId);
      return rows.where((c) => c.mentorId == mentorId).toList();
    });

/// Trạng thái ghi danh — tách biệt với cường độ học.
enum CohortEnrollmentAvailability { available, full, upcoming }

CohortEnrollmentAvailability cohortAvailabilityOf(StudyCohortSummary c) {
  if (c.seatsAvailable <= 0) return CohortEnrollmentAvailability.full;
  if (c.enrollmentOpen) return CohortEnrollmentAvailability.available;
  return CohortEnrollmentAvailability.upcoming;
}

/// Nhãn cường độ lấy từ trường Backend (intensityLabel + sessionsPerWeek).
String cohortIntensityText(StudyCohortSummary c) {
  final label = c.intensityLabel.isNotEmpty ? c.intensityLabel : 'Tùy chỉnh';
  final perWeek = (c.sessionsPerWeek ?? 0) > 0
      ? ' · ${c.sessionsPerWeek} buổi/tuần'
      : '';
  return 'Cường độ: $label$perWeek';
}

String _hours(num h) =>
    '${h == h.roundToDouble() ? h.toInt() : h.toStringAsFixed(1)} giờ';

Color _intensityColor(String intensity) => switch (intensity) {
  'Light' => AppColors.info,
  'Standard' => AppColors.brandPrimary,
  'Advanced' => const Color(0xFF6A3FA0),
  _ => AppColors.textSecondary,
};

/// Phần nội dung thẻ lớp dùng chung (Tìm lớp, hồ sơ Mentor): cường độ hiển thị ngay,
/// cấp JLPT, Mentor, lịch hằng tuần, 90 phút/buổi, tổng buổi, số tuần, chỗ trống, học phí trọn khóa.
class CohortSummaryFacts extends StatelessWidget {
  const CohortSummaryFacts({required this.cohort, this.reviewLine, super.key});

  final StudyCohortSummary cohort;
  final Widget? reviewLine;

  @override
  Widget build(BuildContext context) {
    final c = cohort;
    final availability = cohortAvailabilityOf(c);
    final totalSessions = c.totalSessions ?? c.sessions.length;
    final weeks = (c.sessionsPerWeek ?? 0) > 0
        ? (totalSessions / c.sessionsPerWeek!).round()
        : null;
    final schedule = c.schedulePattern.isNotEmpty
        ? c.schedulePattern.map((p) => p.display).join(' · ')
        : 'Chưa có lịch cụ thể';
    final price = NumberFormat.decimalPattern('vi_VN').format(c.price);
    final date = DateFormat('dd/MM/yyyy HH:mm');
    final meta = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );

    Widget fact(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: meta),
            TextSpan(
              text: value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            MentorStatusBadge(
              key: ValueKey('cohort_intensity_${c.id}'),
              label: cohortIntensityText(c),
              icon: Icons.speed_rounded,
              color: _intensityColor(c.intensity),
            ),
            if (c.isRecommendedIntensity)
              MentorStatusBadge(
                key: ValueKey('cohort_recommended_${c.id}'),
                label: 'Đề xuất',
                icon: Icons.thumb_up_alt_outlined,
                color: AppColors.warning,
              ),
            MentorStatusBadge(
              key: ValueKey('cohort_status_${c.id}'),
              label: switch (availability) {
                CohortEnrollmentAvailability.available => 'Còn chỗ',
                CohortEnrollmentAvailability.full => 'Đã đủ chỗ',
                CohortEnrollmentAvailability.upcoming => 'Sắp mở',
              },
              color: switch (availability) {
                CohortEnrollmentAvailability.available => AppColors.success,
                CohortEnrollmentAvailability.full => AppColors.textSecondary,
                CohortEnrollmentAvailability.upcoming => AppColors.warning,
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(c.name, style: AppTypography.cardTitle),
        const SizedBox(height: 4),
        fact('Cấp độ JLPT', c.level.isEmpty ? '—' : c.level),
        fact('Mentor', c.mentorName.isEmpty ? '#${c.mentorId}' : c.mentorName),
        ?reviewLine,
        fact('Lịch hằng tuần', schedule),
        fact('Thời lượng', '${c.sessionMinutes ?? '—'} phút/buổi'),
        fact(
          'Tổng số buổi',
          '$totalSessions buổi${weeks != null ? ' · $weeks tuần' : ''}${c.totalTeachingHours != null ? ' · Tổng ${_hours(c.totalTeachingHours!)}' : ''}',
        ),
        fact(
          'Chỗ còn trống',
          '${c.seatsAvailable < 0 ? 0 : c.seatsAvailable}/${c.capacity}',
        ),
        fact('Học phí trọn khóa', '$price đ', strong: true),
        const SizedBox(height: 2),
        Text(
          'Khai giảng: ${date.format(c.startsAt)} · Hạn đăng ký: ${date.format(c.enrollmentClosesAtUtc)}',
          style: AppTypography.metadata.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
