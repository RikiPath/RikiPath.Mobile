import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_writing_practice_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice_repository.dart';

final writingPracticeRepositoryProvider = Provider<WritingPracticeRepository>((
  ref,
) {
  return ApiWritingPracticeRepository(ref.watch(apiClientProvider));
});

final writingPracticeControllerProvider =
    AsyncNotifierProvider.family<
      WritingPracticeController,
      WritingPracticeState,
      WritingQueueRequest
    >(WritingPracticeController.new, retry: (_, _) => null);

class WritingPracticeController extends AsyncNotifier<WritingPracticeState> {
  WritingPracticeController(this.request);

  final WritingQueueRequest request;

  WritingPracticeRepository get _repository =>
      ref.read(writingPracticeRepositoryProvider);

  @override
  Future<WritingPracticeState> build() async {
    final items = await _repository.loadQueue(request);
    return WritingPracticeState(items: items);
  }

  Future<void> retry() async {
    state = const AsyncLoading<WritingPracticeState>();
    state = await AsyncValue.guard(build);
  }

  void selectCharacter(int characterId) {
    final current = state.value;
    if (current == null ||
        !current.items.any((item) => item.id == characterId)) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        selectedCharacterId: characterId,
        clearLocalResult: true,
        submissionStatus: WritingSubmissionStatus.idle,
        clearReceipt: true,
        clearSubmissionError: true,
      ),
    );
  }

  void setPracticeMode(WritingPracticeMode mode) {
    final current = state.value;
    if (current == null || current.practiceMode == mode) return;
    state = AsyncData(
      current.copyWith(
        practiceMode: mode,
        clearLocalResult: true,
        submissionStatus: WritingSubmissionStatus.idle,
        clearReceipt: true,
        clearSubmissionError: true,
      ),
    );
  }

  void resetPractice() {
    final current = state.value;
    if (current == null ||
        current.submissionStatus == WritingSubmissionStatus.submitting) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        clearLocalResult: true,
        submissionStatus: WritingSubmissionStatus.idle,
        clearReceipt: true,
        clearSubmissionError: true,
      ),
    );
  }

  int? selectNextCharacter() {
    final current = state.value;
    final selected = current?.selectedCharacter;
    if (current == null || selected == null || current.items.isEmpty) {
      return null;
    }
    final index = current.items.indexWhere((item) => item.id == selected.id);
    if (index < 0 || index + 1 >= current.items.length) return null;
    final nextId = current.items[index + 1].id;
    selectCharacter(nextId);
    return nextId;
  }

  Future<WritingSubmissionReceipt?> completePractice(
    WritingPracticeResult result,
  ) async {
    final current = state.value;
    final character = current?.selectedCharacter;
    if (current == null || character == null) return null;
    if (current.submissionStatus == WritingSubmissionStatus.submitting ||
        current.submissionStatus == WritingSubmissionStatus.succeeded ||
        current.localResult != null) {
      return current.receipt;
    }
    state = AsyncData(
      current.copyWith(
        localResult: result,
        submissionStatus: WritingSubmissionStatus.submitting,
        clearReceipt: true,
        clearSubmissionError: true,
      ),
    );
    return _submit(character: character, result: result);
  }

  Future<WritingSubmissionReceipt?> retrySubmission() async {
    final current = state.value;
    final character = current?.selectedCharacter;
    final result = current?.localResult;
    if (current == null ||
        character == null ||
        result == null ||
        current.submissionStatus != WritingSubmissionStatus.failed) {
      return null;
    }
    state = AsyncData(
      current.copyWith(
        submissionStatus: WritingSubmissionStatus.submitting,
        clearSubmissionError: true,
      ),
    );
    return _submit(character: character, result: result);
  }

  Future<WritingSubmissionReceipt?> _submit({
    required WritingCharacter character,
    required WritingPracticeResult result,
  }) async {
    try {
      final receipt = character.script == WritingScript.kanji
          ? await _repository.submitKanji(
              character: character,
              result: result,
              mode: state.value?.practiceMode ?? WritingPracticeMode.guided,
            )
          : await _repository.submitKana(character: character, result: result);
      final latest = state.value;
      if (latest == null || latest.selectedCharacterId != character.id) {
        return receipt;
      }
      state = AsyncData(
        latest.copyWith(
          submissionStatus: WritingSubmissionStatus.succeeded,
          receipt: receipt,
          clearSubmissionError: true,
        ),
      );
      return receipt;
    } catch (error) {
      final latest = state.value;
      if (latest != null && latest.selectedCharacterId == character.id) {
        state = AsyncData(
          latest.copyWith(
            submissionStatus: WritingSubmissionStatus.failed,
            submissionError: error,
            clearReceipt: true,
          ),
        );
      }
      return null;
    }
  }
}
