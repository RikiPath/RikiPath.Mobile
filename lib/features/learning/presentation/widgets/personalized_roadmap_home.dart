import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_learning_journey_map.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';

/// Chỉ hiển thị lộ trình AI đang hoạt động; bài học có sẵn thuộc Thư viện.
class PersonalizedRoadmapHome extends ConsumerWidget {
  const PersonalizedRoadmapHome({required this.onShowLessons, super.key});

  final VoidCallback onShowLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathState = ref.watch(activeLearningPathProvider);
    return pathState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _RoadmapMessage(
        title: 'Chưa tải được lộ trình',
        description:
            'Vui lòng kiểm tra kết nối rồi thử lại. Bài học có sẵn vẫn có thể truy cập.',
        onPrimary: () => ref.invalidate(activeLearningPathProvider),
        primaryLabel: 'Thử lại',
        onShowLessons: onShowLessons,
      ),
      data: (path) {
        if (path?.status == LearningPathStatus.active) {
          return _ActiveRoadmap(path: path!);
        }
        final placementState = ref.watch(placementTestStatusProvider);
        return placementState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _RoadmapMessage(
            title: 'Chưa tải được trạng thái đánh giá',
            description:
                'Vui lòng kiểm tra kết nối rồi thử lại. Bài học có sẵn vẫn có thể truy cập.',
            onPrimary: () => ref.invalidate(placementTestStatusProvider),
            primaryLabel: 'Thử lại',
            onShowLessons: onShowLessons,
          ),
          data: (placement) => !placement.hasCompletedPlacementTest
              ? _RoadmapMessage(
                  title: 'Bạn chưa có lộ trình cá nhân hóa',
                  description:
                      'Hoàn thành bài đánh giá đầu vào để RikiPath đề xuất lộ trình phù hợp với năng lực và mục tiêu JLPT của bạn.',
                  onPrimary: () => context.push(AppRoutes.placementTest),
                  primaryLabel: 'Làm bài đánh giá đầu vào',
                  onShowLessons: onShowLessons,
                )
              : _NoActiveRoadmap(
                  isEligible: placement.isReadyForLearningPath,
                  onShowLessons: onShowLessons,
                ),
        );
      },
    );
  }
}

class _NoActiveRoadmap extends ConsumerWidget {
  const _NoActiveRoadmap({
    required this.isEligible,
    required this.onShowLessons,
  });

  final bool isEligible;
  final VoidCallback onShowLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestState = ref.watch(learningPathControllerProvider);
    return latestState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _RoadmapMessage(
        title: 'Chưa tải được bản xem trước',
        description: 'Vui lòng kiểm tra kết nối rồi thử lại.',
        primaryLabel: 'Thử lại',
        onPrimary: () => ref.invalidate(learningPathControllerProvider),
        onShowLessons: onShowLessons,
      ),
      data: (latest) {
        if (latest?.status == LearningPathStatus.active) {
          return _ActiveRoadmap(path: latest!);
        }
        final hasDraft = latest?.status == LearningPathStatus.draft;
        return _RoadmapMessage(
          title: hasDraft
              ? 'Bản xem trước đang chờ xác nhận'
              : isEligible
              ? 'Bạn đã hoàn thành đánh giá đầu vào'
              : 'Cần hoàn thiện mục tiêu học tập',
          description: hasDraft
              ? 'Xem và xác nhận lộ trình đề xuất trước khi bắt đầu học.'
              : isEligible
              ? 'Hãy tạo và xác nhận bản xem trước để bắt đầu lộ trình cá nhân hóa.'
              : 'Kết quả đánh giá đã có, nhưng mục tiêu học tập chưa đủ điều kiện tạo lộ trình.',
          onPrimary: isEligible
              ? () => context.push('${AppRoutes.learnRoadmap}?mode=ai')
              : null,
          primaryLabel: hasDraft
              ? 'Xem bản xem trước'
              : 'Tạo lộ trình cá nhân hóa',
          onShowLessons: onShowLessons,
        );
      },
    );
  }
}

