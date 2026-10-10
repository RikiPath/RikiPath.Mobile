import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/writing_practice/application/writing_practice_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/engine/writing_practice_engine.dart';

class WritingPracticeDetailScreen extends ConsumerWidget {
  const WritingPracticeDetailScreen({
    required this.script,
    required this.characterId,
    super.key,
  });

  final WritingScript script;
  final int? characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = characterId;
    final request = WritingQueueRequest(
      script: script,
      kanjiCollection: script == WritingScript.kanji
          ? KanjiWritingCollection.all
          : KanjiWritingCollection.due,
    );
    if (id == null || id <= 0) {
      return _InvalidWritingCharacterScreen(script: script);
    }
    final queue = ref.watch(writingPracticeControllerProvider(request));
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.writingTitle)),
      body: queue.when(
        loading: () =>
            RikiFullScreenLoader(title: context.l10n.writingLoadingStrokeData),
        error: (error, _) => RikiErrorState(
          title: context.l10n.writingLoadFailed,
          message: appErrorMessage(error, context.l10n),
          actionLabel: context.l10n.retry,
          onAction: () => ref
              .read(writingPracticeControllerProvider(request).notifier)
              .retry(),
        ),
        data: (state) {
          final item = state.items.where((entry) => entry.id == id).firstOrNull;
          if (item == null) {
            return _InvalidWritingCharacterScreen(script: script);
          }
          return _WritingPracticeSession(
            key: ValueKey<String>('writing_session_${script.name}_$id'),
            request: request,
            state: state,
            character: item,
          );
        },
      ),
    );
  }
}

class _WritingPracticeSession extends ConsumerStatefulWidget {
  const _WritingPracticeSession({
    required this.request,
    required this.state,
    required this.character,
    super.key,
  });

  final WritingQueueRequest request;
  final WritingPracticeState state;
  final WritingCharacter character;

  @override
  ConsumerState<_WritingPracticeSession> createState() =>
      _WritingPracticeSessionState();
}

