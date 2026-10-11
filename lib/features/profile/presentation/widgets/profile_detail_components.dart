import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class ProfileDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ProfileDetailHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      leading: BackButton(onPressed: onBack),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.compactPageTitle.copyWith(fontSize: 19),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metadata,
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}

class ProfileDetailIntro extends StatelessWidget {
  const ProfileDetailIntro({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.brandPrimary,
    this.iconBackground = AppColors.brandTint,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBackground;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ProfileSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileIconBox(
            icon: icon,
            foreground: iconColor,
            background: iconBackground,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.space2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ProfileSurface extends StatelessWidget {
  const ProfileSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space4),
    this.backgroundColor = AppColors.surface,
    this.shadow = AppShadows.cardSoft,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space1),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class ProfileSettingsGroup extends StatelessWidget {
  const ProfileSettingsGroup({required this.children, this.label, super.key});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ProfileSectionLabel(label!),
          const SizedBox(height: AppSpacing.space2),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.cardSoft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index < children.length - 1)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 72,
                      endIndent: AppSpacing.space4,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileSettingsTile extends StatefulWidget {
  const ProfileSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.emphasized = false,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool emphasized;
  final bool destructive;

  @override
  State<ProfileSettingsTile> createState() => _ProfileSettingsTileState();
}

class _ProfileSettingsTileState extends State<ProfileSettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final foreground = widget.destructive
        ? AppColors.errorText
        : widget.emphasized
        ? AppColors.brandPrimary
        : AppColors.textSecondary;
    final background = widget.destructive
        ? AppColors.errorBackground
        : widget.emphasized
        ? AppColors.brandTint
        : AppColors.profileBackground;

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      child: AnimatedScale(
        scale: !reduceMotion && _pressed ? 0.985 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (pressed) => setState(() => _pressed = pressed),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  _ProfileIconBox(
                    icon: widget.icon,
                    foreground: foreground,
                    background: background,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.cardTitle.copyWith(
                            color: widget.destructive
                                ? AppColors.errorText
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.metadata,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  widget.trailing ??
                      (widget.onTap == null
                          ? const SizedBox.shrink()
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSecurityCard extends StatelessWidget {
  const ProfileSecurityCard({
    required this.email,
    required this.verified,
    required this.verifiedTitle,
    required this.unverifiedTitle,
    super.key,
  });

  final String email;
  final bool verified;
  final String verifiedTitle;
  final String unverifiedTitle;

  @override
  Widget build(BuildContext context) {
    final foreground = verified ? AppColors.success : AppColors.warningText;
    final background = verified
        ? AppColors.successBackgroundSoft
        : AppColors.warningBackground;
    return ProfileSurface(
      child: Row(
        children: [
          _ProfileIconBox(
            icon: verified
                ? Icons.verified_user_outlined
                : Icons.gpp_maybe_outlined,
            foreground: foreground,
            background: background,
            size: 50,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? verifiedTitle : unverifiedTitle,
                  style: AppTypography.sectionTitle.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileFormSection extends StatelessWidget {
  const ProfileFormSection({required this.child, this.title, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          ProfileSectionLabel(title!),
          const SizedBox(height: AppSpacing.space2),
        ],
        ProfileSurface(child: child),
      ],
    );
  }
}

class ProfileAnimatedEntrance extends StatelessWidget {
  const ProfileAnimatedEntrance({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class ProfileDetailSkeleton extends StatelessWidget {
  const ProfileDetailSkeleton({
    this.groupCount = 2,
    this.rowsPerGroup = 2,
    super.key,
  });

  final int groupCount;
  final int rowsPerGroup;

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      semanticsLabel: context.l10n.profileLoading,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          const _ProfileIntroSkeleton(),
          const SizedBox(height: AppSpacing.space6),
          for (var group = 0; group < groupCount; group++) ...[
            const RikiSkeleton(width: 92, height: 12),
            const SizedBox(height: AppSpacing.space2),
            ProfileSurface(
              child: Column(
                children: [
                  for (var row = 0; row < rowsPerGroup; row++) ...[
                    const _ProfileRowSkeleton(),
                    if (row < rowsPerGroup - 1)
                      const SizedBox(height: AppSpacing.space4),
                  ],
                ],
              ),
            ),
            if (group < groupCount - 1)
              const SizedBox(height: AppSpacing.space6),
          ],
        ],
      ),
    );
  }
}

class _ProfileIntroSkeleton extends StatelessWidget {
  const _ProfileIntroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ProfileSurface(
      child: Row(
        children: [
          RikiSkeleton(width: 48, height: 48),
          SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RikiSkeleton(width: 158, height: 16),
                SizedBox(height: AppSpacing.space2),
                RikiSkeleton(height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRowSkeleton extends StatelessWidget {
  const _ProfileRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        RikiSkeleton(width: 42, height: 42),
        SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RikiSkeleton(width: 132, height: 13),
              SizedBox(height: AppSpacing.space2),
              RikiSkeleton(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

Future<bool> showProfileConfirmationSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  Widget? preview,
  Key? confirmKey,
  bool destructive = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space5,
        AppSpacing.space3,
        AppSpacing.space5,
        AppSpacing.space5 + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          Center(
            child: _ProfileIconBox(
              icon: icon,
              foreground: destructive
                  ? AppColors.errorText
                  : AppColors.brandPrimary,
              background: destructive
                  ? AppColors.errorBackground
                  : AppColors.brandTint,
              size: 54,
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Center(child: preview),
          ],
          const SizedBox(height: AppSpacing.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space5),
          FilledButton(
            key: confirmKey,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.errorBackground,
                    foregroundColor: AppColors.errorText,
                    elevation: 0,
                  )
                : null,
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: Text(confirmLabel),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: Text(cancelLabel),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

class _ProfileIconBox extends StatelessWidget {
  const _ProfileIconBox({
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 42,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Icon(icon, size: size * 0.48, color: foreground),
    );
  }
}
