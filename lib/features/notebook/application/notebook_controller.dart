import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/database/database_provider.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/notebook/data/api_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/data/notebook_local_store.dart';
import 'package:rikipath_mobile/features/notebook/data/persistent_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook_repository.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  final session = ref.watch(authSessionControllerProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return PersistentNotebookRepository(
    ApiNotebookRepository(ref.watch(apiClientProvider)),
    NotebookLocalStore(ref.watch(appDatabaseProvider)),
    () async => session.currentUserId ?? tokenStorage.readAuthenticatedUserId(),
  );
});

final savedVocabularyKeysProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) async* {
  final localState = ref.watch(demoNotebookControllerProvider).value;
  final localKeys = (localState?.entries ?? const <NotebookEntry>[])
      .where((entry) => entry.contentType == NotebookContentType.vocabulary)
      .map((entry) => entry.vocabularyRouteKey)
      .whereType<String>()
      .toSet();
  yield localKeys;
  try {
    await for (final liveKeys
        in ref.watch(notebookRepositoryProvider).watchSavedVocabularyKeys()) {
      yield <String>{...localKeys, ...liveKeys};
    }
  } catch (_) {
    // Fixture truth remains observable when the authenticated live cache is
    // unavailable. The owning screen already reports live failures.
  }
});

final notebookControllerProvider =
    AsyncNotifierProvider<NotebookController, NotebookLibraryState>(
      NotebookController.new,
      retry: (_, _) => null,
    );

