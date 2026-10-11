import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/speech/application/speech_controller.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  ConsumerState<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen>
    with WidgetsBindingObserver {
  late final SpeechController _speechController;

  @override
  void initState() {
    super.initState();
    _speechController = ref.read(speechControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_speechController.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_speechController.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(speechControllerProvider);
    final controller = _speechController;
    final isListening = state.status == SpeechSessionStatus.listening;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.speechPracticeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            _SpeechHero(isListening: isListening),
            const SizedBox(height: AppSpacing.space5),
            Text(
              context.l10n.speechPracticeHeading,
              style: AppTypography.pageTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              context.l10n.speechPracticeSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            RikiCard(
              backgroundColor: AppColors.surface,
              borderColor: AppColors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.speechSampleLabel,
                    style: AppTypography.badgeText.copyWith(
                      color: AppFeatureTones.speech.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    context.l10n.speechSampleSentence,
                    style: AppTypography.cardTitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            _SpeechStatusBanner(status: state.status),
            const SizedBox(height: AppSpacing.space4),
            RikiCard(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 170),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.speechTranscriptLabel,
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        if (state.transcript.isNotEmpty)
                          IconButton(
                            key: const ValueKey<String>('speech_copy_button'),
                            tooltip: context.l10n.speechCopy,
                            onPressed: () => _copyTranscript(state.transcript),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: state.transcript.isEmpty
                          ? Text(
                              context.l10n.speechTranscriptEmpty,
                              key: const ValueKey<String>(
                                'speech_empty_transcript',
                              ),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            )
                          : SelectableText(
                              state.transcript,
                              key: const ValueKey<String>('speech_transcript'),
                              style: AppTypography.body.copyWith(height: 1.7),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: isListening
                  ? RikiPrimaryButton(
                      key: const ValueKey<String>('speech_stop_button'),
                      label: context.l10n.speechStop,
                      leadingIcon: Icons.stop_circle_outlined,
                      onPressed: controller.stop,
                    )
                  : RikiPrimaryButton(
                      key: const ValueKey<String>('speech_start_button'),
                      label: _startLabel(context, state.status),
                      loadingLabel: context.l10n.speechConnecting,
                      isLoading:
                          state.status ==
                              SpeechSessionStatus.requestingPermission ||
                          state.status == SpeechSessionStatus.ready ||
                          state.status == SpeechSessionStatus.processing,
                      leadingIcon: Icons.mic_none_rounded,
                      onPressed: state.isBusy ? null : controller.start,
                    ),
            ),
            if (state.transcript.isNotEmpty && !state.isBusy) ...[
              const SizedBox(height: AppSpacing.space2),
              RikiTextButton(
                key: const ValueKey<String>('speech_clear_button'),
                label: context.l10n.speechClear,
                leadingIcon: Icons.delete_outline,
                onPressed: controller.clear,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _startLabel(BuildContext context, SpeechSessionStatus status) {
    return switch (status) {
      SpeechSessionStatus.permissionDenied ||
      SpeechSessionStatus.networkError ||
      SpeechSessionStatus.providerError => context.l10n.speechRetry,
      SpeechSessionStatus.completed => context.l10n.speechSpeakAgain,
      _ => context.l10n.speechStart,
    };
  }

  Future<void> _copyTranscript(String transcript) async {
    await Clipboard.setData(ClipboardData(text: transcript));
    if (!mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.speechCopied);
  }
}

class _SpeechHero extends StatelessWidget {
  const _SpeechHero({required this.isListening});

  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        width: isListening ? 132 : 120,
        height: isListening ? 132 : 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppFeatureTones.speech.border
              : AppFeatureTones.speech.background,
          border: Border.all(color: AppFeatureTones.speech.border),
          boxShadow: isListening ? AppShadows.cardSoft : const <BoxShadow>[],
        ),
        child: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppFeatureTones.speech.foreground,
            ),
            child: Icon(
              isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechStatusBanner extends StatelessWidget {
  const _SpeechStatusBanner({required this.status});

  final SpeechSessionStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SpeechSessionStatus.permissionDenied => RikiWarningBanner(
        title: context.l10n.speechPermissionTitle,
        message: context.l10n.speechPermissionMessage,
        icon: Icons.mic_off_outlined,
      ),
      SpeechSessionStatus.networkError => RikiErrorBanner(
        title: context.l10n.speechNetworkTitle,
        message: context.l10n.speechNetworkMessage,
      ),
      SpeechSessionStatus.providerError => RikiErrorBanner(
        title: context.l10n.speechProviderTitle,
        message: context.l10n.speechProviderMessage,
      ),
      SpeechSessionStatus.listening => RikiSuccessBanner(
        title: context.l10n.speechListeningTitle,
        message: context.l10n.speechListeningMessage,
        icon: Icons.hearing_rounded,
      ),
      _ => RikiInfoBanner(
        message: context.l10n.speechReadyMessage,
        icon: Icons.record_voice_over_outlined,
      ),
    };
  }
}
