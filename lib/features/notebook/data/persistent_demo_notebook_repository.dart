import 'dart:convert';

import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/notebook/domain/demo_notebook_repository.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class PersistentDemoNotebookRepository implements DemoNotebookRepository {
  PersistentDemoNotebookRepository(this._store);

  static const storageKey = 'r3_3_fixture_notebook_v2';
  static const legacyStorageKey = 'r3_fixture_notebook_v1';

  final JsonPreferenceStore _store;
  List<NotebookEntry>? _entries;

  @override
  Future<List<NotebookEntry>> loadEntries() async {
    final cached = _entries;
    if (cached != null) return _sorted(cached);

    var encoded = await _store.read(storageKey);
    final isLegacy = encoded == null;
    encoded ??= await _store.read(legacyStorageKey);
    if (encoded == null) {
      _entries = <NotebookEntry>[];
      return const <NotebookEntry>[];
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Fixture bookmarks must be a JSON list.');
    }
    final entries = <NotebookEntry>[];
    for (final value in decoded) {
      try {
        entries.add(_decodeEntry(value));
      } on FormatException {
        // One stale/corrupt fixture snapshot must not discard valid entries.
      }
    }
    _entries = _deduplicated(entries);
    if (isLegacy) {
      await _persist();
      await _store.remove(legacyStorageKey);
    }
    return _sorted(_entries!);
  }

  @override
  Future<bool> isSaved(NotebookEntryKey key) async {
    final entries = await loadEntries();
    return entries.any((entry) => entry.key == key);
  }

  @override
  Future<NotebookEntry> saveEntry(NotebookFixtureDraft draft) async {
    final entries = await loadEntries();
    final key = draft.key;
    final existing = entries.where((entry) => entry.key == key).firstOrNull;
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
    _entries = <NotebookEntry>[entry, ...entries];
    await _persist();
    return entry;
  }

  @override
  Future<void> removeEntry(NotebookEntryKey key) async {
    final entries = await loadEntries();
    _entries = entries
        .where((entry) => entry.key != key)
        .toList(growable: true);
    await _persist();
  }

  @override
  Future<void> reset() async {
    _entries = <NotebookEntry>[];
    await _store.remove(storageKey);
  }

  Future<void> _persist() {
    final encoded = jsonEncode(
      (_entries ?? const <NotebookEntry>[])
          .map(
            (entry) => <String, Object?>{
              'entryKey': entry.key.encoded,
              'contentType': entry.contentType.name,
              'vocabularyRouteKey': entry.vocabularyRouteKey,
              'term': entry.term,
              'reading': entry.reading,
              'meaning': entry.meaning,
              'note': entry.note,
              'addedAt': entry.addedAt.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
    );
    return _store.write(storageKey, encoded);
  }

  NotebookEntry _decodeEntry(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Fixture bookmark entry is invalid.');
    }
    final encodedEntryKey = value['entryKey'];
    final vocabularyRouteKey = value['vocabularyRouteKey'];
    final contentTypeValue = value['contentType'];
    final term = value['term'];
    final reading = value['reading'];
    final meaning = value['meaning'];
    final note = value['note'];
    final addedAtValue = value['addedAt'];
    if (term is! String ||
        (reading != null && reading is! String) ||
        meaning is! String ||
        (note != null && note is! String) ||
        addedAtValue is! String) {
      throw const FormatException('Fixture bookmark fields are invalid.');
    }
    final key = encodedEntryKey is String
        ? NotebookEntryKey.tryParse(encodedEntryKey)
        : vocabularyRouteKey is String
        ? NotebookEntryKey.fixture(
            contentType: NotebookContentType.vocabulary,
            stableKey: vocabularyRouteKey,
          )
        : null;
    if (key == null || key.origin != NotebookItemOrigin.fixture) {
      throw const FormatException('Fixture bookmark key is invalid.');
    }
    final contentType = contentTypeValue is String
        ? NotebookContentType.values
              .where((candidate) => candidate.name == contentTypeValue)
              .firstOrNull
        : key.contentType;
    if (contentType == null || contentType != key.contentType) {
      throw const FormatException('Fixture bookmark type is invalid.');
    }
    final addedAt = DateTime.tryParse(addedAtValue)?.toUtc();
    if (addedAt == null) {
      throw const FormatException('Fixture bookmark date is invalid.');
    }
    return NotebookEntry(
      key: key,
      remoteNoteEntryId: null,
      contentType: contentType,
      term: term,
      reading: reading as String?,
      meaning: meaning,
      note: note as String?,
      addedAt: addedAt,
      vocabularyRouteKey: contentType == NotebookContentType.vocabulary
          ? (vocabularyRouteKey as String?) ?? key.stableKey
          : null,
    );
  }

  List<NotebookEntry> _deduplicated(List<NotebookEntry> entries) {
    final unique = <NotebookEntryKey, NotebookEntry>{};
    for (final entry in _sorted(entries)) {
      unique.putIfAbsent(entry.key, () => entry);
    }
    return unique.values.toList(growable: true);
  }

  List<NotebookEntry> _sorted(List<NotebookEntry> entries) {
    final sorted = List<NotebookEntry>.of(entries);
    sorted.sort((left, right) => right.addedAt.compareTo(left.addedAt));
    return List<NotebookEntry>.unmodifiable(sorted);
  }
}
