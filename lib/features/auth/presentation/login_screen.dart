import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_hourglass_overlay.dart';
import 'package:rikipath_mobile/features/auth/application/login_controller.dart';
import 'package:rikipath_mobile/features/auth/application/mentor_registration_intent.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_join_intent_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _rememberSession = true;
  bool _openingMentorRegistration = false;

  Future<void> _openMentorRegistration() async {
    if (_openingMentorRegistration) return;
    setState(() => _openingMentorRegistration = true);
    try {
      await ref.read(mentorRegistrationIntentProvider).mark();
      if (mounted) context.push(AppRoutes.mentorRegister);
    } finally {
      if (mounted) setState(() => _openingMentorRegistration = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(loginControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    final router = GoRouter.of(context);
    final succeeded = await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
          rememberSession: _rememberSession,
        );
    if (!mounted) return;
    if (succeeded) {
      final applyAsMentor = await ref
          .read(mentorRegistrationIntentProvider)
          .consume();
      final hasPendingMeeting = ref
          .read(meetingJoinIntentControllerProvider)
          .hasPendingTarget;
      final role = ref.read(authSessionControllerProvider).currentRole;
      router.go(
        hasPendingMeeting
            ? AppRoutes.meetingJoin
            : applyAsMentor && role == BackendUserRole.learner
            ? AppRoutes.mentorApplication
            : role == BackendUserRole.learner
            ? AppRoutes.learnerStartup
            : AppRoutes.home,
      );
    }
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

    return Stack(
      fit: StackFit.expand,
      children: [
        AuthPage(
          topContentOffset: AppSpacing.space12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
                  Text(l10n.loginWelcome, style: AppTypography.pageTitle),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    l10n.loginSubtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  RikiTextField(
                    key: const Key('login_email_field'),
                    label: l10n.studentEmail,
                    hintText: l10n.emailHint,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    prefixIcon: Icons.mail_outline,
                    errorText: state.emailError,
                    enabled: !state.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    onChanged: (_) => ref
                        .read(loginControllerProvider.notifier)
                        .clearFeedback(),
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
                    onChanged: (_) => ref
                        .read(loginControllerProvider.notifier)
                        .clearFeedback(),
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
                  const SizedBox(height: AppSpacing.space3),
                  SizedBox(
                    height: 54,
                    child: RikiPrimaryButton(
                      key: const Key('login_submit_button'),
                      label: l10n.login,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space4),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: RikiPrimaryButton(
                        key: const Key('public_mentor_registration_entry'),
                        label: l10n.registerAsMentor,
                        loadingLabel: l10n.registerAsMentor,
                        leadingIcon: Icons.volunteer_activism_outlined,
                        backgroundColor: AppColors.mentorAction,
                        pressedColor: AppColors.mentorActionPressed,
                        isLoading: _openingMentorRegistration,
                        onPressed: state.isLoading
                            ? null
                            : _openMentorRegistration,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AuthNavigationPrompt(
                      message: l10n.noAccount,
                      actionLabel: l10n.register,
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(mentorRegistrationIntentProvider)
                                  .clear();
                              if (context.mounted) {
                                context.push(AppRoutes.register);
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    const AuthSecurityFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
        SakuraHourglassOverlay(
          visible: state.isLoading,
          message: l10n.loggingIn,
        ),
      ],
    );
  }
}
