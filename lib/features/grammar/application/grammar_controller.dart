import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/grammar/data/api_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/data/fallback_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/data/fixture_grammar_repository.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar_repository.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return FallbackGrammarRepository(
    remote: ApiGrammarRepository(ref.watch(apiClientProvider)),
    fixture: const FixtureGrammarRepository(),
  );
});

final grammarLibraryControllerProvider =
    AsyncNotifierProvider<GrammarLibraryController, GrammarLibraryState>(
      GrammarLibraryController.new,
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
            items: <GrammarEntry>[...current.page.items, ...nextPage.items],
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
          pageError: 'Không thể tải thêm ngữ pháp. Vui lòng thử lại.',
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
    .family<GrammarDetailController, GrammarEntry, String>(
      GrammarDetailController.new,
    );

class GrammarDetailController extends AsyncNotifier<GrammarEntry> {
  GrammarDetailController(this.routeKey);

  final String routeKey;

  @override
  Future<GrammarEntry> build() {
    return ref.watch(grammarRepositoryProvider).loadDetail(routeKey);
  }

  Future<void> retry() async {
    state = const AsyncLoading<GrammarEntry>();
    state = await AsyncValue.guard(build);
  }
}
