import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/register_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/verify_email_arguments.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/register_success_celebration.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          acceptedTerms: _acceptedTerms,
        );
  }

  void _clearFeedback() {
    ref.read(registerControllerProvider.notifier).clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Locale>(localeControllerProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        ref.read(registerControllerProvider.notifier).clearFeedback();
      }
    });
    final l10n = context.l10n;
    final state = ref.watch(registerControllerProvider);
    if (state.succeeded) {
      return _RegisterSuccess(
        email: state.registeredAccount!.email,
        userId: state.registeredAccount!.userId,
        onVerifyEmail: () {
          final userId = state.registeredAccount!.userId;
          ref.read(registerControllerProvider.notifier).reset();
          context.go(
            AppRoutes.verifyEmail,
            extra: VerifyEmailArguments(
              userId: userId,
              email: state.registeredAccount!.email,
            ),
          );
        },
        onReturnToLogin: () {
          ref.read(registerControllerProvider.notifier).reset();
          context.go(AppRoutes.login);
        },
      );
    }

    return AuthPage(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(),
              const SizedBox(height: AppSpacing.space6),
              Align(
                alignment: Alignment.centerLeft,
                child: RikiPromotionalPill(message: l10n.authPromotion),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(l10n.registerTitle, style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.space1),
              Text(
                l10n.registerSubtitle,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              RikiTextField(
                key: const Key('register_full_name_field'),
                label: l10n.fullName,
                hintText: l10n.fullNameHint,
                controller: _fullNameController,
                prefixIcon: Icons.person_outline,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiTextField(
                key: const Key('register_email_field'),
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
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('register_password_field'),
                label: l10n.password,
                hintText: l10n.passwordHint,
                controller: _passwordController,
                errorText: state.passwordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearFeedback(),
              ),
              if (state.passwordError == null) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Expanded(
                      child: Text(
                        l10n.minimumSixCharacters,
                        style: AppTypography.metadata,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('register_confirm_password_field'),
                label: l10n.confirmPassword,
                hintText: l10n.confirmPasswordHint,
                controller: _confirmPasswordController,
                errorText: state.confirmPasswordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              RikiCheckboxRow(
                value: _acceptedTerms,
                compact: true,
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        setState(() => _acceptedTerms = value ?? false);
                        _clearFeedback();
                      },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.termsPrefix),
                      TextSpan(
                        text: l10n.termsOfService,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: l10n.termsJoiner),
                      TextSpan(
                        text: l10n.privacyPolicy,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: l10n.termsSuffix),
                    ],
                  ),
                ),
              ),
              if (state.agreementError != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.space6),
                  child: Text(
                    state.agreementError!,
                    style: AppTypography.validationText,
                  ),
                ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                RikiErrorBanner(
                  title: l10n.registerFailedTitle,
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const Key('register_submit_button'),
                label: l10n.register,
                loadingLabel: l10n.creatingAccount,
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              if (state.isLoading) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiWarningBanner(
                  icon: Icons.hourglass_bottom,
                  message: l10n.creatingAccountMessage,
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiProgressIndicator(
                  semanticsLabel: l10n.creatingAccountSemantics,
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              children: [
                AuthNavigationPrompt(
                  message: l10n.alreadyHaveAccount,
                  actionLabel: l10n.login,
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(AppRoutes.login),
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

class _RegisterSuccess extends StatefulWidget {
  const _RegisterSuccess({
    required this.email,
    required this.userId,
    required this.onVerifyEmail,
    required this.onReturnToLogin,
  });

  final String email;
  final int userId;
  final VoidCallback onVerifyEmail;
  final VoidCallback onReturnToLogin;

  @override
  State<_RegisterSuccess> createState() => _RegisterSuccessState();
}

class _RegisterSuccessState extends State<_RegisterSuccess>
    with SingleTickerProviderStateMixin {
  static const _celebrationDuration = Duration(milliseconds: 1800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _celebrationDuration,
  );
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
      _hasStarted = true;
      return;
    }
    if (_hasStarted) return;

    _hasStarted = true;
    _controller.forward();
    _triggerSuccessHaptic();
  }

  void _triggerSuccessHaptic() {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        unawaited(HapticFeedback.lightImpact());
        return;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPage(
      animateEntrance: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RikiAuthHeader(statusLabel: l10n.accountCreatedStatus),
              const SizedBox(height: AppSpacing.space10),
              Center(
                child: RegisterSuccessCelebration(
                  key: const Key('register_success_celebration'),
                  animation: _controller,
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              SuccessContentEntrance(
                key: const Key('register_success_title_entrance'),
                animation: _controller,
                start: 0.16,
                end: 0.36,
                child: Text(
                  l10n.accountCreatedTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.heroTitle,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              SuccessContentEntrance(
                key: const Key('register_success_support_entrance'),
                animation: _controller,
                start: 0.22,
                end: 0.42,
                child: Text(
                  l10n.accountCreatedMessage(widget.email),
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              SuccessContentEntrance(
                key: const Key('register_success_status_entrance'),
                animation: _controller,
                start: 0.30,
                end: 0.50,
                child: RikiSuccessBanner(message: l10n.checkEmailVerification),
              ),
              const SizedBox(height: AppSpacing.space4),
              SuccessContentEntrance(
                key: const Key('register_success_warning_entrance'),
                animation: _controller,
                start: 0.38,
                end: 0.58,
                child: RikiWarningBanner(
                  icon: Icons.mark_email_unread_outlined,
                  message: l10n.verificationCodeValidity,
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
                  key: const Key('register_open_verify_email_button'),
                  label: l10n.enterVerificationCode,
                  trailingIcon: Icons.arrow_forward,
                  onPressed: widget.onVerifyEmail,
                ),
                const SizedBox(height: AppSpacing.space2),
                RikiTextButton(
                  label: l10n.returnToLogin,
                  onPressed: widget.onReturnToLogin,
                ),
                const SizedBox(height: AppSpacing.space4),
                const AuthSecurityFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
