import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({
    required this.level,
    required this.streakDays,
    required this.hasUnreadNotifications,
    required this.initials,
    required this.onProfilePressed,
    super.key,
  });

  final JlptLevel? level;
  final int? streakDays;
  final bool hasUnreadNotifications;
  final String? initials;
  final VoidCallback onProfilePressed;

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
                  'Ngày $streakDays',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.learnerTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          const _HeaderSkeleton(width: 54),
        const SizedBox(width: AppSpacing.space1),
        Semantics(
          label: 'Thông báo',
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
                if (hasUnreadNotifications)
                  const Positioned(
                    top: 9,
                    right: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 7),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Mở trang cá nhân',
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
    return Container(
      width: width,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.learnerSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
