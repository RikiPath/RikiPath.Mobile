import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_content_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_shared_widgets.dart';
import 'package:video_player/video_player.dart';

class LessonVideoView extends StatelessWidget {
  const LessonVideoView({
    required this.session,
    required this.videoController,
    required this.onTogglePlayback,
    required this.onRetry,
    required this.onShowArticle,
    required this.onSelectTab,
    required this.onComplete,
    super.key,
  });

  final LessonSession session;
  final VideoPlayerController? videoController;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRetry;
  final VoidCallback onShowArticle;
  final ValueChanged<LessonContentTab> onSelectTab;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final lesson = session.lesson;
    return ListView(
      key: const ValueKey<String>('lesson_video_view'),
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      children: [
        _LessonVideoFrame(
          session: session,
          videoController: videoController,
          onTogglePlayback: onTogglePlayback,
          onRetry: onRetry,
          onShowArticle: onShowArticle,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonMetadataWrap(lesson: lesson),
              const SizedBox(height: AppSpacing.space2),
              Text(
                lesson.title,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              Text(
                lesson.focus,
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              LessonProgressMeter(progress: lesson.progress),
              const SizedBox(height: AppSpacing.space4),
              LessonContentTabs(
                lesson: lesson,
                selectedTab: session.selectedTab,
                onSelected: onSelectTab,
              ),
              const SizedBox(height: AppSpacing.space4),
              if (session.selectedTab == LessonContentTab.vocabulary)
                LessonVocabularyContent(lesson: lesson)
              else
                LessonArticleContent(lesson: lesson),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('lesson_complete_button'),
                label: context.l10n.completeLesson,
                leadingIcon: Icons.check_circle_outline,
                onPressed: onComplete,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonVideoFrame extends StatelessWidget {
  const _LessonVideoFrame({
    required this.session,
    required this.videoController,
    required this.onTogglePlayback,
    required this.onRetry,
    required this.onShowArticle,
  });

  final LessonSession session;
  final VideoPlayerController? videoController;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRetry;
  final VoidCallback onShowArticle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        key: ValueKey<String>(
          'lesson_video_status_${session.videoStatus.name}',
        ),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF253044), Color(0xFF0F172A)],
          ),
        ),
        child: session.videoStatus == LessonVideoStatus.error
            ? _VideoError(
                message:
                    session.videoErrorMessage ?? context.l10n.videoLoadFailed,
                onRetry: onRetry,
                onShowArticle: onShowArticle,
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (videoController != null &&
                      videoController!.value.isInitialized)
                    VideoPlayer(videoController!),
                  const Align(
                    alignment: Alignment(0.42, -0.1),
                    child: Icon(
                      Icons.school_outlined,
                      size: 78,
                      color: Color(0x33FFFFFF),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.space4,
                    top: AppSpacing.space3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        session.lesson.progress.resumePositionSeconds > 0
                            ? context.l10n.watchingInProgress
                            : context.l10n.hdLecture,
                        style: AppTypography.badgeText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: IconButton.filled(
                      key: const ValueKey<String>('lesson_video_toggle_button'),
                      tooltip: _playbackTooltip(context),
                      onPressed:
                          session.videoStatus == LessonVideoStatus.loading
                          ? null
                          : onTogglePlayback,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.square(58),
                      ),
                      icon: session.videoStatus == LessonVideoStatus.loading
                          ? RikiInlineLoader(
                              size: 22,
                              color: Colors.white,
                              semanticsLabel: context.l10n.loading,
                            )
                          : Icon(
                              session.videoStatus == LessonVideoStatus.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 32,
                            ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.space4,
                    right: AppSpacing.space4,
                    bottom: AppSpacing.space3,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: session.videoProgressPercent / 100,
                            minHeight: 5,
                            color: AppColors.brandPrimary,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          children: [
                            Text(
                              formatLessonTime(
                                session.lesson.progress.resumePositionSeconds,
                              ),
                              style: AppTypography.badgeText.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' / ${formatLessonTime(session.lesson.durationSeconds)}',
                              style: AppTypography.badgeText.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${session.videoProgressPercent}%',
                              style: AppTypography.badgeText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _playbackTooltip(BuildContext context) {
    return session.videoStatus == LessonVideoStatus.playing
        ? context.l10n.pauseVideo
        : context.l10n.resumeVideoFrom(
            formatLessonTime(session.lesson.progress.resumePositionSeconds),
          );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({
    required this.message,
    required this.onRetry,
    required this.onShowArticle,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onShowArticle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 32),
          const SizedBox(height: AppSpacing.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.cardTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            context.l10n.articleFallbackMessage,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: AppTypography.metadata.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey<String>('lesson_video_retry_button'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: Text(context.l10n.retry),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('lesson_show_article_button'),
                  onPressed: onShowArticle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.article_outlined, size: 17),
                  label: Text(context.l10n.viewArticle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
