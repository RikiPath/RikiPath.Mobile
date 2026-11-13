import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_catalog_view.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

// Chỉ lưu lựa chọn bộ lọc UI, tách theo tài khoản; Backend vẫn quyết định cấp độ học.
final lessonCatalogSelectedLevelProvider = StateProvider.family<int?, int?>(
  (ref, userId) => null,
);

class LessonCatalogScreen extends ConsumerStatefulWidget {
  const LessonCatalogScreen({super.key});

  @override
  ConsumerState<LessonCatalogScreen> createState() =>
      _LessonCatalogScreenState();
}

class _LessonCatalogScreenState extends ConsumerState<LessonCatalogScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authenticatedUserIdProvider);
    final selectedLevelId = ref.watch(
      lessonCatalogSelectedLevelProvider(userId),
    );
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: 'Bài học tiếng Nhật',
        subtitle: 'Khám phá bài học theo trình độ JLPT',
        onBack: context.pop,
      ),
      body: SafeArea(
        top: false,
        child: LessonCatalogView(
          selectedLevelId: selectedLevelId,
          onSelectLevel: (id) =>
              ref
                      .read(lessonCatalogSelectedLevelProvider(userId).notifier)
                      .state =
                  id,
          onSetStudyLevel: _setStudyLevel,
        ),
      ),
    );
  }

  Future<void> _setStudyLevel(JlptLevelCatalogItem item) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.changeStudyLevelTitle),
        content: Text(context.l10n.changeStudyLevelConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_current_study_level_change'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      if (repository is! StudyLevelProfileRepository) {
        throw StateError('Không thể cập nhật cấp độ đang học.');
      }
      await (repository as StudyLevelProfileRepository).switchStudyLevel(
        currentStudyLevelId: item.id,
      );
      await ref
          .read(learnerJourneyControllerProvider.notifier)
          .selectCatalogLevel(item);
      ref.invalidate(userProfileControllerProvider);
      ref.invalidate(learningControllerProvider);
      ref.invalidate(standardRoadmapProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đổi cấp độ học. Vui lòng thử lại.'),
        ),
      );
    }
  }
}
