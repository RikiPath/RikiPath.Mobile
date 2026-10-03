import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/notebook/data/persistent_demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

final demoNotebookRepositoryProvider = Provider<DemoNotebookRepository>(
  (ref) =>
      PersistentDemoNotebookRepository(ref.watch(jsonPreferenceStoreProvider)),
);

final demoNotebookControllerProvider =
    AsyncNotifierProvider<DemoNotebookController, DemoNotebookState>(
      DemoNotebookController.new,
    );

class DemoNotebookState {
  const DemoNotebookState({
    this.entries = const <NotebookEntry>[],
    this.persistenceStatus = LocalPersistenceStatus.available,
  });

  final List<NotebookEntry> entries;
  final LocalPersistenceStatus persistenceStatus;
}

class DemoNotebookController extends AsyncNotifier<DemoNotebookState> {
  DemoNotebookRepository get _repository =>
      ref.read(demoNotebookRepositoryProvider);

  @override
  Future<DemoNotebookState> build() async {
    try {
      return DemoNotebookState(entries: await _repository.loadEntries());
    } catch (_) {
      try {
        await _repository.reset();
      } catch (_) {
        // The empty in-memory fallback remains usable when storage is offline.
      }
      return const DemoNotebookState(
        persistenceStatus: LocalPersistenceStatus.unavailable,
      );
    }
  }

  bool isSaved(NotebookEntryKey key) =>
      state.value?.entries.any((entry) => entry.key == key) ?? false;

  Future<bool> toggleEntry(NotebookFixtureDraft draft) async {
    final current = state.value ?? await future;
    var persistenceStatus = current.persistenceStatus;
    try {
      if (current.entries.any((entry) => entry.key == draft.key)) {
        await _repository.removeEntry(draft.key);
      } else {
        await _repository.saveEntry(draft);
      }
    } catch (_) {
      persistenceStatus = LocalPersistenceStatus.unavailable;
    }
    final entries = await _safeEntries(current.entries);
    state = AsyncData(
      DemoNotebookState(entries: entries, persistenceStatus: persistenceStatus),
    );
    return entries.any((entry) => entry.key == draft.key);
  }

  Future<bool> saveEntry(NotebookFixtureDraft draft) async {
    final current = state.value ?? await future;
    var persistenceStatus = current.persistenceStatus;
    try {
      await _repository.saveEntry(draft);
    } catch (_) {
      persistenceStatus = LocalPersistenceStatus.unavailable;
    }
    final entries = await _safeEntries(current.entries);
    state = AsyncData(
      DemoNotebookState(entries: entries, persistenceStatus: persistenceStatus),
    );
    return entries.any((entry) => entry.key == draft.key);
  }

  Future<void> removeEntry(NotebookEntry entry) async {
    final current = state.value ?? await future;
    var persistenceStatus = current.persistenceStatus;
    try {
      await _repository.removeEntry(entry.key);
    } catch (_) {
      persistenceStatus = LocalPersistenceStatus.unavailable;
    }
    state = AsyncData(
      DemoNotebookState(
        entries: await _safeEntries(current.entries),
        persistenceStatus: persistenceStatus,
      ),
    );
  }

  Future<void> reset() async {
    try {
      await _repository.reset();
      state = const AsyncData(DemoNotebookState());
    } catch (_) {
      state = const AsyncData(
        DemoNotebookState(
          persistenceStatus: LocalPersistenceStatus.unavailable,
        ),
      );
    }
  }

  Future<List<NotebookEntry>> _safeEntries(List<NotebookEntry> fallback) async {
    try {
      return await _repository.loadEntries();
    } catch (_) {
      return fallback;
    }
  }
}