class _WritingPracticeSessionState
    extends ConsumerState<_WritingPracticeSession>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final WritingPracticeEngine _engine;
  WritingPracticeResult? _handledResult;
  final Set<int> _activeWritingPointers = <int>{};

  bool get _isWritingGestureActive => _activeWritingPointers.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ref.read(writingPracticeEngineFactoryProvider).create(this);
    _engine.listenable.addListener(_handleEngineUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(writingPracticeControllerProvider(widget.request).notifier)
          .selectCharacter(widget.character.id);
    });
    unawaited(_loadCharacter());
  }

  @override
  void didUpdateWidget(_WritingPracticeSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _releaseWritingGestureLock();
      _handledResult = null;
      unawaited(_loadCharacter());
    }
  }

  Future<void> _loadCharacter() {
    return _engine.loadCharacter(
      character: widget.character.character,
      script: widget.character.script,
    );
  }

  void _handleEngineUpdate() {
    if (!mounted) return;
    final snapshot = _engine.snapshot;
    if (snapshot.phase == WritingEnginePhase.completed) {
      _releaseWritingGestureLock();
    }
    final result = snapshot.result;
    if (snapshot.phase != WritingEnginePhase.completed ||
        result == null ||
        identical(result, _handledResult)) {
      return;
    }
    _handledResult = result;
    unawaited(
      ref
          .read(writingPracticeControllerProvider(widget.request).notifier)
          .completePractice(result),
    );
  }

  void _handleWritingPointerDown(PointerDownEvent event) {
    if (_activeWritingPointers.add(event.pointer)) {
      setState(() {});
    }
  }

  void _handleWritingPointerEnd(PointerEvent event) {
    if (_activeWritingPointers.remove(event.pointer)) {
      setState(() {});
    }
  }

  void _releaseWritingGestureLock() {
    if (_activeWritingPointers.isEmpty) return;
    _activeWritingPointers.clear();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _releaseWritingGestureLock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeWritingPointers.clear();
    _engine.listenable.removeListener(_handleEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref
        .watch(writingPracticeControllerProvider(widget.request))
        .value;
    final effectiveState = state ?? widget.state;
    return ListView(
      key: const ValueKey<String>('writing_detail_view'),
      physics: _isWritingGestureActive
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _TargetCharacterCard(character: widget.character),
        if (widget.character.script == WritingScript.kanji) ...[
          const SizedBox(height: AppSpacing.space3),
          _ModeControl(
            value: effectiveState.practiceMode,
            onChanged: (mode) {
              _releaseWritingGestureLock();
              ref
                  .read(
                    writingPracticeControllerProvider(widget.request).notifier,
                  )
                  .setPracticeMode(mode);
              _handledResult = null;
              _engine.reset();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        _WritingCanvasCard(
          engine: _engine,
          guided:
              effectiveState.practiceMode == WritingPracticeMode.guided ||
              widget.character.script != WritingScript.kanji,
          isWritingGestureActive: _isWritingGestureActive,
          onPointerDown: _handleWritingPointerDown,
          onPointerUp: _handleWritingPointerEnd,
          onPointerCancel: _handleWritingPointerEnd,
          onRetry: _loadCharacter,
        ),
        const SizedBox(height: AppSpacing.space4),
        _WritingControls(
          engine: _engine,
          state: effectiveState,
          character: widget.character,
          onReset: () {
            _releaseWritingGestureLock();
            ref
                .read(
                  writingPracticeControllerProvider(widget.request).notifier,
                )
                .resetPractice();
            _handledResult = null;
            _engine.reset();
          },
          onRetrySubmission: () => unawaited(
            ref
                .read(
                  writingPracticeControllerProvider(widget.request).notifier,
                )
                .retrySubmission(),
          ),
          onNext: _next,
        ),
      ],
    );
  }

  void _next() {
    _releaseWritingGestureLock();
    final nextId = ref
        .read(writingPracticeControllerProvider(widget.request).notifier)
        .selectNextCharacter();
    if (nextId == null) {
      context.go(_scriptRoute(widget.character.script));
      return;
    }
    context.go(_detailRoute(widget.character.script, nextId));
  }
}

class _TargetCharacterCard extends StatelessWidget {
  const _TargetCharacterCard({required this.character});

  final WritingCharacter character;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.brandBorder.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Text(
              character.character,
              style: AppTypography.heroTitle.copyWith(fontSize: 58, height: 1),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.writingTargetLabel,
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  character.romaji ??
                      character.meaning ??
                      context.l10n.writingMeaningUnavailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space1,
                  children: [
                    _InfoPill(
                      label: context.l10n.writingStrokeCount(
                        character.strokeCount,
                      ),
                    ),
                    _InfoPill(
                      label: character.isNew
                          ? context.l10n.writingNewCharacter
                          : context.l10n.writingReviewCharacter,
                      accent: character.isNew
                          ? AppColors.brandPrimary
                          : AppColors.success,
                    ),
                  ],
                ),
                if (character.script == WritingScript.kanji) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '${context.l10n.writingOnReading}: '
                    '${character.onYomi ?? context.l10n.writingReadingUnavailable}',
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    '${context.l10n.writingKunReading}: '
                    '${character.kunYomi ?? context.l10n.writingReadingUnavailable}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.accent = AppColors.textSecondary});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        child: Text(
          label,
          style: AppTypography.badgeText.copyWith(color: accent),
        ),
      ),
    );
  }
}

class _ModeControl extends StatelessWidget {
  const _ModeControl({required this.value, required this.onChanged});

