import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/notebook/data/api_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return ApiNotebookRepository(ref.watch(apiClientProvider));
});

final notebookControllerProvider =
    AsyncNotifierProvider<NotebookController, NotebookLibraryState>(
      NotebookController.new,
    );

class NotebookController extends AsyncNotifier<NotebookLibraryState> {
  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);

  @override
  Future<NotebookLibraryState> build() async {
    final collections = await _repository.loadCollections();
    if (collections.isEmpty) {
      return const NotebookLibraryState(
        collections: <NotebookCollection>[],
        entries: <NotebookEntry>[],
      );
    }

    final selected = collections.first;
    final entries = await _repository.loadEntries(selected);
    return NotebookLibraryState(
      collections: collections,
      selectedCollectionKey: selected.routeKey,
      entries: entries,
    );
  }

  void search(String query) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query.trim()));
  }

  void clearSearch() => search('');

  Future<void> retry() async {
    state = const AsyncLoading<NotebookLibraryState>();
    state = await AsyncValue.guard(build);
  }

  Future<void> selectCollection(NotebookCollection collection) async {
    final current = state.value;
    if (current == null ||
        current.isLoadingEntries ||
        current.selectedCollectionKey == collection.routeKey) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        selectedCollectionKey: collection.routeKey,
        entries: const <NotebookEntry>[],
        query: '',
        isLoadingEntries: true,
        clearEntriesError: true,
        clearMutationError: true,
      ),
    );

    try {
      final entries = await _repository.loadEntries(collection);
      state = AsyncData(
        state.requireValue.copyWith(entries: entries, isLoadingEntries: false),
      );
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingEntries: false,
          entriesError: _message(
            error,
            'Không thể tải nội dung danh sách. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  Future<bool> createCollection({
    required String name,
    String? description,
  }) async {
    final current = state.value;
    final normalizedName = name.trim();
    if (current == null || current.isCreatingCollection) return false;
    if (normalizedName.isEmpty) {
      state = AsyncData(
        current.copyWith(mutationError: 'Tên danh sách không được để trống.'),
      );
      return false;
    }

    state = AsyncData(
      current.copyWith(isCreatingCollection: true, clearMutationError: true),
    );
    try {
      final created = await _repository.createCollection(
        name: normalizedName,
        description: description,
      );
      final collections = <NotebookCollection>[
        ...state.requireValue.collections,
        created,
      ]..sort((left, right) => left.name.compareTo(right.name));
      state = AsyncData(
        state.requireValue.copyWith(
          collections: collections,
          selectedCollectionKey: created.routeKey,
          entries: const <NotebookEntry>[],
          query: '',
          isCreatingCollection: false,
          clearEntriesError: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isCreatingCollection: false,
          mutationError: _message(
            error,
            'Không thể tạo danh sách. Vui lòng thử lại.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> addManualEntry({
    required String word,
    String? reading,
    required String meaning,
    String? note,
  }) async {
    final current = state.value;
    final collection = current?.selectedCollection;
    if (current == null || collection == null || current.isAddingEntry) {
      return false;
    }

    if (word.trim().isEmpty || meaning.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(
          mutationError: 'Từ tiếng Nhật và nghĩa tiếng Việt là bắt buộc.',
        ),
      );
      return false;
    }

    state = AsyncData(
      current.copyWith(isAddingEntry: true, clearMutationError: true),
    );
    try {
      final entry = await _repository.addManualEntry(
        collection: collection,
        word: word,
        reading: reading,
        meaning: meaning,
        note: note,
      );
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          entries: <NotebookEntry>[entry, ...latest.entries],
          collections: _adjustEntryCount(
            latest.collections,
            collection.routeKey,
            1,
          ),
          isAddingEntry: false,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isAddingEntry: false,
          mutationError: _message(
            error,
            'Không thể thêm từ vào Sổ từ. Vui lòng thử lại.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> removeEntry(NotebookEntry entry) async {
    final current = state.value;
    if (current == null || current.removingEntryKeys.contains(entry.routeKey)) {
      return false;
    }

    state = AsyncData(
      current.copyWith(
        removingEntryKeys: <String>{
          ...current.removingEntryKeys,
          entry.routeKey,
        },
        clearMutationError: true,
      ),
    );
    try {
      await _repository.removeEntry(entry);
      final latest = state.requireValue;
      final selectedKey = latest.selectedCollectionKey;
      state = AsyncData(
        latest.copyWith(
          entries: latest.entries
              .where((item) => item.routeKey != entry.routeKey)
              .toList(growable: false),
          collections: selectedKey == null
              ? latest.collections
              : _adjustEntryCount(latest.collections, selectedKey, -1),
          removingEntryKeys: <String>{...latest.removingEntryKeys}
            ..remove(entry.routeKey),
        ),
      );
      return true;
    } catch (error) {
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          removingEntryKeys: <String>{...latest.removingEntryKeys}
            ..remove(entry.routeKey),
          mutationError: _message(
            error,
            'Không thể xóa mục khỏi Sổ từ. Vui lòng thử lại.',
          ),
        ),
      );
      return false;
    }
  }

  void clearMutationError() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearMutationError: true));
  }

  List<NotebookCollection> _adjustEntryCount(
    List<NotebookCollection> collections,
    String collectionKey,
    int delta,
  ) {
    return collections
        .map(
          (collection) => collection.routeKey == collectionKey
              ? collection.copyWith(
                  entryCount: (collection.entryCount + delta).clamp(0, 1 << 31),
                )
              : collection,
        )
        .toList(growable: false);
  }

  String _message(Object error, String fallback) {
    if (error is ApiError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }
}

