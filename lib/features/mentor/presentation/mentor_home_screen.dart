import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorHomeScreen extends ConsumerWidget {
  const MentorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(mentorAvailabilityControllerProvider);
    final meetings = ref.watch(mentorMeetingsControllerProvider);

    return Scaffold(
      key: const Key('mentor_home_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mentorLandingTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.space3),
            child: RikiLanguageSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => refreshMentorReadModels(ref),
          child: ListView(
            key: const Key('mentor_home_scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: [
              const RikiBrandLockup(),
              const SizedBox(height: AppSpacing.space5),
              MentorPageHeader(
                title: context.l10n.mentorHomeGreeting,
                subtitle: context.l10n.mentorLandingDescription,
              ),
              const SizedBox(height: AppSpacing.space5),
              _MentorAvailabilitySummary(
                state: availability,
                onRetry: ref
                    .read(mentorAvailabilityControllerProvider.notifier)
                    .retry,
                onOpen: () => context.push(AppRoutes.mentorAvailability),
              ),
              const SizedBox(height: AppSpacing.space4),
              _MentorMeetingSummary(
                state: meetings,
                onRetry: ref
                    .read(mentorMeetingsControllerProvider.notifier)
                    .retry,
                onOpen: () => context.push(AppRoutes.mentorMeetings),
              ),
              const SizedBox(height: AppSpacing.space6),
              RikiSecondaryButton(
                key: const Key('mentor_logout_button'),
                label: context.l10n.logout,
                leadingIcon: Icons.logout,
                onPressed: () =>
                    ref.read(authSessionControllerProvider).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentorAvailabilitySummary extends StatelessWidget {
  const _MentorAvailabilitySummary({
    required this.state,
    required this.onRetry,
    required this.onOpen,
  });

  final AsyncValue<List<MentorAvailabilitySlot>> state;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const RikiShimmer(
        key: Key('mentor_home_availability_loading'),
        child: RikiSkeletonCard(height: 126),
      );
    }
    if (state.hasError) {
      return MentorErrorState(
        key: const Key('mentor_home_availability_error'),
        message: context.l10n.mentorAvailabilityError,
        onRetry: onRetry,
      );
    }
    final slots = state.requireValue;
    final nextOpenSlot = slots.where((slot) => !slot.isBooked).firstOrNull;
    return _MentorSummaryCard(
      key: const Key('mentor_home_availability_summary'),
      icon: Icons.event_available_outlined,
      title: context.l10n.mentorAvailabilityTitle,
      count: context.l10n.mentorAvailabilityCount(slots.length),
      detail: nextOpenSlot == null
          ? context.l10n.mentorAvailabilityEmpty
          : mentorTimeLabel(nextOpenSlot.startTime, context),
      actionLabel: context.l10n.mentorViewAvailability,
      onPressed: onOpen,
    );
  }
}

class _MentorMeetingSummary extends StatelessWidget {
  const _MentorMeetingSummary({
    required this.state,
    required this.onRetry,
    required this.onOpen,
  });

  final AsyncValue<List<MentorMeetingSummary>> state;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const RikiShimmer(
        key: Key('mentor_home_meetings_loading'),
        child: RikiSkeletonCard(height: 126),
      );
    }
    if (state.hasError) {
      return MentorErrorState(
        key: const Key('mentor_home_meetings_error'),
        message: context.l10n.mentorMeetingsError,
        onRetry: onRetry,
      );
    }
    final meetings = state.requireValue;
    final next = meetings.firstOrNull;
    return _MentorSummaryCard(
      key: const Key('mentor_home_meetings_summary'),
      icon: Icons.video_call_outlined,
      title: context.l10n.mentorMeetingsTitle,
      count: context.l10n.mentorMeetingsCount(meetings.length),
      detail: next == null
          ? context.l10n.mentorMeetingsEmpty
          : '${next.learnerName ?? context.l10n.mentorLearnerUnknown} • '
                '${mentorTimeLabel(next.scheduledAt, context)}',
      actionLabel: context.l10n.mentorViewMeetings,
      onPressed: onOpen,
    );
  }
}

class _MentorSummaryCard extends StatelessWidget {
  const _MentorSummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.detail,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String count;
  final String detail;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(title, style: AppTypography.sectionTitle)),
              Text(
                count,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          RikiTextButton(
            label: actionLabel,
            trailingIcon: Icons.arrow_forward,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
