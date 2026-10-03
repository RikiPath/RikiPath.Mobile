import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/forgot_password_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Locale>(localeControllerProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        ref.read(forgotPasswordControllerProvider.notifier).clearFeedback();
      }
    });
    final l10n = context.l10n;
    final state = ref.watch(forgotPasswordControllerProvider);
    if (state.succeeded) {
      return _ForgotPasswordSuccess(
        email: state.submittedEmail!,
        onReturnToLogin: () {
          ref.read(forgotPasswordControllerProvider.notifier).reset();
          context.go(AppRoutes.login);
        },
      );
    }

    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RikiAuthHeader(
                onBack: () => context.go(AppRoutes.login),
                backSemanticLabel: l10n.returnToLogin,
              ),
              const SizedBox(height: AppSpacing.space10),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    border: Border.all(color: AppColors.brandBorder),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 36,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                l10n.forgotPasswordTitle,
                textAlign: TextAlign.center,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.forgotPasswordSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space10),
              RikiTextField(
                key: const Key('forgot_email_field'),
                label: l10n.registeredEmail,
                hintText: l10n.emailHint,
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                errorText: state.emailError,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) => ref
                    .read(forgotPasswordControllerProvider.notifier)
                    .clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiErrorBanner(
                  title: l10n.passwordRecoveryUnavailableTitle,
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
              RikiPrimaryButton(
                key: const Key('forgot_submit_button'),
                label: l10n.sendRequest,
                loadingLabel: l10n.sendingRequest,
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.space3),
              RikiSecondaryButton(
                label: l10n.returnToLogin,
                leadingIcon: Icons.arrow_back,
                onPressed: state.isLoading
                    ? null
                    : () => context.go(AppRoutes.login),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space8),
            child: AuthHelpFooter(),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordSuccess extends StatelessWidget {
  const _ForgotPasswordSuccess({
    required this.email,
    required this.onReturnToLogin,
  });

  final String email;
  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RikiAuthHeader(statusLabel: l10n.requestSentStatus),
              const SizedBox(height: AppSpacing.space10),
              const Center(
                child: AuthSuccessIllustration(icon: Icons.mail_outline),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                l10n.requestSentTitle,
                textAlign: TextAlign.center,
                style: AppTypography.heroTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.forgotPasswordSentBody(email),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              RikiSuccessBanner(message: l10n.forgotPasswordCheckEmail),
              const SizedBox(height: AppSpacing.space4),
              RikiWarningBanner(
                icon: Icons.info_outline,
                message: l10n.forgotPasswordSpamHint,
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                l10n.forgotPasswordResend,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RikiPrimaryButton(
                  label: l10n.returnToLogin,
                  onPressed: onReturnToLogin,
                ),
                const SizedBox(height: AppSpacing.space4),
                AuthHelpFooter(
                  prefix: l10n.helpAccountPrefix,
                  actionLabel: l10n.helpCenter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
