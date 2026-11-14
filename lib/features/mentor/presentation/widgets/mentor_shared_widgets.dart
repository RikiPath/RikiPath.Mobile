import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

String mentorTimeLabel(MentorTimestamp? timestamp, BuildContext context) {
  if (timestamp == null) return context.l10n.mentorSchedulePending;
  return DateFormat('dd/MM/yyyy • HH:mm').format(timestamp.displayValue);
}

String mentorStatusLabel(MentorMeetingStatus status, BuildContext context) =>
    switch (status) {
      MentorMeetingStatus.awaitingPayment =>
        context.l10n.mentorStatusAwaitingPayment,
      MentorMeetingStatus.pendingAssignment =>
        context.l10n.mentorStatusPendingAssignment,
      MentorMeetingStatus.assigned => context.l10n.mentorStatusAssigned,
      MentorMeetingStatus.accepted => context.l10n.mentorStatusAccepted,
      MentorMeetingStatus.completed => context.l10n.mentorStatusCompleted,
      MentorMeetingStatus.cancelled => context.l10n.mentorStatusCancelled,
      MentorMeetingStatus.unknown => context.l10n.mentorStatusUnknown,
    };

class MentorPageHeader extends StatelessWidget {
  const MentorPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.compactPageTitle),
        const SizedBox(height: AppSpacing.space1),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class MentorAvailabilityCard extends StatelessWidget {
  const MentorAvailabilityCard({required this.slot, super.key});

  final MentorAvailabilitySlot slot;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MentorIconTile(
            icon: slot.isBooked
                ? Icons.event_busy_outlined
                : Icons.event_available_outlined,
            color: slot.isBooked ? AppColors.textSecondary : AppColors.success,
            backgroundColor: slot.isBooked
                ? AppColors.surfaceSubtle
                : AppColors.successBackground,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.isBooked
                      ? context.l10n.mentorSlotBooked
                      : context.l10n.mentorSlotOpen,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                _LabelValue(
                  label: context.l10n.mentorStartTimeLabel,
                  value: mentorTimeLabel(slot.startTime, context),
                ),
                const SizedBox(height: AppSpacing.space1),
                _LabelValue(
                  label: context.l10n.mentorEndTimeLabel,
                  value: mentorTimeLabel(slot.endTime, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MentorMeetingCard extends StatelessWidget {
  const MentorMeetingCard({
    required this.meeting,
    this.onTap,
    this.footer,
    super.key,
  });

  final MentorMeetingSummary meeting;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: RikiCard(
            backgroundColor: AppColors.cardWarmWhite,
            borderColor: AppColors.cardBorderMuted,
            boxShadow: AppShadows.sakuraSubtle,
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MentorIconTile(
                      icon: Icons.video_call_outlined,
                      color: AppColors.brandPrimary,
                      backgroundColor: AppColors.brandTint,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting.learnerName ??
                                context.l10n.mentorLearnerUnknown,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            mentorTimeLabel(meeting.scheduledAt, context),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          _StatusPill(status: meeting.status),
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpacing.space2),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  const Divider(height: 1, color: AppColors.cardBorderMuted),
                  const SizedBox(height: AppSpacing.space2),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MentorEmptyState extends StatelessWidget {
  const MentorEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(icon: icon, title: title, message: description);
  }
}

class MentorErrorState extends StatelessWidget {
  const MentorErrorState({
    required this.message,
    required this.onRetry,
    this.title,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      title: title ?? context.l10n.toastActionFailedTitle,
      message: message,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
      compact: true,
    );
  }
}

class MentorListSkeleton extends StatelessWidget {
  const MentorListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const RikiSectionSkeleton(
      itemCount: 3,
      cardHeight: 118,
      showSearch: false,
      showFilters: false,
    );
  }
}

class _MentorIconTile extends StatelessWidget {
  const _MentorIconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTypography.metadata.copyWith(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final MentorMeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == MentorMeetingStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.successBackground : AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        mentorStatusLabel(status, context),
        style: AppTypography.badgeText.copyWith(
          color: isCompleted ? AppColors.success : AppColors.brandPrimary,
        ),
      ),
    );
  }
}

/// Marks subtrees mounted inside `MentorShell` so tab screens avoid rendering
/// a duplicate bottom navigation bar when hosted inside the indexed shell.
class MentorShellScope extends InheritedWidget {
  const MentorShellScope({
    super.key,
    required this.isInsideShell,
    required super.child,
  });

  final bool isInsideShell;

  static bool hasShell(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MentorShellScope>()
            ?.isInsideShell ??
        false;
  }

  @override
  bool updateShouldNotify(MentorShellScope oldWidget) =>
      isInsideShell != oldWidget.isInsideShell;
}

/// Shared navigation helper for Mentor widgets inside or outside [MentorShell].
///
/// Routes belonging to [MentorNavigationConfiguration] switch the persistent
/// shell branch with `router.go` instead of pushing a standalone screen outside
/// the shell; secondary routes still push on top of the shell.
void mentorNavigate(BuildContext context, String route) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }
  if (MentorShellScope.hasShell(context) &&
      MentorNavigationConfiguration.instance.containsRoute(route)) {
    router.go(route);
    return;
  }
  router.push(route);
}

