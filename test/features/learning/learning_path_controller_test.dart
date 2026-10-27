import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';

void main() {
  test('generation blocks parallel repeated requests', () async {
    final repository = _ControlledLearningPathRepository();
    final container = ProviderContainer(
      overrides: [learningPathRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(learningPathControllerProvider.future);
    final controller = container.read(learningPathControllerProvider.notifier);

    final first = controller.generate();
    final second = controller.generate();

    expect(repository.calls, 1);
    expect(await second, isFalse);
    repository.result.complete(_path);
    expect(await first, isTrue);
    expect(container.read(learningPathControllerProvider).value, same(_path));
  });

  test('generation exposes a retryable error without a fake plan', () async {
    final container = ProviderContainer(
      overrides: [
        learningPathRepositoryProvider.overrideWithValue(
          const _FailingLearningPathRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(learningPathControllerProvider.future);

    final generated = await container
        .read(learningPathControllerProvider.notifier)
        .generate();

    expect(generated, isFalse);
    expect(container.read(learningPathControllerProvider).hasError, isTrue);
    expect(container.read(learningPathControllerProvider).value, isNull);
  });
}

class _ControlledLearningPathRepository implements LearningPathRepository {
  final Completer<RecommendedLearningPath> result =
      Completer<RecommendedLearningPath>();
  int calls = 0;

  @override
  Future<RecommendedLearningPath?> loadLatest() async => null;

  @override
  Future<RecommendedLearningPath> generate() {
    calls++;
    return result.future;
  }
}

class _FailingLearningPathRepository implements LearningPathRepository {
  const _FailingLearningPathRepository();

  @override
  Future<RecommendedLearningPath?> loadLatest() async => null;

  @override
  Future<RecommendedLearningPath> generate() {
    return Future<RecommendedLearningPath>.error(
      StateError('controlled failure'),
    );
  }
}

final _path = RecommendedLearningPath(
  userId: 42,
  generatedAt: DateTime.utc(2026, 10, 26),
  summary: 'Lộ trình thật',
  strengths: const <String>[],
  weaknesses: const <String>[],
  feasibility: 'Khả thi',
  isExamDateRealistic: true,
  recommendedStudyDays: 1,
  focusTopics: const <String>[],
  dailySchedules: const <RecommendedLearningDay>[],
);