class _RoadmapMessage extends StatelessWidget {
  const _RoadmapMessage({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onShowLessons,
    this.onPrimary,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onShowLessons;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('learning_no_personalized_roadmap'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 176,
            child: Image.asset(
              'assets/images/learning/sakura_roadmap_hero.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (onPrimary != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('learning_roadmap_primary_action'),
                      onPressed: onPrimary,
                      child: Text(primaryLabel),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('learning_show_existing_lessons'),
                  onPressed: onShowLessons,
                  child: const Text('Khám phá Thư viện'),
                ),
                const Text(
                  'Bạn vẫn có thể học các bài học có sẵn mà không cần làm bài đánh giá.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveRoadmap extends ConsumerWidget {
  const _ActiveRoadmap({required this.path});

  final RecommendedLearningPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelId = path.startingJlptLevelId;
    final levelsState = ref.watch(jlptCatalogControllerProvider);
    final levels = levelsState.asData?.value;
    final startingLevel = levels
        ?.where((level) => level.id == levelId)
        .firstOrNull;
    final targetLevel = levels
        ?.where((level) => level.id == path.targetJlptLevelId)
        .firstOrNull;
    final rangeResolved =
        startingLevel != null &&
        (path.targetJlptLevelId == null || targetLevel != null);
    final levelIds = rangeResolved
        ? [
            for (final level in levels!)
              if (level.sortOrder >= startingLevel.sortOrder &&
                  level.sortOrder <=
                      (targetLevel?.sortOrder ?? startingLevel.sortOrder))
                level.id,
          ]
        : [?levelId];
    final catalogStates = {
      for (final id in levelIds) id: ref.watch(lessonCatalogProvider(id)),
    };
    final catalog = levelId == null
        ? null
        : catalogStates[levelId]?.asData?.value;
    final progressById = {
      for (final entry in catalogStates.entries)
        if (entry.value.asData?.value case final snapshot?)
          if (snapshot.certificateLevelId == null ||
              snapshot.certificateLevelId == entry.key)
            for (final lesson in snapshot.lessons) lesson.lessonId: lesson,
    };
    final recommendations = path.orderedLessons;
    final allProgressKnown =
        rangeResolved &&
        catalogStates.values.every((state) => state.hasValue) &&
        recommendations.isNotEmpty &&
        recommendations.every(
          (lesson) => progressById.containsKey(lesson.lessonId),
        );
    final next = allProgressKnown
        ? recommendations
              .where(
                (lesson) => progressById[lesson.lessonId]!.isCompleted != true,
              )
              .firstOrNull
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeLearningPathProvider);
        for (final id in levelIds) {
          ref.invalidate(lessonCatalogProvider(id));
        }
        await ref.read(activeLearningPathProvider.future);
      },
      child: ListView(
        key: const PageStorageKey('learning_personalized_roadmap'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 162,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/learning/sakura_roadmap_hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 145,
                      child: Text(
                        'Hành trình của bạn',
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.learnerTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(path.summary, style: AppTypography.bodySmall),
          if (allProgressKnown) ...[
            const SizedBox(height: 6),
            Text(
              'Đã hoàn thành ${recommendations.where((lesson) => progressById[lesson.lessonId]!.isCompleted).length}/${recommendations.length} bài học',
              style: AppTypography.metadata,
            ),
          ],
          const SizedBox(height: 12),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.icon(
                key: const ValueKey('learning_continue_ai_lesson'),
                onPressed: () => context.push(AppRoutes.lesson(next.routeId)),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Tiếp tục học: ${next.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (recommendations.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Lộ trình hiện chưa có bài học được đề xuất.'),
              ),
            ),
          if (levelsState.isLoading ||
              catalogStates.values.any((state) => state.isLoading))
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (levelsState.hasError ||
              catalogStates.values.any((state) => state.hasError))
            TextButton(
              onPressed: () {
                ref.invalidate(jlptCatalogControllerProvider);
                for (final id in levelIds) {
                  ref.invalidate(lessonCatalogProvider(id));
                }
              },
              child: const Text('Thử tải lại tiến độ bài học'),
            ),
          if (allProgressKnown)
            SakuraLearningJourneyMap(
              lessons: [
                for (var i = 0; i < recommendations.length; i++)
                  StandardRoadmapLesson(
                    lessonId: recommendations[i].lessonId,
                    title: recommendations[i].title,
                    sortOrder: i,
                    progressPercent: progressById[recommendations[i].lessonId]!
                        .progressPercent,
                    isCompleted:
                        progressById[recommendations[i].lessonId]!.isCompleted,
                  ),
              ],
              currentStudyLevelName:
                  catalog?.jlptTarget.label ?? startingLevel.code,
              nextLessonId: next?.lessonId,
              onOpenLesson: (id) => context.push(AppRoutes.lesson(id)),
            )
          else if (!levelsState.isLoading &&
              catalogStates.values.every((state) => !state.isLoading)) ...[
            const SizedBox(height: 14),
            const Text(
              'Bài học trong lộ trình',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tiến độ chưa được xác nhận cho toàn bộ bài học; danh sách dưới đây chỉ hiển thị đề xuất từ lộ trình.',
            ),
            for (final lesson in recommendations)
              Card(
                child: ListTile(
                  title: Text(lesson.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.lesson(lesson.routeId)),
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('${AppRoutes.learnRoadmap}?mode=ai'),
            child: const Text('Quản lý lộ trình'),
          ),
        ],
      ),
    );
  }
}
