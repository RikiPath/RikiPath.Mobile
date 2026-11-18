import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/features/cohorts/application/mentor_cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorHomeScreen extends ConsumerWidget {
  const MentorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityState = ref.watch(mentorAvailabilityControllerProvider);
    final cohortsState = ref.watch(mentorAssignedCohortsProvider);
    final profileState = ref.watch(mentorProfileControllerProvider);
    final complaintsState = ref.watch(mentorCohortComplaintsProvider);
    final bothFailed = availabilityState.hasError && cohortsState.hasError;
    final secondaryFailed =
        !bothFailed &&
        complaintsState is AsyncError &&
        complaintsState.error is! StateError;

    return Scaffold(
      key: const Key('mentor_home_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: SakuraAppHeader(
        showStreak: false,
        calendarTooltip: 'Lịch giảng dạy',
        onNotificationsPressed: () =>
            mentorNavigate(context, AppRoutes.notifications),
        onCalendarPressed: () => mentorNavigate(context, AppRoutes.mentorCalendar),
      ),
      bottomNavigationBar: MentorShellScope.hasShell(context)
          ? null
          : const MentorBottomNavigationBar(selectedIndex: 0),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.brandPrimary,
          onRefresh: () => Future.wait<void>([
            ref.read(mentorAvailabilityControllerProvider.notifier).retry(),
            ref.refresh(mentorAssignedCohortsProvider.future).catchError((_) => <StudyCohortSummary>[]),
            ref.read(mentorProfileControllerProvider.notifier).retry(),
            ref.refresh(mentorCohortComplaintsProvider.future).catchError((_) => <CohortComplaint>[]),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.space3,
              0,
              AppSpacing.space8,
            ),
            children: [
              // 1. Personalized Mentor Greeting Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: MentorGreetingHeader(profileState: profileState),
              ),
              const SizedBox(height: AppSpacing.space3),

              // 2. Full-bleed Sakura Mentoring Journey Hero Banner
              SakuraMentorHeroBanner(
                onTap: () => mentorNavigate(context, AppRoutes.mentorCohorts),
              ),
              const SizedBox(height: AppSpacing.space4),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3. Approval Status Banner when Mentor profile is not yet Approved
                    if (profileState.hasValue &&
                        !profileState.requireValue.isApproved) ...[
                      _MentorApprovalBanner(
                        profile: profileState.requireValue,
                        onOpenProfile: () =>
                            mentorNavigate(context, AppRoutes.mentorProfile),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],

                    // 4. Compact KPI Summary Strip (Never fakes 0 on error)
                    _MentorKpiSummaryStrip(
                      availabilityState: availabilityState,
                      cohortsState: cohortsState,
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    if (secondaryFailed) ...[
                      RikiInfoBanner(
                        message: context.l10n.mentorHomePartialFailureBanner,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],

                    if (cohortsState case AsyncData(:final value)) ...[
                      _NextCohortSessionSpotlight(cohorts: value),
                    ],

                    _AttentionQueueCard(
                      cohortsState: cohortsState,
                      complaintsState: complaintsState,
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    if (bothFailed) ...[
                      RikiCard(
                        key: const Key('mentor_home_both_error_banner'),
                        backgroundColor: AppColors.errorBackground,
                        borderColor: AppColors.error.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.errorText,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Text(
                                'Chưa thể đồng bộ dữ liệu lịch dạy và lớp nhóm. Vui lòng kiểm tra kết nối và thử lại.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.errorText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            TextButton(
                              key: const Key('mentor_home_retry_all_button'),
                              onPressed: () {
                                ref
                                    .read(
                                      mentorAvailabilityControllerProvider
                                          .notifier,
                                    )
                                    .retry();
                                ref.invalidate(mentorAssignedCohortsProvider);
                              },
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],

                    // 6. Mentor Calendar Summary Card
                    RikiCard(
                      key: const Key('mentor_home_calendar_summary'),
                      backgroundColor: AppColors.cardWarmWhite,
                      borderColor: AppColors.cardBorderMuted,
                      boxShadow: AppShadows.sakuraSubtle,
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.brandTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppColors.brandPrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lịch giảng dạy (Calendar)',
                                      style: AppTypography.cardTitle,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lịch biểu chi tiết: Ngày, Tuần, Tháng, Năm và Lịch trình.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          RikiPrimaryButton(
                            key: const Key('mentor_home_calendar_button'),
                            label: 'Mở Lịch Giảng Dạy',
                            leadingIcon: Icons.calendar_today_outlined,
                            onPressed: () =>
                                mentorNavigate(context, AppRoutes.mentorCalendar),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    // 7. Availability Summary Card
                    _AvailabilitySummaryCard(state: availabilityState),
                    const SizedBox(height: AppSpacing.space4),

                    // 8. Cohorts Summary Card
                    _CohortsSummaryCard(state: cohortsState),
                    const SizedBox(height: AppSpacing.space4),

                    // 9. Quick Operations Hub & Utilities
                    _QuickOperationsSection(
                      complaintsState: complaintsState,
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    // 10. Shared Logout Button
                    RikiSecondaryButton(
                      key: const Key('mentor_logout_button'),
                      label: context.l10n.logout,
                      leadingIcon: Icons.logout_rounded,
                      onPressed: () => confirmAndPerformMentorLogout(
                        context: context,
                        ref: ref,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentorApprovalBanner extends StatelessWidget {
  const _MentorApprovalBanner({
    required this.profile,
    required this.onOpenProfile,
  });

  final MentorProfileData profile;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final (title, description, color, bg) = switch (true) {
      _ when profile.isPending => (
        'Hồ sơ đang chờ xét duyệt',
        'Quản trị viên đang xem xét hồ sơ chuyên môn của bạn.',
        AppColors.warningText,
        AppColors.warningBackground,
      ),
      _ when profile.isRejected => (
        'Hồ sơ cần cập nhật lại',
        profile.rejectionReason?.trim().isNotEmpty == true
            ? 'Lý do: ${profile.rejectionReason}'
            : 'Hồ sơ chưa đạt yêu cầu xét duyệt. Vui lòng kiểm tra và gửi lại.',
        AppColors.errorText,
        AppColors.errorBackground,
      ),
      _ when profile.isChangesRequested => (
        'Yêu cầu bổ sung thông tin',
        profile.reviewNotes?.trim().isNotEmpty == true
            ? 'Ghi chú: ${profile.reviewNotes}'
            : 'Quản trị viên yêu cầu bổ sung thông tin hồ sơ.',
        AppColors.warningText,
        AppColors.warningBackground,
      ),
      _ => (
        'Hoàn thiện hồ sơ cố vấn',
        'Cập nhật thông tin chuyên môn và chứng chỉ JLPT để kích hoạt nhận lịch.',
        AppColors.brandPrimary,
        AppColors.brandTint,
      ),
    };

    return RikiCard(
      key: const Key('mentor_home_approval_banner'),
      backgroundColor: bg,
      borderColor: color.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: color, size: 24),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpenProfile,
            child: const Text('Xem hồ sơ'),
          ),
        ],
      ),
    );
  }
}

class _MentorKpiSummaryStrip extends StatelessWidget {
  const _MentorKpiSummaryStrip({
    required this.availabilityState,
    required this.cohortsState,
  });

  final AsyncValue<List<MentorAvailabilitySlot>> availabilityState;
  final AsyncValue<List<StudyCohortSummary>> cohortsState;

  @override
  Widget build(BuildContext context) {
    final openSlotsText = switch (availabilityState) {
      AsyncData(:final value) =>
        '${value.where((slot) => !slot.isBooked).length}',
      AsyncLoading() => '…',
      AsyncError() => '—',
    };
    final activeCohortsText = switch (cohortsState) {
      AsyncData(:final value) =>
        '${value.where((c) => c.status != 'Completed' && c.status != 'Cancelled').length}',
      AsyncLoading() => '…',
      AsyncError() => '—',
    };
    final completedCohortsText = switch (cohortsState) {
      AsyncData(:final value) =>
        '${value.where((c) => c.status == 'Completed').length}',
      AsyncLoading() => '…',
      AsyncError() => '—',
    };

    return IntrinsicHeight(
      key: const Key('mentor_home_kpi_strip'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _KpiTile(
              label: 'Lớp đang dạy',
              value: activeCohortsText,
              icon: Icons.groups_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _KpiTile(
              label: context.l10n.mentorHomeMetricOpenSlots,
              value: openSlotsText,
              icon: Icons.event_available_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _KpiTile(
              label: 'Lớp đã xong',
              value: completedCohortsText,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.borderSubtlePink,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 15, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.compactPageTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySummaryCard extends ConsumerWidget {
  const _AvailabilitySummaryCard({required this.state});

  final AsyncValue<List<MentorAvailabilitySlot>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RikiCard(
      key: const Key('mentor_home_availability_summary'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.mentorAvailabilityTitle,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            context.l10n.mentorAvailabilityDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          switch (state) {
            AsyncLoading() => const RikiSkeleton(
              key: Key('mentor_home_availability_loading'),
              height: 56,
            ),
            AsyncError() => MentorErrorState(
              key: const Key('mentor_home_availability_error'),
              message: context.l10n.mentorAvailabilityError,
              onRetry: ref
                  .read(mentorAvailabilityControllerProvider.notifier)
                  .retry,
            ),
            AsyncData(:final value) => _AvailabilitySummaryBody(slots: value),
          },
          const SizedBox(height: AppSpacing.space3),
          RikiSecondaryButton(
            key: const Key('mentor_home_availability_button'),
            label: 'Đăng ký lịch trống',
            leadingIcon: Icons.event_available_outlined,
            onPressed: () => mentorNavigate(context, AppRoutes.mentorAvailability),
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySummaryBody extends StatelessWidget {
  const _AvailabilitySummaryBody({required this.slots});

  final List<MentorAvailabilitySlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Text(
        context.l10n.mentorAvailabilityEmpty,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.mentorAvailabilityCount(slots.length),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.space2),
        MentorAvailabilityCard(slot: slots.first),
      ],
    );
  }
}

class _CohortsSummaryCard extends ConsumerWidget {
  const _CohortsSummaryCard({required this.state});

  final AsyncValue<List<StudyCohortSummary>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RikiCard(
      key: const Key('mentor_home_cohorts_summary'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lớp học nhóm phụ trách',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Quản lý buổi học 90 phút, điểm danh, giao & chấm bài tập.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          switch (state) {
            AsyncLoading() => const RikiSkeleton(
              key: Key('mentor_home_cohorts_loading'),
              height: 56,
            ),
            AsyncError() => MentorErrorState(
              key: const Key('mentor_home_cohorts_error'),
              message: 'Chưa thể tải danh sách lớp nhóm.',
              onRetry: () => ref.invalidate(mentorAssignedCohortsProvider),
            ),
            AsyncData(:final value) => Text(
              value.isEmpty
                  ? 'Chưa có lớp nhóm được phân công.'
                  : 'Đang phụ trách ${value.length} lớp nhóm.',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          },
          const SizedBox(height: AppSpacing.space3),
          RikiPrimaryButton(
            key: const Key('mentor_home_cohorts_button'),
            label: 'Mở danh sách lớp nhóm',
            leadingIcon: Icons.groups_outlined,
            onPressed: () => mentorNavigate(context, AppRoutes.mentorCohorts),
          ),
        ],
      ),
    );
  }
}

class _NextCohortSessionSpotlight extends StatelessWidget {
  const _NextCohortSessionSpotlight({required this.cohorts});

  final List<StudyCohortSummary> cohorts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    ({StudyCohortSummary cohort, CohortSessionSlot session})? next;
    for (final c in cohorts) {
      if (c.status == 'Cancelled' || c.status == 'Completed') continue;
      for (final s in c.sessions) {
        if (s.endTime.isBefore(now)) continue;
        if (next == null || s.startTime.isBefore(next.session.startTime)) {
          next = (cohort: c, session: s);
        }
      }
    }
    if (next == null) return const SizedBox.shrink();

    final cohort = next.cohort;
    final session = next.session;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: RikiCard(
        key: const Key('mentor_home_next_session_card'),
        backgroundColor: AppColors.brandTint,
        borderColor: AppColors.brandPrimary.withValues(alpha: 0.25),
        boxShadow: AppShadows.sakuraSubtle,
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.upcoming_rounded,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    'Buổi dạy sắp tới · Buổi ${session.number}',
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                MentorStatusBadge(
                  label: cohort.level,
                  color: AppColors.brandPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(cohort.name, style: AppTypography.sectionTitle),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('dd/MM/yyyy • HH:mm').format(session.startTime.toLocal())} · ${cohort.enrolledCount}/${cohort.capacity} học viên',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            RikiPrimaryButton(
              label: 'Vào chi tiết lớp',
              leadingIcon: Icons.groups_outlined,
              onPressed: () => mentorNavigate(
                context,
                AppRoutes.mentorCohortDetail(cohort.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionQueueCard extends StatelessWidget {
  const _AttentionQueueCard({
    required this.cohortsState,
    required this.complaintsState,
  });

  final AsyncValue<List<StudyCohortSummary>> cohortsState;
  final AsyncValue<List<CohortComplaint>> complaintsState;

  @override
  Widget build(BuildContext context) {
    final openComplaints = complaintsState.asData?.value
            .where((c) => c.mentorCanRespond)
            .length ??
        0;
    final activeCohorts = cohortsState.asData?.value
            .where((c) => c.status != 'Completed' && c.status != 'Cancelled')
            .length ??
        0;

    final entries = <_AttentionItem>[
      if (openComplaints > 0)
        _AttentionItem(
          icon: Icons.gavel_rounded,
          color: AppColors.error,
          label: 'Khiếu nại khóa học chờ giải trình',
          count: openComplaints,
          route: AppRoutes.mentorCohorts,
        ),
      if (activeCohorts > 0)
        _AttentionItem(
          icon: Icons.groups_outlined,
          color: AppColors.brandPrimary,
          label: 'Lớp nhóm đang phụ trách',
          count: activeCohorts,
          route: AppRoutes.mentorCohorts,
        ),
    ];

    return RikiCard(
      key: const Key('mentor_home_attention_queue'),
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mentorHomeAttentionTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          if (entries.isEmpty)
            Text(
              context.l10n.mentorHomeAttentionEmpty,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (var i = 0; i < entries.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => mentorNavigate(context, entries[i].route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: entries[i].color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          entries[i].icon,
                          size: 18,
                          color: entries[i].color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          entries[i].label,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      MentorStatusBadge(
                        label: '${entries[i].count}',
                        color: entries[i].color,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < entries.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final String route;
}

class _QuickOperationsSection extends StatelessWidget {
  const _QuickOperationsSection({required this.complaintsState});

  final AsyncValue<List<CohortComplaint>> complaintsState;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final openComplaints = complaintsState.asData?.value
            .where((c) => c.mentorCanRespond)
            .length ??
        0;

    final tiles = [
      _QuickOpTileData(
        icon: Icons.groups_outlined,
        label: 'Lớp nhóm',
        badgeCount: openComplaints,
        route: AppRoutes.mentorCohorts,
      ),
      _QuickOpTileData(
        icon: Icons.calendar_view_week_outlined,
        label: l10n.mentorActionSchedulePolicy,
        badgeCount: 0,
        route: AppRoutes.mentorAvailability,
      ),
      const _QuickOpTileData(
        icon: Icons.calendar_month_outlined,
        label: 'Lịch giảng dạy',
        badgeCount: 0,
        route: AppRoutes.mentorCalendar,
      ),
      const _QuickOpTileData(
        icon: Icons.fact_check_outlined,
        label: 'Chấm công & KPI',
        badgeCount: 0,
        route: AppRoutes.mentorAttendanceKpi,
      ),
    ];

    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.mentorHomeQuickActionsTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.space2,
              crossAxisSpacing: AppSpacing.space2,
              childAspectRatio: 2.35,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: () => mentorNavigate(context, tile.route),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.cardBorderMuted),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tile.icon,
                          size: 20,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            tile.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (tile.badgeCount > 0)
                          MentorStatusBadge(
                            label: '${tile.badgeCount}',
                            color: AppColors.brandPrimary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space3),
          RikiSecondaryButton(
            key: const Key('mentor_home_profile_button'),
            label: 'Hồ sơ & Cài đặt tài khoản',
            leadingIcon: Icons.person_outline_rounded,
            onPressed: () => mentorNavigate(context, AppRoutes.mentorProfile),
          ),
        ],
      ),
    );
  }
}

class _QuickOpTileData {
  const _QuickOpTileData({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.route,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
  final String route;
}
