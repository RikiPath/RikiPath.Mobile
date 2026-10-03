import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({
    required this.level,
    required this.streakDays,
    required this.isStreakLoading,
    required this.unreadNotificationCount,
    required this.initials,
    required this.onProfilePressed,
    required this.onNotificationsPressed,
    super.key,
  });

  final JlptLevel? level;
  final int? streakDays;
  final bool isStreakLoading;
  final int? unreadNotificationCount;
  final String? initials;
  final VoidCallback onProfilePressed;
  final VoidCallback onNotificationsPressed;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      titleSpacing: AppSpacing.space4,
      elevation: 0,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(boxShadow: AppShadows.learnerHeader),
      ),
      title: RikiBrandLockup(level: level, compact: true),
      actions: [
        if (streakDays != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.learnerTertiaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: AppColors.learnerTertiary,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  context.l10n.dayCount(streakDays!),
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.learnerTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else if (isStreakLoading)
          const _HeaderSkeleton(width: 54),
        const SizedBox(width: AppSpacing.space1),
        Semantics(
          button: true,
          label: context.l10n.notifications,
          child: InkResponse(
            onTap: onNotificationsPressed,
            radius: 24,
            child: SizedBox.square(
              dimension: 44,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.notifications_outlined,
                    size: 24,
                    color: AppColors.learnerTextSecondary,
                  ),
                  if ((unreadNotificationCount ?? 0) > 0)
                    Positioned(
                      key: const ValueKey<String>(
                        'home_notification_unread_badge',
                      ),
                      top: 4,
                      right: 3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          unreadNotificationCount! > 99
                              ? '99+'
                              : '$unreadNotificationCount',
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
        Semantics(
          button: true,
          label: context.l10n.openProfile,
          child: InkResponse(
            onTap: onProfilePressed,
            radius: 24,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  child: initials == null
                      ? const Icon(Icons.person_outline, size: 18)
                      : Text(
                          initials!,
                          style: AppTypography.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return RikiSkeleton(width: width, height: 26, borderRadius: AppRadius.pill);
  }
}
