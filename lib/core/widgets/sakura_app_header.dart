import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
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
    this.unreadNotificationCount,
    this.onNotificationsPressed,
    this.onCalendarPressed,
    this.isScrolled = false,
    super.key,
  });

  final int? streakDays;
  final bool isStreakLoading;
  final int? unreadNotificationCount;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCalendarPressed;
  final bool isScrolled;

  @override
  Size get preferredSize => const Size.fromHeight(RikiLearnerHeader.height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Resolve Streak
    final analyticsAsync = streakDays == null
        ? ref.watch(learnerAnalyticsControllerProvider)
        : null;
    final liveAnalytics = analyticsAsync?.value;
    final effectiveStreak =
        streakDays ??
        (liveAnalytics?.isAvailable(AnalyticsSection.streak) == true
            ? liveAnalytics?.streakDays
            : null);
    final effectiveLoading =
        isStreakLoading ||
        (streakDays == null && (analyticsAsync?.isLoading ?? false));

    // 2. Resolve Notifications
    final notificationsAsync = unreadNotificationCount == null
        ? ref.watch(notificationControllerProvider)
        : null;
    final effectiveUnread =
        unreadNotificationCount ?? notificationsAsync?.value?.unreadCount;

    // 3. Resolve Navigation callbacks
    final handleNotifications =
        onNotificationsPressed ?? () => context.push(AppRoutes.notifications);
    final handleCalendar =
        onCalendarPressed ?? () => context.push(AppRoutes.calendar);

    // Responsive checks: fits comfortably on 340dp+, 360dp, 393dp, 412dp
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    final showHeaderStreak = screenWidth >= 340 && textScale < 24;

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
        Semantics(
          button: true,
          label: context.l10n.notifications,
          child: InkResponse(
            onTap: handleNotifications,
            radius: 24,
            child: SizedBox.square(
              dimension: 40,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const SakuraColorfulIcon(
                    type: SakuraColorfulIconType.notifications,
                    size: 24,
                    useEmoji: true,
                  ),
                  if ((effectiveUnread ?? 0) > 0)
                    Positioned(
                      key: const ValueKey<String>(
                        'home_notification_unread_badge',
                      ),
                      top: 2,
                      right: 1,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          effectiveUnread! > 99 ? '99+' : '$effectiveUnread',
                          style: AppTypography.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey<String>('home_calendar_button'),
          icon: const SakuraColorfulIcon(
            type: SakuraColorfulIconType.calendar,
            size: 24,
            useEmoji: true,
          ),
          tooltip: 'Lịch học',
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
