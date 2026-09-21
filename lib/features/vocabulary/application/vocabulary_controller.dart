import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/vocabulary/data/api_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fallback_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/fixture_vocabulary_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_audio_player.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary_repository.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return FallbackVocabularyRepository(
    remote: ApiVocabularyRepository(ref.watch(apiClientProvider)),
    fixture: const FixtureVocabularyRepository(),
  );
});

final vocabularyAudioPlayerProvider =
    Provider.autoDispose<VocabularyAudioPlayer>((ref) {
      final player = JustAudioVocabularyPlayer();
      ref.onDispose(() {
        player.dispose();
      });
      return player;
    });

final vocabularyLibraryControllerProvider =
    AsyncNotifierProvider<VocabularyLibraryController, VocabularyLibraryState>(
      VocabularyLibraryController.new,
    );

class VocabularyLibraryController
    extends AsyncNotifier<VocabularyLibraryState> {
  static const VocabularyQuery initialQuery = VocabularyQuery();

  VocabularyRepository get _repository =>
      ref.read(vocabularyRepositoryProvider);

  @override
  Future<VocabularyLibraryState> build() async {
    return _load(initialQuery);
  }

  Future<void> search(String keyword) {
    final current = state.value;
    return _replace(
      VocabularyQuery(
        keyword: keyword.trim(),
        level: current?.query.level,
        pageSize: current?.query.pageSize ?? initialQuery.pageSize,
      ),
    );
  }

  Future<void> filterByLevel(JlptLevel? level) {
    final current = state.value;
    return _replace(
      VocabularyQuery(
        keyword: current?.query.keyword ?? '',
        level: level,
        pageSize: current?.query.pageSize ?? initialQuery.pageSize,
      ),
    );
  }

  Future<void> retry() {
    return _replace(state.value?.query ?? initialQuery);
  }

  Future<void> clear() => _replace(initialQuery);

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.page.hasNextPage) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearPageError: true),
    );
    try {
      final nextQuery = VocabularyQuery(
        keyword: current.query.keyword,
        level: current.query.level,
        page: current.page.page + 1,
        pageSize: current.query.pageSize,
      );
      final nextPage = await _repository.search(nextQuery);
      final combined = VocabularyPage(
        items: <VocabularyEntry>[...current.page.items, ...nextPage.items],
        page: nextPage.page,
        pageSize: nextPage.pageSize,
        totalCount: nextPage.totalCount,
        totalPages: nextPage.totalPages,
        source: nextPage.source,
      );
      state = AsyncData(
        VocabularyLibraryState(query: nextQuery, page: combined),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          pageError: ref
              .read(appLocalizationsProvider)
              .vocabularyLoadMoreFailed,
        ),
      );
    }
  }

  Future<void> _replace(VocabularyQuery query) async {
    state = const AsyncLoading<VocabularyLibraryState>();
    state = await AsyncValue.guard(() => _load(query));
  }

  Future<VocabularyLibraryState> _load(VocabularyQuery query) async {
    final page = await _repository.search(query);
    return VocabularyLibraryState(query: query, page: page);
  }
}

class VocabularyLibraryState {
  const VocabularyLibraryState({
    required this.query,
    required this.page,
    this.isLoadingMore = false,
    this.pageError,
  });

  final VocabularyQuery query;
  final VocabularyPage page;
  final bool isLoadingMore;
  final String? pageError;

  VocabularyLibraryState copyWith({
    bool? isLoadingMore,
    String? pageError,
    bool clearPageError = false,
  }) {
    return VocabularyLibraryState(
      query: query,
      page: page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pageError: clearPageError ? null : pageError ?? this.pageError,
    );
  }
}

final vocabularyDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<VocabularyDetailController, VocabularyDetailState, String>(
      VocabularyDetailController.new,
    );

class VocabularyDetailController extends AsyncNotifier<VocabularyDetailState> {
  VocabularyDetailController(this.routeKey);

