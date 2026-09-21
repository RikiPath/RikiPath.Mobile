import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_components.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _headerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_headerStarted) return;
    _headerStarted = true;
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (reduceMotion) {
      _headerController.value = 1;
    } else {
      _headerController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileControllerProvider);
    final headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: AppBar(
        backgroundColor: AppColors.profileBackground,
        title: FadeTransition(
          opacity: headerAnimation,
          child: Text(context.l10n.profileTitle),
        ),
        actions: [
          FadeTransition(
            opacity: headerAnimation,
            child: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.space3),
              child: RikiLanguageSwitcher(),
            ),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const ProfileSkeleton(),
        error: (error, _) => _ProfileErrorView(
          message: userProfileErrorMessage(error, context.l10n),
          onRetry: () =>
              ref.read(userProfileControllerProvider.notifier).retry(),
        ),
        data: (state) => _ProfileSuccessView(profile: state.profile),
      ),
    );
  }
}

class _ProfileSuccessView extends StatefulWidget {
  const _ProfileSuccessView({required this.profile});

  final UserProfile profile;

  @override
  State<_ProfileSuccessView> createState() => _ProfileSuccessViewState();
}

class _ProfileSuccessViewState extends State<_ProfileSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  bool _entranceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (reduceMotion) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _curved(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _entrance({
    required Widget child,
    required double begin,
    required double end,
    bool scale = false,
  }) {
    final animation = _curved(begin, end);
    Widget result = FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.045),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
    if (scale) {
      result = ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
        child: result,
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.profile;
    final displayName = profile.fullName.isEmpty
        ? l10n.learner
        : profile.fullName;
    final avatarPulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 18),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.045,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.045,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
    ]).animate(_curved(0, 0.82));

    return ListView(
      key: const ValueKey<String>('profile_success_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _entrance(
          begin: 0,
          end: 0.56,
          scale: true,
          child: ProfileHeroCard(
            profile: profile,
            displayName: displayName,
            avatarPulse: avatarPulse,
            onEdit: () => context.push(AppRoutes.profileEdit),
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        _entrance(
          begin: 0.34,
          end: 0.82,
          child: ProfileSection(
            title: l10n.navigationLearn,
            children: [
              ProfileActionTile(
                key: const ValueKey<String>('profile_jlpt_goal_action'),
                icon: Icons.track_changes_outlined,
                title: l10n.jlptGoalSettings,
                subtitle: l10n.jlptGoalSettingsSubtitle,
                emphasized: true,
                onTap: () => context.push(AppRoutes.profileJlptGoal),
              ),
              ProfileActionTile(
                key: const ValueKey<String>('profile_progress_action'),
                icon: Icons.insights_outlined,
                title: l10n.progressAndHistory,
                subtitle: l10n.profileProgressSubtitle,
                onTap: () => context.go(AppRoutes.learnProgress),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        _entrance(
          begin: 0.42,
          end: 0.9,
          child: ProfileSection(
            title: l10n.account,
            children: [
              ProfileActionTile(
                key: const ValueKey<String>('profile_edit_action'),
                icon: Icons.person_outline_rounded,
                title: l10n.profileEdit,
                subtitle: l10n.profileEditSubtitle,
                onTap: () => context.push(AppRoutes.profileEdit),
              ),
              ProfileActionTile(
                key: const ValueKey<String>('profile_settings_action'),
                icon: Icons.settings_outlined,
                title: l10n.settings,
                subtitle: l10n.profileSettingsSubtitle,
                onTap: () => context.push(AppRoutes.profileAccount),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        _entrance(
          begin: 0.5,
          end: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileServicesSection,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space3),
              ProfileServiceCard(
                key: const ValueKey<String>('profile_consultation_action'),
                icon: Icons.support_agent_outlined,
                title: l10n.consultation,
                description: l10n.profileConsultationSubtitle,
                status: l10n.notAvailable,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        key: const ValueKey<String>('profile_error_view'),
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RikiErrorBanner(
                title: context.l10n.profileLoadFailedTitle,
                message: message,
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiSecondaryButton(
                key: const ValueKey<String>('profile_retry_button'),
                label: context.l10n.retry,
                leadingIcon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