class NotebookController extends AsyncNotifier<NotebookLibraryState> {
  static const String demoCollectionRouteKey = 'fixture-learning-saved';

  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);

  @override
  Future<NotebookLibraryState> build() async {
    final demoState = await ref.watch(demoNotebookControllerProvider.future);
    final localEntries = demoState.entries;
    var remoteCollections = const <NotebookCollection>[];
    String? remoteLoadError;
    try {
      remoteCollections = await _repository.loadCollections();
    } catch (_) {
      if (localEntries.isEmpty) rethrow;
      remoteLoadError = ref
          .read(appLocalizationsProvider)
          .notebookListsLoadFailed;
    }
    final collections = <NotebookCollection>[
      if (localEntries.isNotEmpty)
        NotebookCollection(
          routeKey: demoCollectionRouteKey,
          remoteId: null,
          name: ref.read(appLocalizationsProvider).savedFromLessons,
          entryCount: localEntries.length,
          createdAt: null,
          source: NotebookDataSource.fixture,
        ),
      ...remoteCollections,
    ];
    if (collections.isEmpty) {
      return const NotebookLibraryState(
        collections: <NotebookCollection>[],
        localEntries: <NotebookEntry>[],
        liveEntries: <NotebookEntry>[],
      );
    }

    final selected = remoteCollections.firstOrNull ?? collections.first;
    var liveEntries = const <NotebookEntry>[];
    String? entriesError;
    if (selected.source == NotebookDataSource.remote) {
      try {
        liveEntries = await _repository.loadEntries(selected);
      } catch (error) {
        entriesError = _message(
          error,
          ref.read(appLocalizationsProvider).notebookEntriesLoadFailed,
        );
      }
    }
    final localRestoreError =
        demoState.persistenceStatus == LocalPersistenceStatus.unavailable
        ? ref.read(appLocalizationsProvider).notebookLocalRestoreUnavailable
        : null;
    return NotebookLibraryState(
      collections: collections,
      selectedCollectionKey: selected.routeKey,
      localEntries: localEntries,
      liveEntries: liveEntries,
      entriesError: entriesError,
      mutationError: remoteLoadError ?? localRestoreError,
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
        liveEntries: const <NotebookEntry>[],
        query: '',
        isLoadingEntries: collection.source == NotebookDataSource.remote,
        clearEntriesError: true,
        clearMutationError: true,
      ),
    );

    if (collection.source != NotebookDataSource.remote) return;

    try {
      final entries = await _repository.loadEntries(collection);
      state = AsyncData(
        state.requireValue.copyWith(
          liveEntries: entries,
          isLoadingEntries: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isLoadingEntries: false,
          entriesError: _message(
            error,
            ref.read(appLocalizationsProvider).notebookEntriesLoadFailed,
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
        current.copyWith(
          mutationError: ref
              .read(appLocalizationsProvider)
              .collectionNameRequired,
        ),
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
          liveEntries: const <NotebookEntry>[],
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
            ref.read(appLocalizationsProvider).notebookCreateFailed,
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
          mutationError: ref
              .read(appLocalizationsProvider)
              .wordAndMeaningRequired,
        ),
      );
      return false;
    }
    if (collection.source != NotebookDataSource.remote ||
        collection.remoteId == null) {
      state = AsyncData(
        current.copyWith(
          mutationError: ref
              .read(appLocalizationsProvider)
              .selectLiveCollectionForManualEntry,
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
          liveEntries: _mergeEntries(<NotebookEntry>[
            entry,
            ...latest.liveEntries,
          ]),
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
            ref.read(appLocalizationsProvider).notebookAddFailed,
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

    if (entry.origin == NotebookItemOrigin.fixture) {
      await ref
          .read(demoNotebookControllerProvider.notifier)
          .removeEntry(entry);
      final localState = await ref.read(demoNotebookControllerProvider.future);
      final removed = !localState.entries.any(
        (candidate) => candidate.key == entry.key,
      );
      state = AsyncData(
        current.copyWith(
          localEntries: localState.entries,
          collections: _replaceDemoCollectionCount(
            current.collections,
            localState.entries.length,
          ),
          mutationError: removed
              ? null
              : ref.read(appLocalizationsProvider).notebookLocalRemoveFailed,
          clearMutationError: removed,
        ),
      );
      return removed;
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
          liveEntries: latest.liveEntries
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
            ref.read(appLocalizationsProvider).notebookRemoveFailed,
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

  void clearEntriesError() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearEntriesError: true));
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

  List<NotebookCollection> _replaceDemoCollectionCount(
    List<NotebookCollection> collections,
    int count,
  ) {
    if (count == 0) {
      return collections
          .where((item) => item.routeKey != demoCollectionRouteKey)
          .toList(growable: false);
    }
    final containsDemo = collections.any(
      (item) => item.routeKey == demoCollectionRouteKey,
    );
    if (!containsDemo) {
      return <NotebookCollection>[
        NotebookCollection(
          routeKey: demoCollectionRouteKey,
          remoteId: null,
          name: ref.read(appLocalizationsProvider).savedFromLessons,
          entryCount: count,
          createdAt: null,
          source: NotebookDataSource.fixture,
        ),
        ...collections,
      ];
    }
    return collections
        .map(
          (item) => item.routeKey == demoCollectionRouteKey
              ? item.copyWith(entryCount: count)
              : item,
        )
        .toList(growable: false);
  }

  List<NotebookEntry> _mergeEntries(List<NotebookEntry> entries) {
    final unique = <NotebookEntryKey, NotebookEntry>{};
    final sorted = List<NotebookEntry>.of(entries)
      ..sort((left, right) => right.addedAt.compareTo(left.addedAt));
    for (final entry in sorted) {
      unique.putIfAbsent(entry.key, () => entry);
    }
    return List<NotebookEntry>.unmodifiable(unique.values);
  }

  String _message(Object error, String fallback) {
    return appErrorMessage(
      error,
      ref.read(appLocalizationsProvider),
      fallback: fallback,
    );
  }
}

class NotebookLibraryState {
  const NotebookLibraryState({
    required this.collections,
    required this.localEntries,
    required this.liveEntries,
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
  final List<NotebookEntry> localEntries;
  final List<NotebookEntry> liveEntries;
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

  List<NotebookEntry> get entries {
    final candidates = selectedCollection?.source == NotebookDataSource.fixture
        ? localEntries
        : <NotebookEntry>[...localEntries, ...liveEntries];
    final sorted = List<NotebookEntry>.of(candidates)
      ..sort((left, right) => right.addedAt.compareTo(left.addedAt));
    final unique = <NotebookEntryKey, NotebookEntry>{};
    for (final entry in sorted) {
      unique.putIfAbsent(entry.key, () => entry);
    }
    return List<NotebookEntry>.unmodifiable(unique.values);
  }

  bool get canAddManualEntry =>
      selectedCollection?.source == NotebookDataSource.remote &&
      selectedCollection?.remoteId != null;

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
      localEntries.isNotEmpty;

  NotebookLibraryState copyWith({
    List<NotebookCollection>? collections,
    String? selectedCollectionKey,
    List<NotebookEntry>? localEntries,
    List<NotebookEntry>? liveEntries,
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
      localEntries: localEntries ?? this.localEntries,
      liveEntries: liveEntries ?? this.liveEntries,
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
