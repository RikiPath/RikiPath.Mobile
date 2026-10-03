import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/login_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberSession = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final succeeded = await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
          rememberSession: _rememberSession,
        );
    if (!mounted) return;
    if (succeeded) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Locale>(localeControllerProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        ref.read(loginControllerProvider.notifier).clearFeedback();
      }
    });
    final l10n = context.l10n;
    final state = ref.watch(loginControllerProvider);
    final hasFeedback =
        state.emailError != null ||
        state.passwordError != null ||
        state.serverError != null;

    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(),
              const SizedBox(height: AppSpacing.space8),
              Align(
                alignment: Alignment.centerLeft,
                child: RikiPromotionalPill(message: l10n.authPromotion),
              ),
              const SizedBox(height: AppSpacing.space5),
              Text(l10n.loginWelcome, style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.loginSubtitle,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              RikiTextField(
                key: const Key('login_email_field'),
                label: l10n.studentEmail,
                hintText: l10n.emailHint,
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                suffixIcon: state.isLoading
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                errorText: state.emailError,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) =>
                    ref.read(loginControllerProvider.notifier).clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('login_password_field'),
                label: l10n.password,
                hintText: l10n.passwordHint,
                controller: _passwordController,
                errorText: state.passwordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.done,
                onChanged: (_) =>
                    ref.read(loginControllerProvider.notifier).clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: RikiTextButton(
                  key: const Key('forgot_password_button'),
                  label: l10n.forgotPassword,
                  onPressed: state.isLoading
                      ? null
                      : () => context.push(AppRoutes.forgotPassword),
                ),
              ),
              RikiCheckboxRow(
                value: _rememberSession,
                compact: true,
                centerChild: true,
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        setState(() => _rememberSession = value ?? false);
                      },
                child: Text(l10n.rememberSession),
              ),
              const SizedBox(height: AppSpacing.space2),
              RikiPrimaryButton(
                key: const Key('login_submit_button'),
                label: l10n.login,
                loadingLabel: l10n.loggingIn,
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              if (state.isLoading) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiWarningBanner(
                  icon: Icons.hourglass_bottom,
                  message: l10n.loginSecureConnection,
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiProgressIndicator(semanticsLabel: l10n.loggingInSemantics),
              ] else if (!hasFeedback) ...[
                const SizedBox(height: AppSpacing.space5),
                RikiWarningBanner(
                  title: l10n.loginTipTitle,
                  message: l10n.loginTipMessage,
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              children: [
                AuthNavigationPrompt(
                  message: l10n.noAccount,
                  actionLabel: l10n.register,
                  onPressed: state.isLoading
                      ? null
                      : () => context.push(AppRoutes.register),
                ),
                const AuthSecurityFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
