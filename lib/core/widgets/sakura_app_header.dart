import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/animated_notification_bell.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';

/// Unified Sakura App Header for all primary learner destinations.
///
/// Follows the shared specification:
/// [RikiPath Logo] [🔥 Streak] [Notification] [Calendar]
///
/// Automatically hooks into Riverpod state when explicit parameters are omitted,
/// supports dynamic scroll-aware soft shadow elevation, and guarantees zero
/// visual discrepancy when switching between bottom navigation tabs.
class SakuraAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const SakuraAppHeader({
    this.streakDays,
    this.isStreakLoading = false,
    this.showStreak = true,
    this.unreadNotificationCount,
    this.onNotificationsPressed,
    this.onCalendarPressed,
    this.calendarTooltip = 'Lịch học',
    this.isScrolled = false,
    super.key,
  });

  final int? streakDays;
  final bool isStreakLoading;
  final bool showStreak;
  final int? unreadNotificationCount;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCalendarPressed;
  final String calendarTooltip;
  final bool isScrolled;

  @override
  Size get preferredSize => const Size.fromHeight(RikiLearnerHeader.height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Resolve Streak (skipped when showStreak is false, e.g. for Mentor)
    final analyticsAsync = (showStreak && streakDays == null)
        ? ref.watch(learnerAnalyticsControllerProvider)
        : null;
    final liveAnalytics = analyticsAsync?.value;
    final effectiveStreak = !showStreak
        ? null
        : (streakDays ??
              (liveAnalytics?.isAvailable(AnalyticsSection.streak) == true
                  ? liveAnalytics?.streakDays
                  : null));
    final effectiveLoading =
        showStreak &&
        (isStreakLoading ||
            (streakDays == null && (analyticsAsync?.isLoading ?? false)));

    // 2. Resolve Notifications
    final notificationsAsync = ref.watch(notificationControllerProvider);
    final effectiveUnread =
        unreadNotificationCount ?? notificationsAsync.value?.unreadCount;
    final bellTrigger = ref.watch(notificationBellTriggerProvider);

    // 3. Resolve Navigation callbacks
    final handleNotifications =
        onNotificationsPressed ?? () => context.push(AppRoutes.notifications);
    final handleCalendar =
        onCalendarPressed ?? () => context.push(AppRoutes.calendar);

    // Responsive checks: fits comfortably on 340dp+, 360dp, 393dp, 412dp
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    final showHeaderStreak =
        showStreak && screenWidth >= 340 && textScale < 24;

    return RikiLearnerHeader(
      isScrolled: isScrolled,
      title: const RikiBrandLockup(compact: true),
      actions: [
        if (showHeaderStreak && effectiveStreak != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.streakFireBackground,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.streakFireBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SakuraColorfulIcon(
                  type: SakuraColorfulIconType.streak,
                  size: 20,
                  useEmoji: true,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  context.l10n.dayShort(effectiveStreak),
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.streakFire,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else if (showHeaderStreak && effectiveLoading)
          const _HeaderSkeleton(width: 54),
        const SizedBox(width: AppSpacing.space1),
        AnimatedNotificationBell(
          unreadCount: effectiveUnread,
          ringSequence: bellTrigger.ringSequence,
          consumedSequence: bellTrigger.consumedSequence,
          onRingConsumed: (sequence) => ref
              .read(notificationBellTriggerProvider.notifier)
              .consumeRing(sequence),
          onPressed: handleNotifications,
        ),
        IconButton(
          key: const ValueKey<String>('home_calendar_button'),
          icon: const SakuraColorfulIcon(
            type: SakuraColorfulIconType.calendar,
            size: 24,
            useEmoji: true,
          ),
          tooltip: calendarTooltip,
          onPressed: handleCalendar,
        ),
      ],
    );
  }
}

/// Backwards compatibility alias for the legacy HomeHeader name.
typedef HomeHeader = SakuraAppHeader;

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return RikiSkeleton(width: width, height: 26, borderRadius: AppRadius.pill);
  }
}
