import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/change_password_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_syncUnsavedState);
    _newPasswordController.addListener(_syncUnsavedState);
    _confirmPasswordController.addListener(_syncUnsavedState);
  }

  void _syncUnsavedState() {
    final dirty =
        _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
    if (dirty != _hasUnsavedChanges && mounted) {
      setState(() => _hasUnsavedChanges = dirty);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_syncUnsavedState);
    _newPasswordController.removeListener(_syncUnsavedState);
    _confirmPasswordController.removeListener(_syncUnsavedState);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final succeeded = await ref
        .read(changePasswordControllerProvider.notifier)
        .submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted || !succeeded) return;
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(changePasswordControllerProvider);
    final session = ref.watch(authSessionControllerProvider);
    final userId = session.currentUserId;
    final backFallback = session.currentRole == BackendUserRole.mentor
        ? AppRoutes.mentorProfile
        : AppRoutes.profileAccount;
    final hasUnsavedChanges = _hasUnsavedChanges && !state.isLoading;
    final canPopRoute =
        !hasUnsavedChanges &&
        (GoRouter.maybeOf(context)?.canPop() ??
            (ModalRoute.of(context)?.canPop ?? true));

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: backFallback,
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
        backgroundColor: AppColors.profileBackground,
        appBar: ProfileDetailHeader(
          title: l10n.changePassword,
          onBack: () => handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: backFallback,
          ),
        ),
      body: ProfileAnimatedEntrance(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            ProfileDetailIntro(
              icon: Icons.lock_reset_rounded,
              colorfulIcon: SakuraColorfulIconType.password,
              title: l10n.protectAccountTitle,
              description: l10n.passwordContractHint,
            ),
            const SizedBox(height: AppSpacing.space6),
            if (userId == null) ...[
              RikiErrorBanner(
                title: l10n.missingSessionTitle,
                message: l10n.missingSessionMessage,
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
            ProfileFormSection(
              child: Column(
                children: [
                  RikiPasswordField(
                    key: const Key('change_password_current_field'),
                    label: l10n.currentPassword,
                    hintText: l10n.currentPasswordHint,
                    controller: _currentPasswordController,
                    errorText: state.currentPasswordError,
                    enabled: userId != null && !state.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => ref
                        .read(changePasswordControllerProvider.notifier)
                        .clearFeedback(),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  RikiPasswordField(
                    key: const Key('change_password_new_field'),
                    label: l10n.newPassword,
                    hintText: l10n.newPasswordHint,
                    controller: _newPasswordController,
                    errorText: state.newPasswordError,
                    enabled: userId != null && !state.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => ref
                        .read(changePasswordControllerProvider.notifier)
                        .clearFeedback(),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  RikiPasswordField(
                    key: const Key('change_password_confirm_field'),
                    label: l10n.confirmNewPassword,
                    hintText: l10n.confirmNewPasswordHint,
                    controller: _confirmPasswordController,
                    errorText: state.confirmPasswordError,
                    enabled: userId != null && !state.isLoading,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => ref
                        .read(changePasswordControllerProvider.notifier)
                        .clearFeedback(),
                    onSubmitted: (_) {
                      if (userId != null && !state.isLoading) _submit();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            ProfileFormSection(
              title: l10n.passwordRequirementsTitle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      l10n.passwordMinimumRequirement,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: Column(
                children: [
                  if (state.serverError != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    RikiErrorBanner(
                      title: l10n.changePasswordFailedTitle,
                      message: state.serverError!,
                    ),
                  ],
                  if (state.succeeded) ...[
                    const SizedBox(height: AppSpacing.space4),
                    RikiSuccessBanner(
                      message: l10n.passwordUpdatedSessionMessage,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            RikiPrimaryButton(
              key: const Key('change_password_submit_button'),
              label: l10n.changePassword,
              loadingLabel: l10n.changingPassword,
              isLoading: state.isLoading,
              onPressed: userId == null ? null : _submit,
            ),
          ],
        ),
      ),
        ),
        AppLoadingOverlay(
          visible: state.isLoading,
          title: l10n.loadingOverlaySavingTitle,
          subtitle: l10n.loadingOverlayUpdatingSubtitle,
        ),
      ],
      ),
    );
  }
}