/// Shared Mentor Bottom Navigation Bar delegating rendering and motion to
/// [SakuraBottomNavigation] via [MentorNavigationConfiguration].
class MentorBottomNavigationBar extends StatelessWidget {
  const MentorBottomNavigationBar({
    required this.selectedIndex,
    this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  static const List<String> routes = MentorNavigationConfiguration.tabRoutes;

  @override
  Widget build(BuildContext context) {
    final config = MentorNavigationConfiguration.instance;
    final localizedDestinations = config.destinations(context.l10n);

    return SakuraBottomNavigation(
      key: config.bottomNavigationKey,
      selectedIndex: selectedIndex,
      destinations: localizedDestinations,
      onDestinationSelected: (index) {
        if (index < 0 || index >= routes.length) {
          return;
        }
        final callback = onDestinationSelected;
        if (callback != null) {
          callback(index);
          return;
        }
        if (index == selectedIndex) {
          return;
        }
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go(routes[index]);
        }
      },
    );
  }
}

/// Shared Logout flow for Mentor that reuses the exact Learner confirmation
/// sheet ([showProfileConfirmationSheet]), clears user-scoped session caches
/// via the root auth identity listener, signs out, and triggers the Sakura
/// Glass logout toast.
Future<bool> confirmAndPerformMentorLogout({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return confirmAndPerformLogout(context: context, ref: ref);
}

/// Personalized Mentor Greeting Header matching Learner's Greeting Section.
class MentorGreetingHeader extends StatelessWidget {
  const MentorGreetingHeader({
    required this.profileState,
    super.key,
  });

  final AsyncValue<MentorProfileData> profileState;

  @override
  Widget build(BuildContext context) {
    final profile = profileState.value;
    final hasName = profile != null &&
        ((profile.firstName?.trim().isNotEmpty ?? false) ||
            (profile.lastName?.trim().isNotEmpty ?? false));
    final greetingTitle = hasName
        ? 'Xin chào, ${profile.fullName}!'
        : 'Xin chào, Cố vấn!';
    final levelTag = profile?.jlptLevel?.trim();
    final subtitle = (levelTag != null && levelTag.isNotEmpty)
        ? 'Không gian cố vấn · Chuyên môn JLPT $levelTag'
        : 'Không gian cố vấn · Hướng dẫn học viên 1-1';

    return Row(
      key: const Key('mentor_greeting_header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtlePink),
          ),
          child: const Icon(
            Icons.local_florist_rounded,
            color: AppColors.brandPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.compactPageTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sakura Mentoring Journey Hero Banner matching Learner Hero Banner style.
class SakuraMentorHeroBanner extends StatelessWidget {
  const SakuraMentorHeroBanner({
    this.onTap,
    super.key,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      label:
          'Đồng hành cùng học viên. Quản lý buổi tư vấn và chia sẻ kinh nghiệm JLPT.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('mentor_sakura_hero_banner'),
          onTap: onTap,
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
          child: AspectRatio(
            aspectRatio: 2048 / 682,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.25),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Pastel Sakura Mentoring Backdrop
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFE5EC),
                          Color(0xFFFFF3F6),
                          Color(0xFFFFF8FA),
                        ],
                      ),
                    ),
                  ),
                  // Subtle decorative sakura circles
                  Positioned(
                    right: -24,
                    top: -28,
                    child: IgnorePointer(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandSecondary.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 10,
                    bottom: 10,
                    child: Center(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Image.asset(
                          'assets/images/icons_3d/mentor.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.workspace_premium_rounded,
                            size: 56,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final leftOffset =
                          (constraints.maxWidth * 0.34).clamp(118.0, 168.0);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          leftOffset,
                          6,
                          AppSpacing.space4,
                          6,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFD1DC),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  '先生・メンター',
                                  style: TextStyle(
                                    color: AppColors.brandPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Đồng hành cùng học viên',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: constraints.maxWidth < 380
                                      ? 14.0
                                      : 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2C1E20),
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Quản lý buổi tư vấn và chia sẻ kinh nghiệm JLPT.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: constraints.maxWidth < 380
                                      ? 11.5
                                      : 12.2,
                                  color: const Color(0xFF5A3E42),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
