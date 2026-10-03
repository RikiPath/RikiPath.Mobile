import 'package:rikipath_mobile/features/notebook/domain/demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class SessionDemoNotebookRepository implements DemoNotebookRepository {
  final Map<NotebookEntryKey, NotebookEntry> _entries =
      <NotebookEntryKey, NotebookEntry>{};

  @override
  Future<List<NotebookEntry>> loadEntries() async {
    final entries = _entries.values.toList(growable: false);
    entries.sort((left, right) => right.addedAt.compareTo(left.addedAt));
    return entries;
  }

  @override
  Future<bool> isSaved(NotebookEntryKey key) async => _entries.containsKey(key);

  @override
  Future<NotebookEntry> saveEntry(NotebookFixtureDraft draft) async {
    final key = draft.key;
    final existing = _entries[key];
    if (existing != null) return existing;
    final entry = NotebookEntry(
      key: key,
      remoteNoteEntryId: null,
      contentType: draft.contentType,
      term: draft.term,
      reading: draft.reading,
      meaning: draft.meaning,
      note: draft.note,
      addedAt: DateTime.now().toUtc(),
      vocabularyRouteKey: draft.contentType == NotebookContentType.vocabulary
          ? draft.stableKey
          : null,
    );
    _entries[key] = entry;
    return entry;
  }

  @override
  Future<void> removeEntry(NotebookEntryKey key) async => _entries.remove(key);

  @override
  Future<void> reset() async => _entries.clear();
}
