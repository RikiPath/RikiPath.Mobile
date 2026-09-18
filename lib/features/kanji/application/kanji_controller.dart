import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/kanji/data/api_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/fallback_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/fixture_kanji_repository.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_audio_player.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji_repository.dart';

final kanjiRepositoryProvider = Provider<KanjiRepository>((ref) {
  return FallbackKanjiRepository(
    remote: ApiKanjiRepository(ref.watch(apiClientProvider)),
    fixture: const FixtureKanjiRepository(),
  );
});

final kanjiNotebookRepositoryProvider = Provider<KanjiNotebookRepository>((
  ref,
) {
  return ApiKanjiNotebookRepository(ref.watch(apiClientProvider));
});

final kanjiAudioPlayerProvider = Provider.autoDispose<KanjiAudioPlayer>((ref) {
  final player = JustAudioKanjiPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final kanjiLibraryControllerProvider =
    AsyncNotifierProvider<KanjiLibraryController, KanjiLibraryState>(
      KanjiLibraryController.new,
    );

class KanjiLibraryController extends AsyncNotifier<KanjiLibraryState> {
  static const KanjiQuery initialQuery = KanjiQuery();

  KanjiRepository get _repository => ref.read(kanjiRepositoryProvider);

  @override
  Future<KanjiLibraryState> build() => _load(initialQuery);

  Future<void> search(String keyword) {
    final current = state.value;
    return _replace(
      KanjiQuery(
        keyword: keyword.trim(),
        level: current?.query.level,
        pageSize: current?.query.pageSize ?? initialQuery.pageSize,
      ),
    );
  }

  Future<void> filterByLevel(JlptLevel? level) {
    final current = state.value;
    return _replace(
      KanjiQuery(
        keyword: current?.query.keyword ?? '',
        level: level,
        pageSize: current?.query.pageSize ?? initialQuery.pageSize,
      ),
    );
  }

  Future<void> clear() => _replace(initialQuery);

  Future<void> retry() => _replace(state.value?.query ?? initialQuery);

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.page.hasNextPage) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final nextQuery = KanjiQuery(
        keyword: current.query.keyword,
        level: current.query.level,
        page: current.page.page + 1,
        pageSize: current.query.pageSize,
        minStrokeCount: current.query.minStrokeCount,
        maxStrokeCount: current.query.maxStrokeCount,
      );
      final nextPage = await _repository.search(nextQuery);
      state = AsyncData(
        KanjiLibraryState(
          query: nextQuery,
          page: KanjiPage(
            items: <KanjiEntry>[...current.page.items, ...nextPage.items],
            page: nextPage.page,
            pageSize: nextPage.pageSize,
            totalCount: nextPage.totalCount,
            totalPages: nextPage.totalPages,
            source: nextPage.source,
          ),
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          pageError: 'Không thể tải thêm Kanji. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> _replace(KanjiQuery query) async {
    state = const AsyncLoading<KanjiLibraryState>();
    state = await AsyncValue.guard(() => _load(query));
  }

  Future<KanjiLibraryState> _load(KanjiQuery query) async {
    return KanjiLibraryState(
      query: query,
      page: await _repository.search(query),
    );
  }
}

class KanjiLibraryState {
  const KanjiLibraryState({
    required this.query,
    required this.page,
    this.isLoadingMore = false,
    this.pageError,
  });

  final KanjiQuery query;
  final KanjiPage page;
  final bool isLoadingMore;
  final String? pageError;

  KanjiLibraryState copyWith({
    bool? isLoadingMore,
    String? pageError,
    bool clearError = false,
  }) {
    return KanjiLibraryState(
      query: query,
      page: page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pageError: clearError ? null : pageError ?? this.pageError,
    );
  }
}

final kanjiDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<KanjiDetailController, KanjiDetailState, String>(
      KanjiDetailController.new,
    );

class KanjiDetailController extends AsyncNotifier<KanjiDetailState> {
  KanjiDetailController(this.routeKey);

  final String routeKey;

  @override
  Future<KanjiDetailState> build() async {
    final entry = await ref.watch(kanjiRepositoryProvider).loadDetail(routeKey);
    return KanjiDetailState(entry: entry);
  }

  Future<void> retry() async {
    state = const AsyncLoading<KanjiDetailState>();
    state = await AsyncValue.guard(build);
  }

  void openStrokeOrder() {
    final current = state.requireValue;
    if (!current.hasStrokeOrder) return;
    state = AsyncData(current.copyWith(showStrokeOrder: true));
  }

  void closeStrokeOrder() {
    state = AsyncData(state.requireValue.copyWith(showStrokeOrder: false));
  }

  void selectStroke(int number) {
    final current = state.requireValue;
    final maximum = current.entry.strokeCount < 1
        ? 1
        : current.entry.strokeCount;
    final safeNumber = number.clamp(1, maximum);
    state = AsyncData(current.copyWith(currentStroke: safeNumber));
  }

  void nextStroke() => selectStroke(state.requireValue.currentStroke + 1);

  void previousStroke() => selectStroke(state.requireValue.currentStroke - 1);

  void restartStrokeOrder() => selectStroke(1);

  Future<List<KanjiNotebookList>> loadNotebookLists() async {
    final current = state.requireValue;
    if (current.entry.source == KanjiDataSource.fixture) {
      const lists = <KanjiNotebookList>[
        KanjiNotebookList(
          id: -1,
          name: 'Mặc định (dữ liệu mẫu)',
          entryCount: 48,
        ),
      ];
      state = AsyncData(current.copyWith(notebookLists: lists));
      return lists;
    }

    state = AsyncData(
      current.copyWith(isLoadingNotebook: true, clearNotebookError: true),
    );
    try {
      final lists = await ref.read(kanjiNotebookRepositoryProvider).loadLists();
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
          notebookError: 'Không thể tải danh sách Sổ từ.',
        ),
      );
      return const <KanjiNotebookList>[];
    }
  }

  Future<bool> saveToNotebook(KanjiNotebookList list) async {
    final current = state.requireValue;
    if (current.isSaving || current.isSaved) return current.isSaved;

    if (current.entry.source == KanjiDataSource.fixture) {
      state = AsyncData(
        current.copyWith(
          entry: current.entry.copyWith(isSaved: true),
          bookmark: KanjiBookmark(
            noteEntryId: null,
            listId: list.id,
            listName: list.name,
          ),
        ),
      );
      return true;
    }

    final remoteId = current.entry.remoteId;
    if (remoteId == null) return false;
    state = AsyncData(
      current.copyWith(isSaving: true, clearNotebookError: true),
    );
    try {
      final bookmark = await ref
          .read(kanjiNotebookRepositoryProvider)
          .bookmarkKanji(kanjiEntryId: remoteId, list: list);
      state = AsyncData(
        state.requireValue.copyWith(isSaving: false, bookmark: bookmark),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isSaving: false,
          notebookError: 'Không thể lưu Kanji vào Sổ từ.',
        ),
      );
      return false;
    }
  }

  Future<bool> playAudio() async {
    final current = state.requireValue;
    final source = current.entry.audioUrl;
    if (source == null || current.isPlayingAudio) return false;
    state = AsyncData(current.copyWith(isPlayingAudio: true));
    try {
      await ref.read(kanjiAudioPlayerProvider).play(source);
      state = AsyncData(state.requireValue.copyWith(isPlayingAudio: false));
      return true;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isPlayingAudio: false,
          audioError: 'Không thể phát âm thanh Kanji.',
        ),
      );
      return false;
    }
  }
}

