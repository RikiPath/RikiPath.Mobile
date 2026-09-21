import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/verify_email_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.userId, super.key});

  final int? userId;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(verifyEmailControllerProvider.notifier)
        .submit(userId: widget.userId, verificationCode: _codeController.text);
  }

  void _finish() {
    final session = ref.read(authSessionControllerProvider);
    final l10n = ref.read(appLocalizationsProvider);
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(
          title: l10n.toastVerifyEmailSuccessTitle,
          description: session.value == AuthSessionState.authenticated
              ? l10n.emailVerifiedMessage
              : l10n.toastVerifyEmailSuccessDescription,
        );
    ref.read(verifyEmailControllerProvider.notifier).reset();
    context.go(
      session.value == AuthSessionState.authenticated
          ? AppRoutes.profileAccount
          : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(verifyEmailControllerProvider);
    if (state.succeeded) {
      return AuthPage(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RikiAuthHeader(statusLabel: l10n.emailVerifiedStatus),
                const SizedBox(height: AppSpacing.space10),
                const Center(
                  child: AuthSuccessIllustration(
                    icon: Icons.mark_email_read_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                Text(
                  l10n.verifyEmailSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.heroTitle,
                ),
                const SizedBox(height: AppSpacing.space4),
                RikiSuccessBanner(message: l10n.emailVerifiedMessage),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space8),
              child: RikiPrimaryButton(
                key: const Key('verify_email_finish_button'),
                label: l10n.continueLabel,
                trailingIcon: Icons.arrow_forward,
                onPressed: _finish,
              ),
            ),
          ],
        ),
      );
    }

    final isBlocked = widget.userId == null;
    return AuthPage(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RikiAuthHeader(statusLabel: l10n.verifyEmailStatus),
              const SizedBox(height: AppSpacing.space8),
              Text(l10n.verifyEmailTitle, style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.verifyEmailInputSubtitle,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              if (isBlocked) ...[
                RikiWarningBanner(
                  title: l10n.verifyEmailBlockedTitle,
                  message: l10n.verifyEmailBlockedMessage,
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              RikiTextField(
                key: const Key('verify_email_code_field'),
                label: l10n.verificationCode,
                hintText: l10n.verificationCodeHint,
                controller: _codeController,
                prefixIcon: Icons.pin_outlined,
                errorText: state.codeError,
                enabled: !isBlocked && !state.isLoading,
                keyboardType: const TextInputType.numberWithOptions(),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: !isBlocked,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => ref
                    .read(verifyEmailControllerProvider.notifier)
                    .clearFeedback(),
                onSubmitted: (_) {
                  if (!isBlocked && !state.isLoading) _submit();
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      l10n.verificationCodeValidity,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiErrorBanner(
                  title: l10n.verifyEmailFailedTitle,
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const Key('verify_email_submit_button'),
                label: l10n.verify,
                loadingLabel: l10n.verifying,
                isLoading: state.isLoading,
                onPressed: isBlocked ? null : _submit,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: AuthNavigationPrompt(
              message: l10n.verifiedPrompt,
              actionLabel: l10n.login,
              onPressed: state.isLoading
                  ? null
                  : () => context.go(AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }
}
