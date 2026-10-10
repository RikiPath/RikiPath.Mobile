import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_join_intent_controller.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_join_target.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';

class MeetingJoinScreen extends ConsumerStatefulWidget {
  const MeetingJoinScreen({super.key});

  @override
  ConsumerState<MeetingJoinScreen> createState() => _MeetingJoinScreenState();
}

class _MeetingJoinScreenState extends ConsumerState<MeetingJoinScreen> {
  late final TextEditingController _linkController;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(
      text: ref.read(meetingJoinIntentControllerProvider).rawLink,
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    ref
        .read(meetingJoinIntentControllerProvider.notifier)
        .submit(_linkController.text);
  }

  void _cancel() {
    ref.read(meetingJoinIntentControllerProvider.notifier).clear();
    _linkController.clear();
    if (context.canPop()) context.pop();
  }

  Future<void> _openMeeting(MeetingJoinTarget target) async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    final opened = await ref
        .read(mentorMeetingLinkLauncherProvider)
        .open(target.uri);
    if (!mounted) return;
    setState(() => _isOpening = false);
    if (opened) {
      ref.read(meetingJoinIntentControllerProvider.notifier).clear();
      return;
    }
    ref
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: context.l10n.meetingOpenFailedTitle,
          description: context.l10n.meetingOpenFailedDescription,
        );
  }

  @override
  Widget build(BuildContext context) {
    final intent = ref.watch(meetingJoinIntentControllerProvider);
    final session = ref.watch(authSessionControllerProvider);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(meetingJoinIntentControllerProvider.notifier).clear();
        }
      },
      child: Scaffold(
        key: const ValueKey<String>('meeting_join_screen'),
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(context.l10n.meetingTitle),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: [
              Text(
                context.l10n.meetingJoinTitle,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.meetingJoinDescription,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiTextField(
                key: const ValueKey<String>('meeting_link_field'),
                label: context.l10n.meetingLinkLabel,
                hintText: context.l10n.meetingLinkHint,
                controller: _linkController,
                prefixIcon: Icons.link,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                errorText: switch (intent.validationError) {
                  MeetingLinkValidationError.empty =>
                    context.l10n.meetingLinkRequired,
                  MeetingLinkValidationError.invalid =>
                    context.l10n.meetingLinkInvalid,
                  null => null,
                },
                onChanged: (value) {
                  ref
                      .read(meetingJoinIntentControllerProvider.notifier)
                      .updateRawLink(value);
                },
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (!intent.hasPendingTarget)
                RikiPrimaryButton(
                  key: const ValueKey<String>('meeting_continue_button'),
                  label: context.l10n.meetingContinueAction,
                  trailingIcon: Icons.arrow_forward,
                  onPressed: _continue,
                )
              else
                ValueListenableBuilder<AuthSessionState>(
                  valueListenable: session,
                  builder: (context, authState, _) {
                    if (authState == AuthSessionState.authenticated) {
                      return _AuthenticatedJoinCard(
                        host: intent.target!.uri.host,
                        isOpening: _isOpening,
                        onJoin: () => _openMeeting(intent.target!),
                        onCancel: _cancel,
                      );
                    }
                    return _AuthRequiredCard(
                      onLogin: () => context.push(AppRoutes.login),
                      onRegister: () => context.push(AppRoutes.register),
                      onCancel: _cancel,
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.space4),
              RikiInfoBanner(
                icon: Icons.lock_outline,
                message: context.l10n.meetingAuthorizationNotice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthRequiredCard extends StatelessWidget {
  const _AuthRequiredCard({
    required this.onLogin,
    required this.onRegister,
    required this.onCancel,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      key: const ValueKey<String>('meeting_auth_required'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.meetingAuthRequiredTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            context.l10n.meetingAuthRequiredDescription,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space4),
          RikiPrimaryButton(
            key: const ValueKey<String>('meeting_login_button'),
            label: context.l10n.login,
            onPressed: onLogin,
          ),
          const SizedBox(height: AppSpacing.space2),
          RikiSecondaryButton(
            key: const ValueKey<String>('meeting_register_button'),
            label: context.l10n.register,
            onPressed: onRegister,
          ),
          RikiTextButton(label: context.l10n.cancel, onPressed: onCancel),
        ],
      ),
    );
  }
}

class _AuthenticatedJoinCard extends StatelessWidget {
  const _AuthenticatedJoinCard({
    required this.host,
    required this.isOpening,
    required this.onJoin,
    required this.onCancel,
  });

  final String host;
  final bool isOpening;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      key: const ValueKey<String>('meeting_prejoin_card'),
      boxShadow: AppShadows.cardSoft,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  context.l10n.meetingReadyTitle,
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(host, style: AppTypography.metadata),
          const SizedBox(height: AppSpacing.space4),
          RikiPrimaryButton(
            key: const ValueKey<String>('meeting_open_button'),
            label: context.l10n.meetingEnterRoom,
            leadingIcon: Icons.open_in_new,
            isLoading: isOpening,
            onPressed: onJoin,
          ),
          const SizedBox(height: AppSpacing.space2),
          RikiTextButton(label: context.l10n.cancel, onPressed: onCancel),
        ],
      ),
    );
  }
}
