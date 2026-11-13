import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';

final learningPathRepositoryProvider = Provider<LearningPathRepository>(
  (ref) => ApiLearningPathRepository(ref.watch(apiClientProvider)),
);

/// The roadmap tab must never present a draft/latest path as the active plan.
final activeLearningPathProvider = FutureProvider<RecommendedLearningPath?>((
  ref,
) async {
  ref.watch(authenticatedUserIdProvider);
  final repository = ref.watch(learningPathRepositoryProvider);
  if (repository is! LearningPathVersionRepository) return null;
  try {
    return await (repository as LearningPathVersionRepository).loadActive();
  } on NotFoundError {
    return null;
  }
});

final learningPathControllerProvider =
    AsyncNotifierProvider<LearningPathController, RecommendedLearningPath?>(
      LearningPathController.new,
      retry: (_, _) => null,
    );

class LearningPathController extends AsyncNotifier<RecommendedLearningPath?> {
  @override
  FutureOr<RecommendedLearningPath?> build() async {
    ref.watch(authenticatedUserIdProvider);
    try {
      return await ref.watch(learningPathRepositoryProvider).loadLatest();
    } on NotFoundError {
      return null;
    }
  }

  Future<bool> generate() async {
    if (state.isLoading) return false;
    state = const AsyncLoading<RecommendedLearningPath?>();
    try {
      final path = await ref.read(learningPathRepositoryProvider).generate();
      state = AsyncData(path);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  void showServerPath(RecommendedLearningPath path) {
    state = AsyncData(path);
  }
}
