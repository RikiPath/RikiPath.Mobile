import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_language_switcher.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';

class LearningHeader extends StatelessWidget implements PreferredSizeWidget {
  const LearningHeader.root({
    required this.streakDays,
    required this.hasUnreadNotifications,
    super.key,
  }) : title = null,
       subtitle = null,
       onBack = null;

  const LearningHeader.detail({
    required this.title,
    required this.subtitle,
    required this.onBack,
    super.key,
  }) : streakDays = null,
       hasUnreadNotifications = false;

  final String? title;
  final String? subtitle;
  final int? streakDays;
  final bool hasUnreadNotifications;
  final VoidCallback? onBack;

  bool get _isRoot => onBack == null;

  @override
  Size get preferredSize => const Size.fromHeight(RikiLearnerHeader.height);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return RikiLearnerHeader(
      titleSpacing: _isRoot ? AppSpacing.space4 : 0,
      leadingWidth: _isRoot ? 0 : 64,
      leading: _isRoot
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: AppSpacing.space3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.brandTint,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.cardSoft,
                    ),
                    child: IconButton(
                      key: const Key('learning_detail_back_button'),
                      tooltip: context.l10n.back,
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      iconSize: 22,
                      icon: const Icon(Icons.chevron_left),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.brandPrimary,
                        backgroundColor: Colors.transparent,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      title: _isRoot ? _buildBrandTitle() : _buildDetailTitle(),
      actions: _isRoot
          ? _buildRootActions(context, compact: compact)
          : _buildDetailActions(),
    );
  }

  Widget _buildBrandTitle() {
    return const RikiBrandLockup(compact: true);
  }

  Widget _buildDetailTitle() {
    return Column(
      key: const Key('learning_detail_title'),
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

  List<Widget> _buildRootActions(
    BuildContext context, {
    required bool compact,
  }) {
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
                compact ? '$streakDays' : context.l10n.dayShort(streakDays!),
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
        label: context.l10n.notifications,
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
      const RikiLanguageSwitcher(),
      const SizedBox(width: AppSpacing.space2),
    ];
  }

  List<Widget> _buildDetailActions() {
    return [
      const RikiLanguageSwitcher(),
      const SizedBox(width: AppSpacing.space2),
    ];
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