class NotebookLibraryState {
  const NotebookLibraryState({
    required this.collections,
    required this.entries,
    this.selectedCollectionKey,
    this.query = '',
    this.isLoadingEntries = false,
    this.isCreatingCollection = false,
    this.isAddingEntry = false,
    this.removingEntryKeys = const <String>{},
    this.entriesError,
    this.mutationError,
  });

  final List<NotebookCollection> collections;
  final String? selectedCollectionKey;
  final List<NotebookEntry> entries;
  final String query;
  final bool isLoadingEntries;
  final bool isCreatingCollection;
  final bool isAddingEntry;
  final Set<String> removingEntryKeys;
  final String? entriesError;
  final String? mutationError;

  NotebookCollection? get selectedCollection {
    for (final collection in collections) {
      if (collection.routeKey == selectedCollectionKey) return collection;
    }
    return null;
  }

  List<NotebookEntry> get visibleEntries {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return entries;
    return entries
        .where((entry) {
          return <String?>[entry.term, entry.reading, entry.meaning, entry.note]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(normalized));
        })
        .toList(growable: false);
  }

  bool get usesFixtureData =>
      collections.any((item) => item.source == NotebookDataSource.fixture) ||
      entries.any((item) => item.source == NotebookDataSource.fixture);

  NotebookLibraryState copyWith({
    List<NotebookCollection>? collections,
    String? selectedCollectionKey,
    List<NotebookEntry>? entries,
    String? query,
    bool? isLoadingEntries,
    bool? isCreatingCollection,
    bool? isAddingEntry,
    Set<String>? removingEntryKeys,
    String? entriesError,
    String? mutationError,
    bool clearEntriesError = false,
    bool clearMutationError = false,
  }) {
    return NotebookLibraryState(
      collections: collections ?? this.collections,
      selectedCollectionKey:
          selectedCollectionKey ?? this.selectedCollectionKey,
      entries: entries ?? this.entries,
      query: query ?? this.query,
      isLoadingEntries: isLoadingEntries ?? this.isLoadingEntries,
      isCreatingCollection: isCreatingCollection ?? this.isCreatingCollection,
      isAddingEntry: isAddingEntry ?? this.isAddingEntry,
      removingEntryKeys: removingEntryKeys ?? this.removingEntryKeys,
      entriesError: clearEntriesError
          ? null
          : entriesError ?? this.entriesError,
      mutationError: clearMutationError
          ? null
          : mutationError ?? this.mutationError,
    );
  }
}