  final WritingPracticeMode value;
  final ValueChanged<WritingPracticeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space1),
        child: Row(
          children: [
            for (final mode in WritingPracticeMode.values)
              Expanded(
                child: Material(
                  color: mode == value
                      ? AppColors.brandTint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                  child: InkWell(
                    key: ValueKey<String>('writing_mode_${mode.name}'),
                    onTap: () => onChanged(mode),
                    borderRadius: BorderRadius.circular(AppRadius.compact),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                      child: Text(
                        mode == WritingPracticeMode.guided
                            ? context.l10n.writingGuidedMode
                            : context.l10n.writingFreeMode,
                        textAlign: TextAlign.center,
                        style: AppTypography.badgeText.copyWith(
                          color: mode == value
                              ? AppColors.brandPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WritingCanvasCard extends StatelessWidget {
  const _WritingCanvasCard({
    required this.engine,
    required this.guided,
    required this.isWritingGestureActive,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onRetry,
  });

  final WritingPracticeEngine engine;
  final bool guided;
  final bool isWritingGestureActive;
  final PointerDownEventListener onPointerDown;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: ListenableBuilder(
        listenable: engine.listenable,
        builder: (context, _) {
          final snapshot = engine.snapshot;
          return Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final extent = constraints.maxWidth
                      .clamp(220.0, 320.0)
                      .toDouble();
                  return Center(
                    child: SizedBox.square(
                      dimension: extent,
                      child: Listener(
                        key: const ValueKey<String>(
                          'writing_canvas_pointer_region',
                        ),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: snapshot.hasCanvas
                            ? onPointerDown
                            : null,
                        onPointerUp: snapshot.hasCanvas ? onPointerUp : null,
                        onPointerCancel: snapshot.hasCanvas
                            ? onPointerCancel
                            : null,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            border: Border.all(
                              color: isWritingGestureActive
                                  ? AppColors.brandPrimary
                                  : AppColors.border,
                              width: isWritingGestureActive
                                  ? AppBorders.emphasized
                                  : AppBorders.thin,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const CustomPaint(
                                  painter: _WritingGridPainter(),
                                ),
                                if (snapshot.hasCanvas)
                                  engine.buildCanvas(
                                    size: Size.square(extent),
                                    key: ValueKey<String>(
                                      'writing_engine_${snapshot.character}',
                                    ),
                                  ),
                                if (snapshot.phase ==
                                    WritingEnginePhase.loading)
                                  Center(
                                    child: RikiInlineLoader(
                                      semanticsLabel:
                                          context.l10n.writingLoadingStrokeData,
                                    ),
                                  ),
                                if (snapshot.phase == WritingEnginePhase.failed)
                                  _StrokeLoadFailure(onRetry: onRetry),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                _engineHint(context, snapshot, guided),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.writingGestureHint,
                key: const ValueKey<String>('writing_gesture_hint'),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StrokeLoadFailure extends StatelessWidget {
  const _StrokeLoadFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.errorText,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              context.l10n.writingStrokeDataFailedTitle,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              context.l10n.writingStrokeDataFailedMessage,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space3),
            RikiTextButton(
              label: context.l10n.retry,
              leadingIcon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _WritingControls extends StatelessWidget {
  const _WritingControls({
    required this.engine,
    required this.state,
    required this.character,
    required this.onReset,
    required this.onRetrySubmission,
    required this.onNext,
  });

  final WritingPracticeEngine engine;
  final WritingPracticeState state;
  final WritingCharacter character;
  final VoidCallback onReset;
  final VoidCallback onRetrySubmission;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine.listenable,
      builder: (context, _) {
        final snapshot = engine.snapshot;
        final result = state.localResult ?? snapshot.result;
        final ready = snapshot.phase == WritingEnginePhase.ready;
        final busy =
            snapshot.phase == WritingEnginePhase.animating ||
            snapshot.phase == WritingEnginePhase.quizzing ||
            state.submissionStatus == WritingSubmissionStatus.submitting;
        return Column(
          children: [
            if (result == null) ...[
              Row(
                children: [
                  Expanded(
                    child: RikiSecondaryButton(
                      key: const ValueKey<String>('writing_demo_button'),
                      label: context.l10n.writingShowStrokes,
                      leadingIcon: Icons.play_circle_outline,
                      onPressed: ready ? engine.showStrokeAnimation : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: RikiPrimaryButton(
                      key: const ValueKey<String>('writing_start_button'),
                      label: context.l10n.writingStart,
                      leadingIcon: Icons.draw_outlined,
                      onPressed: ready
                          ? () => engine.startQuiz(
                              guided:
                                  state.practiceMode ==
                                      WritingPracticeMode.guided ||
                                  character.script != WritingScript.kanji,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _WritingResultCard(
                character: character,
                result: result,
                state: state,
              ),
              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: RikiSecondaryButton(
                      key: const ValueKey<String>('writing_reset_button'),
                      label: context.l10n.writingRewrite,
                      leadingIcon: Icons.refresh,
                      onPressed: busy ? null : onReset,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: RikiPrimaryButton(
                      key: const ValueKey<String>('writing_next_button'),
                      label: context.l10n.writingNext,
                      trailingIcon: Icons.arrow_forward,
                      onPressed:
                          state.submissionStatus ==
                              WritingSubmissionStatus.succeeded
                          ? onNext
                          : null,
                    ),
                  ),
                ],
              ),
            ],
            if (state.canRetrySubmission) ...[
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                width: double.infinity,
                child: RikiSecondaryButton(
                  key: const ValueKey<String>('writing_retry_submit_button'),
                  label: context.l10n.writingRetrySave,
                  leadingIcon: Icons.cloud_upload_outlined,
                  onPressed: onRetrySubmission,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WritingResultCard extends StatelessWidget {
  const _WritingResultCard({
    required this.character,
    required this.result,
    required this.state,
  });

  final WritingCharacter character;
  final WritingPracticeResult result;
  final WritingPracticeState state;

  @override
  Widget build(BuildContext context) {
    final status = state.submissionStatus;
    final isFailure = status == WritingSubmissionStatus.failed;
    final accent = isFailure ? AppColors.warning : AppColors.success;
    final background = isFailure
        ? AppColors.warningBackground
        : AppColors.successBackgroundSoft;
    final statusText = switch (status) {
      WritingSubmissionStatus.idle => context.l10n.writingCompleteTitle,
      WritingSubmissionStatus.submitting => context.l10n.writingSavingResult,
      WritingSubmissionStatus.succeeded => context.l10n.writingResultSaved,
      WritingSubmissionStatus.failed => context.l10n.writingResultSaveFailed,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.banner),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isFailure ? Icons.cloud_off_outlined : Icons.check_circle,
              color: accent,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.writingCompleteTitle,
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Wrap(
                    spacing: AppSpacing.space3,
                    runSpacing: AppSpacing.space1,
                    children: [
                      Text(
                        context.l10n.writingMistakeCount(result.totalMistakes),
                        style: AppTypography.bodySmall,
                      ),
                      if (character.script == WritingScript.kanji)
                        Text(
                          context.l10n.writingResultScore(
                            result.scoreFor(character.strokeCount),
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    statusText,
                    style: AppTypography.bodySmall.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            if (status == WritingSubmissionStatus.submitting)
              RikiInlineLoader(
                size: 18,
                color: accent,
                semanticsLabel: context.l10n.writingSavingResult,
              ),
          ],
        ),
      ),
    );
  }
}

class _InvalidWritingCharacterScreen extends StatelessWidget {
  const _InvalidWritingCharacterScreen({required this.script});

  final WritingScript script;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.writingTitle)),
      body: RikiEmptyState(
        icon: Icons.edit_off_outlined,
        title: context.l10n.writingEmptyTitle,
        message: context.l10n.commonErrorNotFound,
        actionLabel: context.l10n.back,
        onAction: () => context.go(_scriptRoute(script)),
      ),
    );
  }
}

String _engineHint(
  BuildContext context,
  WritingEngineSnapshot snapshot,
  bool guided,
) => switch (snapshot.phase) {
  WritingEnginePhase.loading => context.l10n.writingLoadingStrokeData,
  WritingEnginePhase.animating => context.l10n.writingAnimationInProgress,
  WritingEnginePhase.quizzing => context.l10n.writingQuizInProgress,
  WritingEnginePhase.completed => context.l10n.writingCompleteTitle,
  _ => guided ? context.l10n.writingGuidedHint : context.l10n.writingFreeHint,
};

String _scriptRoute(WritingScript script) => switch (script) {
  WritingScript.hiragana => AppRoutes.writingHiragana,
  WritingScript.katakana => AppRoutes.writingKatakana,
  WritingScript.kanji => AppRoutes.writingKanji,
};

String _detailRoute(WritingScript script, int id) => switch (script) {
  WritingScript.hiragana => AppRoutes.writingHiraganaDetail(id),
  WritingScript.katakana => AppRoutes.writingKatakanaDetail(id),
  WritingScript.kanji => AppRoutes.writingKanjiDetail(id),
};

class _WritingGridPainter extends CustomPainter {
  const _WritingGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const dash = 6.0;
    const gap = 5.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(
        Offset(centerX, y),
        Offset(centerX, (y + dash).clamp(0, size.height).toDouble()),
        paint,
      );
    }
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset((x + dash).clamp(0, size.width).toDouble(), centerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WritingGridPainter oldDelegate) => false;
}
