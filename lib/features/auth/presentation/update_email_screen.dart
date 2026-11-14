import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/update_email_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/domain/verify_email_arguments.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class UpdateEmailScreen extends ConsumerStatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  ConsumerState<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends ConsumerState<UpdateEmailScreen> {
  final _emailController = TextEditingController();
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final hasDraft = _emailController.text.trim().isNotEmpty;
    if (hasDraft != _hasDraft && mounted) {
      setState(() => _hasDraft = hasDraft);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(updateEmailControllerProvider.notifier)
        .submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(updateEmailControllerProvider);
    final session = ref.watch(authSessionControllerProvider);
    final userId = session.currentUserId;
    final currentEmail = session.currentRole == BackendUserRole.mentor
        ? ref.watch(mentorProfileControllerProvider).value?.email
        : ref.watch(userProfileControllerProvider).value?.profile.email;
    final backFallback = session.currentRole == BackendUserRole.mentor
        ? AppRoutes.mentorProfile
        : AppRoutes.profileAccount;
    final hasUnsavedChanges = _hasDraft && !state.succeeded && !state.isLoading;

    return PopScope(
      canPop: !hasUnsavedChanges,
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
          title: l10n.changeEmail,
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
              icon: Icons.mark_email_read_outlined,
              title: l10n.newLoginEmailTitle,
              description: l10n.newLoginEmailSubtitle,
            ),
            if (currentEmail != null) ...[
              const SizedBox(height: AppSpacing.space6),
              ProfileSettingsGroup(
                children: [
                  ProfileSettingsTile(
                    icon: Icons.alternate_email_rounded,
                    title: l10n.currentEmailLabel,
                    subtitle: currentEmail,
                    onTap: null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.space6),
            if (userId == null) ...[
              RikiErrorBanner(
                title: l10n.missingSessionTitle,
                message: l10n.missingSessionMessage,
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
            ProfileFormSection(
              child: RikiTextField(
                key: const Key('update_email_field'),
                label: l10n.newEmail,
                hintText: l10n.newEmailHint,
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                errorText: state.emailError,
                enabled: userId != null && !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) => ref
                    .read(updateEmailControllerProvider.notifier)
                    .clearFeedback(),
                onSubmitted: (_) {
                  if (userId != null && !state.isLoading) _submit();
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: Column(
                children: [
                  if (state.serverError != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    RikiErrorBanner(
                      title: l10n.changeEmailFailedTitle,
                      message: state.serverError!,
                    ),
                  ],
                  if (state.succeeded) ...[
                    const SizedBox(height: AppSpacing.space4),
                    RikiSuccessBanner(
                      message: l10n.emailUpdatedVerificationMessage,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            RikiPrimaryButton(
              key: const Key('update_email_submit_button'),
              label: l10n.updateEmail,
              loadingLabel: l10n.updatingEmail,
              isLoading: state.isLoading,
              onPressed: userId == null ? null : _submit,
            ),
            if (state.succeeded && userId != null) ...[
              const SizedBox(height: AppSpacing.space3),
              RikiSecondaryButton(
                key: const Key('update_email_verify_action'),
                label: l10n.enterVerificationCode,
                trailingIcon: Icons.arrow_forward,
                onPressed: () => context.push(
                  session.currentRole == BackendUserRole.mentor
                      ? AppRoutes.mentorVerifyEmail
                      : AppRoutes.profileVerifyEmail,
                  extra: VerifyEmailArguments(
                    userId: userId,
                    email: _emailController.text.trim(),
                  ),
                ),
              ),
            ],
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
