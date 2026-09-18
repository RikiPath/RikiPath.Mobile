import 'package:flutter/foundation.dart';

enum NotebookDataSource { remote, fixture }

enum NotebookContentType { vocabulary, kanji, manual, unknown }

@immutable
class NotebookCollection {
  const NotebookCollection({
    required this.routeKey,
    required this.remoteId,
    required this.name,
    required this.entryCount,
    required this.createdAt,
    required this.source,
    this.description,
  });

  final String routeKey;
  final int? remoteId;
  final String name;
  final String? description;
  final int entryCount;
  final DateTime? createdAt;
  final NotebookDataSource source;

  NotebookCollection copyWith({int? entryCount}) {
    return NotebookCollection(
      routeKey: routeKey,
      remoteId: remoteId,
      name: name,
      description: description,
      entryCount: entryCount ?? this.entryCount,
      createdAt: createdAt,
      source: source,
    );
  }
}

@immutable
class NotebookEntry {
  const NotebookEntry({
    required this.routeKey,
    required this.remoteNoteEntryId,
    required this.contentType,
    required this.term,
    required this.meaning,
    required this.addedAt,
    required this.source,
    this.reviewItemId,
    this.reading,
    this.note,
    this.vocabularyRouteKey,
  });

  final String routeKey;
  final int? remoteNoteEntryId;
  final int? reviewItemId;
  final NotebookContentType contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final DateTime addedAt;
  final NotebookDataSource source;

  /// Present only when a data source can prove the corresponding vocabulary
  /// route identity. The current Notebook API response does not expose it.
  final String? vocabularyRouteKey;
}

@immutable
class NotebookBookmark {
  const NotebookBookmark({
    required this.noteEntryId,
    required this.collectionRouteKey,
    required this.collectionName,
  });

  final int? noteEntryId;
  final String collectionRouteKey;
  final String collectionName;
}