  final String routeKey;

  @override
  Future<VocabularyDetailState> build() async {
    final entry = await ref
        .watch(vocabularyRepositoryProvider)
        .loadDetail(routeKey);
    return VocabularyDetailState(entry: entry);
  }

  Future<void> retry() async {
    state = const AsyncLoading<VocabularyDetailState>();
    state = await AsyncValue.guard(build);
  }

  Future<List<NotebookCollection>> loadNotebookLists() async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(isLoadingNotebook: true, clearNotebookError: true),
    );
    try {
      final lists = await ref
          .read(notebookRepositoryProvider)
          .loadCollections();
      state = AsyncData(
        state.requireValue.copyWith(
          notebookLists: lists,
          isLoadingNotebook: false,
        ),
      );
      return lists;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingNotebook: false,
          notebookError: ref
              .read(appLocalizationsProvider)
              .notebookListsLoadFailed,
        ),
      );
      return const <NotebookCollection>[];
    }
  }

  Future<bool> saveToNotebook(NotebookCollection list) async {
    final current = state.requireValue;
    if (current.isSaving) return false;

    final notebook = ref.read(notebookRepositoryProvider);
    if (await notebook.isVocabularySaved(current.entry.routeKey)) return true;

    state = AsyncData(
      current.copyWith(isSaving: true, clearNotebookError: true),
    );
    try {
      await notebook.bookmarkVocabulary(
        vocabulary: NotebookVocabularyDraft(
          routeKey: current.entry.routeKey,
          remoteId: current.entry.remoteId,
          term: current.entry.word,
          reading: current.entry.reading,
          meaning: current.entry.meaning,
          jlptLevel: current.entry.level.label,
          exampleSentence: current.entry.exampleSentence,
        ),
        collection: list,
      );
      state = AsyncData(state.requireValue.copyWith(isSaving: false));
      ref.invalidate(notebookControllerProvider);
      return true;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isSaving: false,
          notebookError: ref
              .read(appLocalizationsProvider)
              .vocabularySaveFailed,
        ),
      );
      return false;
    }
  }

  Future<bool> playAudio() async {
    final current = state.requireValue;
    final source = current.entry.audioUrl;
    if (source == null || current.isPlayingAudio) {
      return false;
    }

    state = AsyncData(current.copyWith(isPlayingAudio: true));
    try {
      await ref.read(vocabularyAudioPlayerProvider).play(source);
      state = AsyncData(state.requireValue.copyWith(isPlayingAudio: false));
      return true;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isPlayingAudio: false,
          audioError: ref.read(appLocalizationsProvider).vocabularyAudioFailed,
        ),
      );
      return false;
    }
  }
}

class VocabularyDetailState {
  const VocabularyDetailState({
    required this.entry,
    this.notebookLists = const <NotebookCollection>[],
    this.isLoadingNotebook = false,
    this.isSaving = false,
    this.isPlayingAudio = false,
    this.notebookError,
    this.audioError,
  });

  final VocabularyEntry entry;
  final List<NotebookCollection> notebookLists;
  final bool isLoadingNotebook;
  final bool isSaving;
  final bool isPlayingAudio;
  final String? notebookError;
  final String? audioError;

  VocabularyDetailState copyWith({
    VocabularyEntry? entry,
    List<NotebookCollection>? notebookLists,
    bool? isLoadingNotebook,
    bool? isSaving,
    bool? isPlayingAudio,
    String? notebookError,
    String? audioError,
    bool clearNotebookError = false,
  }) {
    return VocabularyDetailState(
      entry: entry ?? this.entry,
      notebookLists: notebookLists ?? this.notebookLists,
      isLoadingNotebook: isLoadingNotebook ?? this.isLoadingNotebook,
      isSaving: isSaving ?? this.isSaving,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
      notebookError: clearNotebookError
          ? null
          : notebookError ?? this.notebookError,
      audioError: audioError ?? this.audioError,
    );
  }
}
