import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/standard_roadmap_view.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';

class LearningRoadmapScreen extends ConsumerStatefulWidget {
  const LearningRoadmapScreen({super.key});

  @override
  ConsumerState<LearningRoadmapScreen> createState() =>
      _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends ConsumerState<LearningRoadmapScreen> {
  bool _isPreparingPreview = false;
  String? _previewError;

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(standardRoadmapProvider);
    final placementState = ref.watch(placementTestStatusProvider);
    final pathState = ref.watch(learningPathControllerProvider);
    final roadmap = roadmapState.asData?.value;
    final placement = placementState.asData?.value;
    final eligible =
        placement?.hasCompletedPlacementTest == true &&
        placement?.isReadyForLearningPath == true;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.standardRoadmapTitle,
        subtitle: roadmap == null
            ? context.l10n.loadingRoadmap
            : context.l10n.standardRoadmapProgress(
                roadmap.completedLessons,
                roadmap.totalLessons,
              ),
        onBack: () => _goBack(context),
      ),
      body: SafeArea(
        top: false,
        child: roadmapState.when(
          loading: () => const LearningLoadingView(),
          error: (error, _) => LearningErrorView(
            onRetry: () => ref.invalidate(standardRoadmapProvider),
          ),
          data: (data) => StandardRoadmapView(
            roadmap: data,
            onOpenLesson: (lessonId) =>
                context.push(AppRoutes.lesson(lessonId)),
            onRefresh: () => _refresh(ref),
            canGenerateAiPath: eligible,
            hasCompletedPlacement: placement?.hasCompletedPlacementTest == true,
            isGeneratingAiPath: pathState.isLoading || _isPreparingPreview,
            aiPathError:
                _previewError ?? _pathError(context, pathState, placementState),
            aiPath: pathState.asData?.value,
            onGenerateAiPath: () {
              if (eligible) {
                if (pathState.asData?.value != null) {
                  _previewReplacement(data);
                } else {
                  ref.read(learningPathControllerProvider.notifier).generate();
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _previewReplacement(StandardRoadmap roadmap) async {
    if (_isPreparingPreview) return;
    setState(() {
      _isPreparingPreview = true;
      _previewError = null;
    });
    try {
      final repository = ref.read(learningPathRepositoryProvider);
      if (repository is! LearningPathVersionRepository) {
        throw StateError('Learning Path preview is unavailable.');
      }
      final versionRepository = repository as LearningPathVersionRepository;
      final preview = await versionRepository.preview(
        startingJlptLevelId: roadmap.currentStudyLevelId,
        targetJlptLevelId: roadmap.targetJlptLevelId,
      );
      if (preview.pathId == null) {
        throw const FormatException('Learning Path preview has no ID.');
      }
      if (!mounted) return;
      setState(() => _isPreparingPreview = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _LearningPathPreviewDialog(
          preview: preview,
          repository: versionRepository,
          onConfirmed: () => ref.invalidate(learningPathControllerProvider),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _previewError = appErrorMessage(
          error,
          context.l10n,
          fallback: context.l10n.learningPathPreviewFailed,
        );
      });
    } finally {
      if (mounted) setState(() => _isPreparingPreview = false);
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(standardRoadmapProvider);
    ref.invalidate(placementTestStatusProvider);
    ref.invalidate(learningPathControllerProvider);
    await ref.read(standardRoadmapProvider.future);
  }

  String? _pathError(
    BuildContext context,
    AsyncValue<Object?> pathState,
    AsyncValue<Object?> placementState,
  ) {
    if (placementState.hasError) {
      return appErrorMessage(
        placementState.error!,
        context.l10n,
        fallback: context.l10n.checkConnectionRetry,
      );
    }
    if (pathState.hasError) {
      final error = pathState.error!;
      if (error is ValidationError) {
        return context.l10n.learningPathRequirements;
      }
      return appErrorMessage(
        error,
        context.l10n,
        fallback: context.l10n.learningPathGenerateFailed,
      );
    }
    return null;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.learn);
  }
}

class _LearningPathPreviewDialog extends StatefulWidget {
  const _LearningPathPreviewDialog({
    required this.preview,
    required this.repository,
    required this.onConfirmed,
  });

  final RecommendedLearningPath preview;
  final LearningPathVersionRepository repository;
  final VoidCallback onConfirmed;

  @override
  State<_LearningPathPreviewDialog> createState() =>
      _LearningPathPreviewDialogState();
}

class _LearningPathPreviewDialogState
    extends State<_LearningPathPreviewDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _finish({required bool confirm}) async {
    final pathId = widget.preview.pathId;
    if (_busy || pathId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (confirm) {
        await widget.repository.confirmPreview(pathId);
        widget.onConfirmed();
      } else {
        await widget.repository.cancelPreview(pathId);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: context.l10n.learningPathPreviewFailed,
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey<String>('ai_learning_path_preview_dialog'),
        title: Text(context.l10n.learningPathPreviewTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.preview.summary),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.learningPathPreviewVersion(
                  widget.preview.version ?? 0,
                ),
              ),
              if (_error case final message?) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(message, style: TextStyle(color: AppColors.error)),
              ],
              if (_busy) ...[
                const SizedBox(height: AppSpacing.space2),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey<String>('ai_learning_path_cancel_preview'),
            onPressed: _busy ? null : () => _finish(confirm: false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey<String>('ai_learning_path_confirm_preview'),
            onPressed: _busy ? null : () => _finish(confirm: true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}