const Object _unsetKanjiBookmark = Object();

class KanjiDetailState {
  const KanjiDetailState({
    required this.entry,
    this.notebookLists = const <KanjiNotebookList>[],
    this.bookmark,
    this.showStrokeOrder = false,
    this.currentStroke = 1,
    this.isLoadingNotebook = false,
    this.isSaving = false,
    this.isPlayingAudio = false,
    this.notebookError,
    this.audioError,
  });

  final KanjiEntry entry;
  final List<KanjiNotebookList> notebookLists;
  final KanjiBookmark? bookmark;
  final bool showStrokeOrder;
  final int currentStroke;
  final bool isLoadingNotebook;
  final bool isSaving;
  final bool isPlayingAudio;
  final String? notebookError;
  final String? audioError;

  bool get isSaved => entry.isSaved == true || bookmark != null;
  bool get hasStrokeOrder =>
      entry.strokeOrderUrl != null ||
      (entry.enrichment?.strokeSteps.isNotEmpty ?? false);

  KanjiDetailState copyWith({
    KanjiEntry? entry,
    List<KanjiNotebookList>? notebookLists,
    Object? bookmark = _unsetKanjiBookmark,
    bool? showStrokeOrder,
    int? currentStroke,
    bool? isLoadingNotebook,
    bool? isSaving,
    bool? isPlayingAudio,
    String? notebookError,
    String? audioError,
    bool clearNotebookError = false,
  }) {
    return KanjiDetailState(
      entry: entry ?? this.entry,
      notebookLists: notebookLists ?? this.notebookLists,
      bookmark: identical(bookmark, _unsetKanjiBookmark)
          ? this.bookmark
          : bookmark as KanjiBookmark?,
      showStrokeOrder: showStrokeOrder ?? this.showStrokeOrder,
      currentStroke: currentStroke ?? this.currentStroke,
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
