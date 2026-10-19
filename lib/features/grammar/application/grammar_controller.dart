import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/utils/stable_merge.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/grammar/data/api_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return ApiGrammarRepository(ref.watch(apiClientProvider));
});

final grammarBookmarkRepositoryProvider = Provider<GrammarBookmarkRepository>((
  ref,
) {
  return ApiGrammarBookmarkRepository(ref.watch(apiClientProvider));
});

final grammarLibraryControllerProvider =
    AsyncNotifierProvider<GrammarLibraryController, GrammarLibraryState>(
      GrammarLibraryController.new,
      retry: (_, _) => null,
    );

class GrammarLibraryController extends AsyncNotifier<GrammarLibraryState> {
  static const GrammarQuery initialQuery = GrammarQuery();

  GrammarRepository get _repository => ref.read(grammarRepositoryProvider);

  @override
  Future<GrammarLibraryState> build() => _load(initialQuery);

  Future<void> search(String keyword) {
    final current = state.value;
    return _replace(
      GrammarQuery(
        keyword: keyword.trim(),
        level: current?.query.level,
        pageSize: current?.query.pageSize ?? initialQuery.pageSize,
      ),
    );
  }

  Future<void> filterByLevel(JlptLevel? level) {
    final current = state.value;
    return _replace(
      GrammarQuery(
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
      final nextQuery = GrammarQuery(
        keyword: current.query.keyword,
        level: current.query.level,
        page: current.page.page + 1,
        pageSize: current.query.pageSize,
      );
      final nextPage = await _repository.search(nextQuery);
      state = AsyncData(
        GrammarLibraryState(
          query: nextQuery,
          page: GrammarPage(
            items: mergeUniqueByKey(
              current.page.items,
              nextPage.items,
              (entry) => entry.routeKey,
            ),
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
          pageError: ref.read(appLocalizationsProvider).grammarLoadMoreFailed,
        ),
      );
    }
  }

  Future<void> _replace(GrammarQuery query) async {
    state = const AsyncLoading<GrammarLibraryState>();
    state = await AsyncValue.guard(() => _load(query));
  }

  Future<GrammarLibraryState> _load(GrammarQuery query) async {
    return GrammarLibraryState(
      query: query,
      page: await _repository.search(query),
    );
  }
}

class GrammarLibraryState {
  const GrammarLibraryState({
    required this.query,
    required this.page,
    this.isLoadingMore = false,
    this.pageError,
  });

  final GrammarQuery query;
  final GrammarPage page;
  final bool isLoadingMore;
  final String? pageError;

  GrammarLibraryState copyWith({
    bool? isLoadingMore,
    String? pageError,
    bool clearError = false,
  }) {
    return GrammarLibraryState(
      query: query,
      page: page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pageError: clearError ? null : pageError ?? this.pageError,
    );
  }
}

final grammarDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<GrammarDetailController, GrammarDetailState, String>(
      GrammarDetailController.new,
      retry: (_, _) => null,
    );

class GrammarDetailController extends AsyncNotifier<GrammarDetailState> {
  GrammarDetailController(this.routeKey);

  final String routeKey;

  @override
  Future<GrammarDetailState> build() async {
    final entry = await ref
        .watch(grammarRepositoryProvider)
        .loadDetail(routeKey);
    return GrammarDetailState(entry: entry);
  }

  Future<void> retry() async {
    state = const AsyncLoading<GrammarDetailState>();
    state = await AsyncValue.guard(build);
  }

  Future<bool> saveBookmark() async {
    final current = state.requireValue;
    if (current.isSaving || current.isSaved) return current.isSaved;
    final grammarId = current.entry.remoteId;
    if (current.entry.source != GrammarDataSource.remote ||
        grammarId == null ||
        grammarId <= 0) {
      return false;
    }

    state = AsyncData(
      current.copyWith(isSaving: true, clearBookmarkError: true),
    );
    try {
      final bookmark = await ref
          .read(grammarBookmarkRepositoryProvider)
          .bookmarkGrammar(grammarId);
      state = AsyncData(
        state.requireValue.copyWith(isSaving: false, bookmark: bookmark),
      );
      return true;
    } on ConflictError {
      state = AsyncData(
        state.requireValue.copyWith(isSaving: false, alreadySaved: true),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(
          isSaving: false,
          bookmarkError: ref.read(appLocalizationsProvider).grammarSaveFailed,
        ),
      );
      return false;
    }
  }
}

class GrammarDetailState {
  const GrammarDetailState({
    required this.entry,
    this.bookmark,
    this.isSaving = false,
    this.alreadySaved = false,
    this.bookmarkError,
  });

  final GrammarEntry entry;
  final GrammarBookmark? bookmark;
  final bool isSaving;
  final bool alreadySaved;
  final String? bookmarkError;

  bool get isSaved => bookmark != null || alreadySaved;
  bool get canBookmark =>
      entry.source == GrammarDataSource.remote && (entry.remoteId ?? 0) > 0;

  GrammarDetailState copyWith({
    GrammarBookmark? bookmark,
    bool? isSaving,
    bool? alreadySaved,
    String? bookmarkError,
    bool clearBookmarkError = false,
  }) {
    return GrammarDetailState(
      entry: entry,
      bookmark: bookmark ?? this.bookmark,
      isSaving: isSaving ?? this.isSaving,
      alreadySaved: alreadySaved ?? this.alreadySaved,
      bookmarkError: clearBookmarkError
          ? null
          : bookmarkError ?? this.bookmarkError,
    );
  }
}
