import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/engine/writing_stroke_data_repository.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

final writingPracticeEngineFactoryProvider =
    Provider<WritingPracticeEngineFactory>((ref) {
      return NativeWritingPracticeEngineFactory(
        ref.watch(writingStrokeDataRepositoryProvider),
      );
    });

enum WritingEnginePhase {
  empty,
  loading,
  ready,
  animating,
  quizzing,
  completed,
  failed,
  disposed,
}

@immutable
class WritingEngineSnapshot {
  const WritingEngineSnapshot({
    required this.phase,
    this.character,
    this.totalStrokeCount = 0,
    this.result,
    this.error,
  });

  const WritingEngineSnapshot.empty() : this(phase: WritingEnginePhase.empty);

  final WritingEnginePhase phase;
  final String? character;
  final int totalStrokeCount;
  final WritingPracticeResult? result;
  final Object? error;

  bool get hasCanvas => switch (phase) {
    WritingEnginePhase.ready ||
    WritingEnginePhase.animating ||
    WritingEnginePhase.quizzing ||
    WritingEnginePhase.completed => true,
    _ => false,
  };
}

abstract interface class WritingPracticeEngineFactory {
  WritingPracticeEngine create(TickerProvider tickerProvider);
}

abstract interface class WritingPracticeEngine {
  Listenable get listenable;

  WritingEngineSnapshot get snapshot;

  Future<void> loadCharacter({
    required String character,
    required WritingScript script,
  });

  void showStrokeAnimation();

  void startQuiz({required bool guided});

  void reset();

  Widget buildCanvas({required Size size, Key? key});

  void dispose();
}

class NativeWritingPracticeEngineFactory
    implements WritingPracticeEngineFactory {
  const NativeWritingPracticeEngineFactory(this._dataRepository);

  final WritingStrokeDataRepository _dataRepository;

  @override
  WritingPracticeEngine create(TickerProvider tickerProvider) {
    return NativeWritingPracticeEngine(_dataRepository, tickerProvider);
  }
}

class NativeWritingPracticeEngine extends ChangeNotifier
    implements WritingPracticeEngine {
  NativeWritingPracticeEngine(this._dataRepository, this._tickerProvider);

  final WritingStrokeDataRepository _dataRepository;
  final TickerProvider _tickerProvider;

  StrokeOrderAnimationController? _controller;
  WritingEngineSnapshot _snapshot = const WritingEngineSnapshot.empty();
  int _loadGeneration = 0;
  bool _disposed = false;

  @override
  Listenable get listenable => this;

  @override
  WritingEngineSnapshot get snapshot => _snapshot;

  @override
  Future<void> loadCharacter({
    required String character,
    required WritingScript script,
  }) async {
    final generation = ++_loadGeneration;
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.loading,
        character: character,
      ),
    );
    try {
      final raw = await _dataRepository.load(
        character: character,
        script: script,
      );
      if (_disposed || generation != _loadGeneration) return;
      final strokeOrder = StrokeOrder(raw);
      _controller?.removeListener(_handleNativeUpdate);
      _controller?.dispose();
      final controller = StrokeOrderAnimationController(
        strokeOrder,
        _tickerProvider,
        strokeAnimationSpeed: 2.2,
        hintAnimationSpeed: 3,
        showStroke: false,
        showOutline: true,
        showBackground: true,
        showMedian: false,
        showUserStroke: true,
        strokeColor: AppColors.textPrimary,
        outlineColor: AppColors.borderStrong,
        backgroundColor: AppColors.brandTint,
        brushColor: AppColors.brandPrimary,
        hintColor: AppColors.success,
        brushWidth: 18,
        outlineWidth: 2,
        hintAfterStrokes: 1,
        onQuizCompleteCallback: _handleQuizComplete,
      )..addListener(_handleNativeUpdate);
      _controller = controller;
      _replaceSnapshot(
        WritingEngineSnapshot(
          phase: WritingEnginePhase.ready,
          character: character,
          totalStrokeCount: strokeOrder.nStrokes,
        ),
      );
    } catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _replaceSnapshot(
        WritingEngineSnapshot(
          phase: WritingEnginePhase.failed,
          character: character,
          error: error,
        ),
      );
    }
  }

  @override
  void showStrokeAnimation() {
    final controller = _controller;
    if (controller == null || _disposed) return;
    controller.stopQuiz();
    controller.reset();
    controller.setShowStroke(true);
    controller.setShowOutline(false);
    controller.setShowBackground(false);
    controller.startAnimation();
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.animating,
        character: _snapshot.character,
        totalStrokeCount: controller.strokeOrder.nStrokes,
      ),
    );
  }

  @override
  void startQuiz({required bool guided}) {
    final controller = _controller;
    if (controller == null || _disposed) return;
    controller.stopAnimation();
    controller.reset();
    controller.setShowStroke(false);
    controller.setShowOutline(guided);
    controller.setShowBackground(guided);
    controller.setShowUserStroke(true);
    controller.startQuiz();
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.quizzing,
        character: _snapshot.character,
        totalStrokeCount: controller.strokeOrder.nStrokes,
      ),
    );
  }

  @override
  void reset() {
    final controller = _controller;
    if (controller == null || _disposed) return;
    controller.stopQuiz();
    controller.reset();
    controller.setShowStroke(false);
    controller.setShowOutline(true);
    controller.setShowBackground(true);
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.ready,
        character: _snapshot.character,
        totalStrokeCount: controller.strokeOrder.nStrokes,
      ),
    );
  }

  @override
  Widget buildCanvas({required Size size, Key? key}) {
    final controller = _controller;
    if (controller == null || !_snapshot.hasCanvas) {
      return SizedBox.fromSize(size: size);
    }
    return StrokeOrderAnimator(controller, size: size, key: key);
  }

  void _handleQuizComplete(QuizSummary summary) {
    if (_disposed) return;
    final result = writingPracticeResultFromQuiz(summary);
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.completed,
        character: _snapshot.character,
        totalStrokeCount: result.totalStrokeCount,
        result: result,
      ),
    );
  }

  void _handleNativeUpdate() {
    final controller = _controller;
    if (_disposed ||
        controller == null ||
        _snapshot.phase != WritingEnginePhase.animating) {
      return;
    }
    if (!controller.isAnimating &&
        controller.currentStroke >= controller.strokeOrder.nStrokes) {
      _replaceSnapshot(
        WritingEngineSnapshot(
          phase: WritingEnginePhase.ready,
          character: _snapshot.character,
          totalStrokeCount: controller.strokeOrder.nStrokes,
        ),
      );
    }
  }

  void _replaceSnapshot(WritingEngineSnapshot value) {
    if (_disposed) return;
    _snapshot = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration++;
    _controller?.removeListener(_handleNativeUpdate);
    _controller?.dispose();
    _controller = null;
    _snapshot = const WritingEngineSnapshot(phase: WritingEnginePhase.disposed);
    super.dispose();
  }
}

@visibleForTesting
WritingPracticeResult writingPracticeResultFromQuiz(QuizSummary summary) {
  final total = summary.nStrokes;
  final mistakes = summary.nTotalMistakes;
  return WritingPracticeResult(
    totalMistakes: mistakes,
    correctStrokeCount: (total - mistakes).clamp(0, total).toInt(),
    totalStrokeCount: total,
  );
}
