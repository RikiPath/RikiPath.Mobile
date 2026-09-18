import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';

class LearningHeader extends StatelessWidget implements PreferredSizeWidget {
  const LearningHeader.root({
    required this.level,
    required this.streakDays,
    required this.hasUnreadNotifications,
    required this.initials,
    required this.onProfilePressed,
    super.key,
  }) : title = null,
       subtitle = null,
       onBack = null;

  const LearningHeader.detail({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.initials,
    required this.onBack,
    required this.onProfilePressed,
    super.key,
  }) : streakDays = null,
       hasUnreadNotifications = false;

  final String? title;
  final String? subtitle;
  final JlptLevel? level;
  final int? streakDays;
  final bool hasUnreadNotifications;
  final String? initials;
  final VoidCallback? onBack;
  final VoidCallback onProfilePressed;

  bool get _isRoot => onBack == null;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: preferredSize.height,
      titleSpacing: _isRoot ? AppSpacing.space4 : 0,
      elevation: 0,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(boxShadow: AppShadows.learnerHeader),
      ),
      leadingWidth: _isRoot ? 0 : 56,
      leading: _isRoot
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: AppSpacing.space3),
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.learnerTextPrimary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
      title: _isRoot ? _buildBrandTitle() : _buildDetailTitle(),
      actions: _isRoot
          ? _buildRootActions(compact: compact)
          : _buildDetailActions(),
    );
  }

  Widget _buildBrandTitle() {
    return RikiBrandLockup(level: level, compact: true);
  }

  Widget _buildDetailTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.learnerTextPrimary,
          ),
        ),
        Text(
          subtitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.metadata.copyWith(
            color: AppColors.learnerTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRootActions({required bool compact}) {
    return [
      if (streakDays != null)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.warningBackground,
            border: Border.all(color: AppColors.warningBorder),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 17,
                color: AppColors.skillGrammar,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                compact ? '$streakDays' : '$streakDays ngày',
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.learnerTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        )
      else
        const _HeaderSkeleton(width: 58),
      Semantics(
        label: 'Thông báo',
        child: SizedBox.square(
          dimension: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
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
      _ProfileAvatar(initials: initials, onPressed: onProfilePressed),
      const SizedBox(width: AppSpacing.space2),
    ];
  }

  List<Widget> _buildDetailActions() {
    return [
      if (level != null) JlptBadge(level!),
      const SizedBox(width: AppSpacing.space1),
      _ProfileAvatar(initials: initials, onPressed: onProfilePressed),
      const SizedBox(width: AppSpacing.space2),
    ];
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.onPressed});

  final String? initials;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mở trang cá nhân',
      child: InkResponse(
        onTap: onPressed,
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
