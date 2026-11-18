import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

const List<String> _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// "T4 20/11 19:00" — locale-independent so it renders without intl data.
String formatCohortSessionTime(DateTime dt) =>
    '${_weekdayShort[dt.weekday - 1]} ${DateFormat('dd/MM HH:mm').format(dt)}';

/// Mentor's assigned group cohorts (`/mentor/cohorts`).
class MentorCohortsScreen extends ConsumerWidget {
  const MentorCohortsScreen({super.key});

  static String cohortStatusLabel(String status) => switch (status) {
    'Draft' => 'Bản nháp',
    'Published' => 'Đang tuyển sinh',
    'Full' => 'Đã đủ học viên',
    'InProgress' || 'Ongoing' || 'Active' => 'Đang học',
    'Completed' => 'Đã kết thúc',
    'Cancelled' => 'Đã hủy',
    _ => status,
  };

  static Color cohortStatusColor(String status) => switch (status) {
    'Published' => AppColors.info,
    'Full' => AppColors.warning,
    'InProgress' || 'Ongoing' || 'Active' => AppColors.success,
    'Cancelled' => AppColors.error,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorAssignedCohortsProvider);
    final inShell = MentorShellScope.hasShell(context);
    final hasRouter = !inShell && GoRouter.maybeOf(context) != null;

    return Scaffold(
      key: const Key('mentor_cohorts_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: hasRouter
            ? BackButton(onPressed: () => popOrGo(context, AppRoutes.mentor))
            : null,
        title: const Text('Lớp nhóm của tôi'),
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncData(:final value) => RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () => ref.refresh(mentorAssignedCohortsProvider.future),
            child: value.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    children: const [
                      MentorEmptyState(
                        key: Key('mentor_cohorts_empty'),
                        icon: Icons.groups_outlined,
                        title: 'Chưa có lớp nhóm được phân công',
                        description:
                            'Khi Admin phân công bạn làm Mentor chính hoặc dạy thay cho một lớp, lớp sẽ hiển thị tại đây.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    itemCount: value.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space3),
                    itemBuilder: (context, i) =>
                        MentorCohortCard(cohort: value[i]),
                  ),
          ),
          AsyncError(:final error) => Center(
            child: MentorErrorState(
              message: appErrorMessage(error, context.l10n),
              onRetry: () => ref.invalidate(mentorAssignedCohortsProvider),
            ),
          ),
          _ => const MentorListSkeleton(key: Key('mentor_cohorts_loading')),
        },
      ),
    );
  }
}

class MentorCohortCard extends StatelessWidget {
  const MentorCohortCard({required this.cohort, super.key});

  final StudyCohortSummary cohort;

  @override
  Widget build(BuildContext context) {
    final overview = MentorCohortOverview(cohort);
    final next = overview.nextSession(DateTime.now());
    final perWeek = overview.sessionsPerWeek;
    final secondary = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );

    return RikiCard(
      key: ValueKey('mentor_cohort_card_${cohort.id}'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      padding: const EdgeInsets.all(AppSpacing.space4),
      onTap: () => context.push(AppRoutes.mentorCohortDetail(cohort.id)),
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
                  key: ValueKey('mentor_cohort_intensity_${cohort.id}'),
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
          Text(cohort.name, style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text(
            [
              if (perWeek > 0) '$perWeek buổi/tuần',
              if (cohort.totalSessions != null) '${cohort.totalSessions} buổi',
              if (cohort.schedulePattern.isNotEmpty)
                cohort.schedulePattern.map((p) => p.display).join(' · '),
            ].join(' · '),
            style: secondary,
          ),
          Text(
            next == null
                ? 'Không còn buổi học sắp tới'
                : 'Buổi tiếp theo: Buổi ${next.number} · ${formatCohortSessionTime(next.startTime)}',
            key: ValueKey('mentor_cohort_next_${cohort.id}'),
            style: secondary,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                'Học viên: ${cohort.enrolledCount}/${cohort.capacity}',
                key: ValueKey('mentor_cohort_roster_${cohort.id}'),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
