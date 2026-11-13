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
  const LearningRoadmapScreen({this.aiOnly = false, super.key});

  final bool aiOnly;

  @override
  ConsumerState<LearningRoadmapScreen> createState() =>
      _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends ConsumerState<LearningRoadmapScreen> {
  bool _isPreparingPreview = false;
  String? _previewError;
  int? _updatingDay;
  String? _dayError;

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(standardRoadmapProvider);
    final placementState = ref.watch(placementTestStatusProvider);
    final pathState = ref.watch(learningPathControllerProvider);
    final activeState = ref.watch(activeLearningPathProvider);
    final activePath = activeState.asData?.value;
    final latestPath = pathState.asData?.value;
    final roadmap = roadmapState.asData?.value;
    final placement = placementState.asData?.value;
    final eligible =
        placement?.hasCompletedPlacementTest == true &&
        placement?.isReadyForLearningPath == true;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: widget.aiOnly
            ? context.l10n.aiPersonalizedPathTitle
            : context.l10n.standardRoadmapTitle,
        subtitle: widget.aiOnly
            ? 'Xem và quản lý hành trình học của bạn'
            : roadmap == null
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
            showStandard: !widget.aiOnly,
            roadmap: data,
            onOpenLesson: (lessonId) =>
                context.push(AppRoutes.lesson(lessonId)),
            onRefresh: () => _refresh(ref),
            canGenerateAiPath: eligible,
            hasCompletedPlacement: placement?.hasCompletedPlacementTest == true,
            isGeneratingAiPath: pathState.isLoading || _isPreparingPreview,
            aiPathError:
                _previewError ?? _pathError(context, pathState, placementState),
            aiPath: activePath ?? latestPath,
            hasPendingPreview:
                latestPath?.status == LearningPathStatus.draft &&
                latestPath?.pathId != null,
            onUpdateAiDay: _updateAiDay,
            updatingAiDay: _updatingDay,
            aiDayError: _dayError,
            onGenerateAiPath: () async {
              if (eligible) {
                if (latestPath?.status == LearningPathStatus.draft &&
                    latestPath?.pathId != null) {
                  _showExistingPreview(latestPath!);
                } else if (activePath != null || latestPath != null) {
                  _previewReplacement(data);
                } else {
                  final generated = await ref
                      .read(learningPathControllerProvider.notifier)
                      .generate();
                  if (generated) ref.invalidate(activeLearningPathProvider);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateAiDay(int day, {required bool complete}) async {
    if (_updatingDay != null) return;
    setState(() {
      _updatingDay = day;
      _dayError = null;
    });
    try {
      final repository = ref.read(learningPathRepositoryProvider);
      if (repository is! LearningPathDayRepository) {
        throw StateError('Learning Path day actions are unavailable.');
      }
      final dayRepository = repository as LearningPathDayRepository;
      final updated = complete
          ? await dayRepository.completeDay(day)
          : await dayRepository.startDay(day);
      ref.read(learningPathControllerProvider.notifier).showServerPath(updated);
      ref.invalidate(activeLearningPathProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dayError = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không thể cập nhật ngày học. Vui lòng thử lại.',
        );
      });
    } finally {
      if (mounted) setState(() => _updatingDay = null);
    }
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
      await _presentPreview(preview, versionRepository);
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

  Future<void> _showExistingPreview(RecommendedLearningPath preview) async {
    final repository = ref.read(learningPathRepositoryProvider);
    if (repository is! LearningPathVersionRepository) return;
    await _presentPreview(preview, repository as LearningPathVersionRepository);
  }

  Future<void> _presentPreview(
    RecommendedLearningPath preview,
    LearningPathVersionRepository repository,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LearningPathPreviewDialog(
        preview: preview,
        repository: repository,
        onChanged: () {
          ref.invalidate(learningPathControllerProvider);
          ref.invalidate(activeLearningPathProvider);
        },
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(standardRoadmapProvider);
    ref.invalidate(placementTestStatusProvider);
    ref.invalidate(learningPathControllerProvider);
    ref.invalidate(activeLearningPathProvider);
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
    required this.onChanged,
  });

  final RecommendedLearningPath preview;
  final LearningPathVersionRepository repository;
  final VoidCallback onChanged;

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
      } else {
        await widget.repository.cancelPreview(pathId);
      }
      widget.onChanged();
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
              const Text(
                'Lộ trình đang học chỉ được thay thế sau khi bạn xác nhận. '
                'Tiến độ và lịch sử bài học cũ vẫn được lưu.',
              ),
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
