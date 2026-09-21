import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.avatarUrl,
    required this.radius,
    this.showRing = false,
    this.semanticsLabel,
    super.key,
  });

  final String? avatarUrl;
  final double radius;
  final bool showRing;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final uri = avatarUrl == null ? null : Uri.tryParse(avatarUrl!);
    final canLoad =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        padding: showRing ? const EdgeInsets.all(3) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: showRing
              ? Border.all(color: AppColors.brandSecondary, width: 2)
              : null,
          boxShadow: showRing ? AppShadows.cardSoft : const <BoxShadow>[],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: AppColors.brandTint,
            child: canLoad
                ? Image.network(
                    avatarUrl!,
                    key: const ValueKey<String>('profile_avatar_image'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.person_outline_rounded,
      key: const ValueKey<String>('profile_avatar_fallback'),
      size: radius,
      color: AppColors.brandPrimary,
    );
  }
}

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    required this.profile,
    required this.displayName,
    required this.onEdit,
    this.avatarPulse,
    super.key,
  });

  final UserProfile profile;
  final String displayName;
  final VoidCallback onEdit;
  final Animation<double>? avatarPulse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = profile.supportedJlptLevel;
    final pulse = avatarPulse;

    return Semantics(
      container: true,
      label: '${l10n.profileTitle}: $displayName',
      child: Container(
        key: const ValueKey<String>('profile_hero_card'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.neutralShadow,
              offset: Offset(0, 8),
              blurRadius: 28,
              spreadRadius: -9,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -34,
              top: -42,
              child: _HeroDecoration(size: 128, opacity: 0.24),
            ),
            const Positioned(
              left: -28,
              bottom: -48,
              child: _HeroDecoration(size: 92, opacity: 0.14),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: pulse ?? kAlwaysCompleteAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: pulse?.value ?? 1,
                          child: child,
                        ),
                        child: ProfileAvatar(
                          avatarUrl: profile.avatarUrl,
                          radius: 42,
                          showRing: true,
                          semanticsLabel: displayName,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: AppColors.brandPrimary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: const ValueKey<String>(
                              'profile_hero_avatar_edit',
                            ),
                            customBorder: const CircleBorder(),
                            onTap: onEdit,
                            child: Semantics(
                              button: true,
                              label: l10n.editAvatar,
                              child: const SizedBox.square(
                                dimension: 44,
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 18,
                                  color: AppColors.surface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.compactPageTitle.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          profile.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        Wrap(
                          spacing: AppSpacing.space2,
                          runSpacing: AppSpacing.space2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _VerificationPill(
                              verified: profile.isEmailVerified,
                            ),
                            if (level != null) JlptBadge(level),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandSecondary.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.textSecondary;
    final background = verified
        ? AppColors.successBackgroundSoft
        : AppColors.inputProcessing;
    return Container(
      key: ValueKey<String>(
        verified ? 'profile_verified_status' : 'profile_unverified_status',
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified_rounded
                : Icons.mark_email_unread_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.space1),
          Flexible(
            child: Text(
              verified ? context.l10n.verified : context.l10n.unverified,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.badgeText.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
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
                      indent: 70,
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

class ProfileActionTile extends StatefulWidget {
  const ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  State<ProfileActionTile> createState() => _ProfileActionTileState();
}

class ProfileServiceCard extends StatelessWidget {
  const ProfileServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.profileAccentSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(icon, color: AppColors.brandPrimary, size: 23),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(description, style: AppTypography.metadata),
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    status,
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTileState extends State<ProfileActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final accent = widget.emphasized
        ? AppColors.brandPrimary
        : AppColors.textSecondary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.title,
      child: AnimatedScale(
        scale: !reduceMotion && _pressed ? 0.985 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: enabled
                ? (value) => setState(() => _pressed = value)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.emphasized
                          ? AppColors.brandTint
                          : AppColors.profileBackground,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Icon(widget.icon, size: 21, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTypography.cardTitle),
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled
                        ? AppColors.textMuted
                        : AppColors.textDisabled,
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

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      semanticsLabel: context.l10n.profileLoading,
      child: ListView(
        key: const ValueKey<String>('profile_loading_view'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: const [
          _ProfileHeroSkeleton(),
          SizedBox(height: AppSpacing.space6),
          RikiSkeleton(width: 92, height: 18),
          SizedBox(height: AppSpacing.space3),
          _ProfileActionGroupSkeleton(itemCount: 2),
          SizedBox(height: AppSpacing.space6),
          RikiSkeleton(width: 112, height: 18),
          SizedBox(height: AppSpacing.space3),
          _ProfileActionGroupSkeleton(itemCount: 2),
        ],
      ),
    );
  }
}

class _ProfileHeroSkeleton extends StatelessWidget {
  const _ProfileHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile_hero_skeleton'),
      height: 158,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.neutralShadow,
            offset: Offset(0, 8),
            blurRadius: 28,
            spreadRadius: -9,
          ),
        ],
      ),
      child: const Row(
        children: [
          RikiSkeleton(width: 84, height: 84, shape: BoxShape.circle),
          SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RikiSkeleton(width: 134, height: 20),
                SizedBox(height: AppSpacing.space2),
                RikiSkeleton(height: 13),
                SizedBox(height: AppSpacing.space3),
                RikiSkeleton(
                  width: 94,
                  height: 24,
                  borderRadius: AppRadius.pill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionGroupSkeleton extends StatelessWidget {
  const _ProfileActionGroupSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardSoft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          children: [
            for (var index = 0; index < itemCount; index++) ...[
              const _ProfileActionRowSkeleton(),
              if (index < itemCount - 1)
                const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 70,
                  endIndent: AppSpacing.space4,
                  color: AppColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileActionRowSkeleton extends StatelessWidget {
  const _ProfileActionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            RikiSkeleton(width: 42, height: 42),
            SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RikiSkeleton(width: 128, height: 14),
                  SizedBox(height: AppSpacing.space2),
                  RikiSkeleton(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
