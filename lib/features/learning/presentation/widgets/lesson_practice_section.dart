import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_practice_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_practice.dart';

class LessonPracticeSection extends ConsumerStatefulWidget {
  const LessonPracticeSection({required this.lessonId, super.key});

  final int lessonId;

  @override
  ConsumerState<LessonPracticeSection> createState() =>
      _LessonPracticeSectionState();
}

class _LessonPracticeSectionState extends ConsumerState<LessonPracticeSection> {
  int? _startingId;
  String? _error;

  Future<void> _start(LessonPracticeExercise exercise) async {
    if (_startingId != null) return;
    setState(() {
      _startingId = exercise.id;
      _error = null;
    });
    try {
      final repository = ref.read(lessonPracticeRepositoryProvider);
      final attempt = await repository.start(exercise.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) =>
            _PracticeAttemptSheet(attempt: attempt, repository: repository),
      );
      ref.invalidate(lessonPracticeExercisesProvider(widget.lessonId));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không thể bắt đầu bài luyện tập. Vui lòng thử lại.',
        );
      });
    } finally {
      if (mounted) setState(() => _startingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonPracticeExercisesProvider(widget.lessonId));
    return RikiCard(
      key: ValueKey<String>('lesson_practice_${widget.lessonId}'),
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Luyện tập bài học', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.space2),
          if (_error case final error?)
            Text(error, style: TextStyle(color: AppColors.error)),
          state.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appErrorMessage(
                    error,
                    context.l10n,
                    fallback: 'Không thể tải bài luyện tập.',
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    lessonPracticeExercisesProvider(widget.lessonId),
                  ),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
            data: (exercises) => exercises.isEmpty
                ? const Text('Bài học này chưa có bài luyện tập.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final exercise in exercises) ...[
                        Text(exercise.title, style: AppTypography.bodySmall),
                        if (exercise.description case final description?)
                          Text(description, style: AppTypography.metadata),
                        Text(
                          exercise.bestScorePercent == null
                              ? '${exercise.questionCount} câu hỏi'
                              : 'Điểm cao nhất: ${exercise.bestScorePercent!.toStringAsFixed(0)}%',
                          style: AppTypography.metadata,
                        ),
                        OutlinedButton.icon(
                          key: ValueKey<String>(
                            'practice_start_${exercise.id}',
                          ),
                          onPressed:
                              exercise.questionCount > 0 && _startingId == null
                              ? () => _start(exercise)
                              : null,
                          icon: const Icon(Icons.quiz_outlined),
                          label: Text(
                            _startingId == exercise.id
                                ? 'Đang mở bài luyện tập...'
                                : 'Làm bài luyện tập',
                          ),
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

class _PracticeAttemptSheet extends StatefulWidget {
  const _PracticeAttemptSheet({
    required this.attempt,
    required this.repository,
  });

  final LessonPracticeAttempt attempt;
  final LessonPracticeRepository repository;

  @override
  State<_PracticeAttemptSheet> createState() => _PracticeAttemptSheetState();
}

class _PracticeAttemptSheetState extends State<_PracticeAttemptSheet> {
  late final Map<int, int> _answers = {...widget.attempt.savedOptionIds};
  late final Map<int, String> _textAnswers = {
    ...widget.attempt.savedTextAnswers,
  };
  bool _submitting = false;
  String? _error;
  LessonPracticeResult? _result;

  Future<void> _submit() async {
    if (_submitting ||
        _result != null ||
        (_answers.isEmpty && _textAnswers.isEmpty)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.repository.submit(
        attemptId: widget.attempt.attemptId,
        selectedOptionIds: Map<int, int>.unmodifiable(_answers),
        textAnswers: Map<int, String>.unmodifiable(_textAnswers),
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback:
              'Chưa xác nhận được kết quả. Hãy kiểm tra trước khi nộp lại.',
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: ListView(
          key: const ValueKey<String>('lesson_practice_attempt_sheet'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space2,
            AppSpacing.space4,
            AppSpacing.space6,
          ),
          children: [
            Text(widget.attempt.title, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.space2),
            if (widget.attempt.resumed)
              const Text('Đã mở lại lượt làm bài chưa nộp.'),
            if (result != null) ...[
              Text(
                'Kết quả: ${result.scorePercent.toStringAsFixed(0)}% '
                '(${result.correctCount}/${result.gradedQuestions} câu được chấm)',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                result.scorePercent >= 70
                    ? 'Bạn đã đạt mức 70%. Quay lại lộ trình để hoàn thành ngày học.'
                    : 'Cần đạt ít nhất 70% để hoàn thành ngày học AI.',
              ),
            ] else ...[
              for (
                var index = 0;
                index < widget.attempt.questions.length;
                index++
              ) ...[
                const Divider(),
                Text(
                  'Câu ${index + 1}. ${widget.attempt.questions[index].text}',
                  style: AppTypography.cardTitle,
                ),
                if (widget.attempt.questions[index].options.isEmpty)
                  TextFormField(
                    key: ValueKey<String>(
                      'practice_text_${widget.attempt.questions[index].id}',
                    ),
                    maxLength: 2000,
                    maxLines: 3,
                    initialValue:
                        _textAnswers[widget.attempt.questions[index].id],
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu trả lời của bạn',
                    ),
                    onChanged: (value) => setState(() {
                      final questionId = widget.attempt.questions[index].id;
                      if (value.trim().isEmpty) {
                        _textAnswers.remove(questionId);
                      } else {
                        _textAnswers[questionId] = value.trim();
                      }
                    }),
                  ),
                for (final option in widget.attempt.questions[index].options)
                  ListTile(
                    key: ValueKey<String>(
                      'practice_option_${widget.attempt.questions[index].id}_${option.id}',
                    ),
                    leading: Icon(
                      _answers[widget.attempt.questions[index].id] == option.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(option.text),
                    onTap: _submitting
                        ? null
                        : () => setState(() {
                            _answers[widget.attempt.questions[index].id] =
                                option.id;
                          }),
                  ),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(error, style: TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.space3),
              FilledButton(
                key: const ValueKey<String>('practice_submit_button'),
                onPressed:
                    (_answers.isEmpty && _textAnswers.isEmpty) || _submitting
                    ? null
                    : _submit,
                child: Text(_submitting ? 'Đang nộp bài...' : 'Nộp bài'),
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}
