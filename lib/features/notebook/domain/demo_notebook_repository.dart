import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

abstract interface class DemoNotebookRepository {
  Future<List<NotebookEntry>> loadEntries();

  Future<bool> isSaved(NotebookEntryKey key);

  Future<NotebookEntry> saveEntry(NotebookFixtureDraft draft);

  Future<void> removeEntry(NotebookEntryKey key);

  Future<void> reset();
}
