import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/speech/application/speech_controller.dart';
import 'package:rikipath_mobile/features/speech/data/speech_audio_repository.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  ConsumerState<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen>
    with WidgetsBindingObserver {
  late final SpeechController _speechController;
  final TextEditingController _topicController = TextEditingController();
  int? _selectedLevelId;
  bool _audioBusy = false;
  String? _restTranscript;
  EssayWritingResult? _gradingResult;
  String? _audioError;
  bool _subscriptionRequired = false;

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
    _topicController.dispose();
    unawaited(_speechController.stop());
    super.dispose();
  }

  Future<void> _pickAndTranscribeAudio() async {
    if (_audioBusy) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'webm', 'ogg'],
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _audioBusy = true;
      _audioError = null;
      _subscriptionRequired = false;
    });
    try {
      final text = await ref
          .read(speechAudioRepositoryProvider)
          .transcribeAudio(bytes: bytes, fileName: picked.name);
      if (!mounted) return;
      setState(() {
        _audioBusy = false;
        _restTranscript = text;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioBusy = false;
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
        _audioError = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không chuyển âm thanh thành văn bản được lúc này.',
        );
      });
    }
  }

  Future<void> _pickAndGradeAudio(int levelId) async {
    if (_audioBusy) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'webm', 'ogg'],
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _audioBusy = true;
      _audioError = null;
      _subscriptionRequired = false;
    });
    try {
      final result = await ref
          .read(speechAudioRepositoryProvider)
          .gradeAudio(
            bytes: bytes,
            fileName: picked.name,
            certificateLevelId: levelId,
            topic: _topicController.text,
          );
      if (!mounted) return;
      ref.invalidate(learnerAnalyticsControllerProvider);
      ref.invalidate(learnerStudyHistoryProvider);
      setState(() {
        _audioBusy = false;
        _gradingResult = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioBusy = false;
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
        _audioError = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không chấm điểm bài nói được lúc này.',
        );
      });
    }
  }

  Future<void> _gradeTranscript(int levelId, String text) async {
    if (_audioBusy || text.trim().isEmpty) return;
    setState(() {
      _audioBusy = true;
      _audioError = null;
      _subscriptionRequired = false;
    });
    try {
      final result = await ref
          .read(speechAudioRepositoryProvider)
          .gradeTranscript(
            certificateLevelId: levelId,
            textContent: text,
            topic: _topicController.text,
          );
      if (!mounted) return;
      ref.invalidate(learnerAnalyticsControllerProvider);
      ref.invalidate(learnerStudyHistoryProvider);
      setState(() {
        _audioBusy = false;
        _gradingResult = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioBusy = false;
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
        _audioError = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không chấm điểm bài nói được lúc này.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(speechControllerProvider);
    final controller = _speechController;
    final isListening = state.status == SpeechSessionStatus.listening;
    final displayTranscript = state.transcript.isNotEmpty
        ? state.transcript
        : (_restTranscript ?? '');
    final levels =
        ref.watch(jlptCatalogControllerProvider).value ?? const [];
    final eligibleLevels = levels
        .where((e) => e.level != JlptLevel.n1)
        .toList(growable: false);
    final profile = ref.watch(userProfileControllerProvider).value?.profile;
    final preferredLevelId =
        profile?.targetJlptLevelId ?? profile?.currentStudyLevelId;
    final resolvedLevelId = eligibleLevels.any((e) => e.id == _selectedLevelId)
        ? _selectedLevelId
        : (eligibleLevels.any((e) => e.id == preferredLevelId)
              ? preferredLevelId
              : eligibleLevels.firstOrNull?.id);

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
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.borderSubtlePink,
              boxShadow: AppShadows.sakuraSubtle,
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
              backgroundColor: AppColors.cardWarmWhite,
              borderColor: AppColors.borderSubtlePink,
              boxShadow: AppShadows.sakuraSubtle,
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
                        if (displayTranscript.isNotEmpty)
                          IconButton(
                            key: const ValueKey<String>('speech_copy_button'),
                            tooltip: context.l10n.speechCopy,
                            onPressed: () => _copyTranscript(displayTranscript),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: displayTranscript.isEmpty
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
                              displayTranscript,
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
            if (displayTranscript.isNotEmpty && !state.isBusy) ...[
              const SizedBox(height: AppSpacing.space2),
              RikiTextButton(
                key: const ValueKey<String>('speech_clear_button'),
                label: context.l10n.speechClear,
                leadingIcon: Icons.delete_outline,
                onPressed: () {
                  controller.clear();
                  setState(() {
                    _restTranscript = null;
                    _gradingResult = null;
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            RikiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chấm điểm nói & Tệp ghi âm AI',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  if (eligibleLevels.isNotEmpty)
                    DropdownButtonFormField<int>(
                      key: const ValueKey<String>('speech_level_picker'),
                      initialValue: resolvedLevelId,
                      decoration: const InputDecoration(
                        labelText: 'Cấp độ JLPT chấm nói',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final item in eligibleLevels)
                          DropdownMenuItem<int>(
                            value: item.id,
                            child: Text('JLPT ${item.code}'),
                          ),
                      ],
                      onChanged: _audioBusy
                          ? null
                          : (value) => setState(() => _selectedLevelId = value),
                    ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    key: const ValueKey<String>('speech_topic_field'),
                    controller: _topicController,
                    enabled: !_audioBusy,
                    decoration: const InputDecoration(
                      labelText: 'Chủ đề nói (tùy chọn)',
                      hintText: 'Vd: Giới thiệu bản thân, sở thích...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'speech_upload_transcribe_button',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                        onPressed: _audioBusy ? null : _pickAndTranscribeAudio,
                        icon: const Icon(Icons.audio_file_outlined, size: 18),
                        label: const Text('Tải file chép lời'),
                      ),
                      if (resolvedLevelId != null)
                        OutlinedButton.icon(
                          key: const ValueKey<String>(
                            'speech_upload_grade_button',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                          ),
                          onPressed: _audioBusy
                              ? null
                              : () => _pickAndGradeAudio(resolvedLevelId),
                          icon: const Icon(
                            Icons.grading_outlined,
                            size: 18,
                          ),
                          label: const Text('Chấm file ghi âm'),
                        ),
                      if (resolvedLevelId != null &&
                          displayTranscript.trim().isNotEmpty)
                        FilledButton.tonalIcon(
                          key: const ValueKey<String>(
                            'speech_grade_transcript_button',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                          ),
                          onPressed: _audioBusy
                              ? null
                              : () => _gradeTranscript(
                                  resolvedLevelId,
                                  displayTranscript,
                                ),
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                          ),
                          label: const Text('Chấm điểm AI'),
                        ),
                    ],
                  ),
                  if (_audioBusy) ...[
                    const SizedBox(height: AppSpacing.space3),
                    const LinearProgressIndicator(),
                  ],
                  if (_audioError != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    RikiErrorBanner(message: _audioError!),
                    if (_subscriptionRequired) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('speech_upgrade_button'),
                          onPressed: () =>
                              context.push(AppRoutes.profileSubscriptions),
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: const Text('Xem gói AI / Luyện nói'),
                        ),
                      ),
                    ],
                  ],
                  if (_gradingResult case final gradingRes?) ...[
                    const SizedBox(height: AppSpacing.space3),
                    const Divider(),
                    const SizedBox(height: AppSpacing.space2),
                    if (gradingRes.grading case final g?) ...[
                      Text(
                        'Điểm nói AI: ${g.overallScore.toStringAsFixed(0)}/100',
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final c in g.criteria)
                        Text(
                          '• ${c.name}: ${c.score.toStringAsFixed(1)}/10 — ${c.comment}',
                          style: AppTypography.bodySmall,
                        ),
                      for (final s in g.strengths)
                        Text('✓ $s', style: AppTypography.bodySmall),
                      for (final imp in g.improvements)
                        Text('→ $imp', style: AppTypography.bodySmall),
                    ] else if (gradingRes.gradingNote != null)
                      Text(
                        gradingRes.gradingNote!,
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ],
              ),
            ),
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
