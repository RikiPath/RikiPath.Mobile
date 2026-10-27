import 'package:flutter/foundation.dart';

enum NotebookDataSource { remote, local, fixture }

enum NotebookContentType { vocabulary, kanji, grammar, manual, unknown }

enum NotebookItemOrigin { live, fixture }

/// Stable domain/UI identity for a Notebook entry.
///
/// This key is safe for routing and comparison. It is never itself a backend
/// ID. A backend note-entry ID can only be obtained from [liveNoteEntryId]
/// after a key has been decoded as [NotebookItemOrigin.live].
@immutable
class NotebookEntryKey {
  const NotebookEntryKey._({
    required this.origin,
    required this.contentType,
    required this.stableKey,
  });

  factory NotebookEntryKey.live({
    required NotebookContentType contentType,
    required int noteEntryId,
  }) {
    if (noteEntryId <= 0) {
      throw ArgumentError.value(
        noteEntryId,
        'noteEntryId',
        'A positive backend note-entry ID is required.',
      );
    }
    return NotebookEntryKey._(
      origin: NotebookItemOrigin.live,
      contentType: contentType,
      stableKey: '$noteEntryId',
    );
  }

  factory NotebookEntryKey.fixture({
    required NotebookContentType contentType,
    required String stableKey,
  }) {
    final normalized = stableKey.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        stableKey,
        'stableKey',
        'A non-empty fixture key is required.',
      );
    }
    return NotebookEntryKey._(
      origin: NotebookItemOrigin.fixture,
      contentType: contentType,
      stableKey: normalized,
    );
  }

  final NotebookItemOrigin origin;
  final NotebookContentType contentType;
  final String stableKey;

  String get encoded =>
      '${origin.name}:${contentType.name}:${Uri.encodeComponent(stableKey)}';

  int? get liveNoteEntryId {
    if (origin != NotebookItemOrigin.live) return null;
    final value = int.tryParse(stableKey);
    return value != null && value > 0 ? value : null;
  }

  static NotebookEntryKey? tryParse(String value) {
    final firstSeparator = value.indexOf(':');
    if (firstSeparator <= 0) return null;
    final secondSeparator = value.indexOf(':', firstSeparator + 1);
    if (secondSeparator <= firstSeparator + 1 ||
        secondSeparator >= value.length - 1) {
      return null;
    }

    final origin = switch (value.substring(0, firstSeparator)) {
      'live' => NotebookItemOrigin.live,
      'fixture' => NotebookItemOrigin.fixture,
      _ => null,
    };
    final contentType = NotebookContentType.values
        .where(
          (candidate) =>
              candidate.name ==
              value.substring(firstSeparator + 1, secondSeparator),
        )
        .firstOrNull;
    if (origin == null || contentType == null) return null;

    String stableKey;
    try {
      stableKey = Uri.decodeComponent(value.substring(secondSeparator + 1));
    } on FormatException {
      return null;
    }
    if (stableKey.trim().isEmpty) return null;
    if (origin == NotebookItemOrigin.live) {
      final noteEntryId = int.tryParse(stableKey);
      if (noteEntryId == null || noteEntryId <= 0) return null;
      return NotebookEntryKey.live(
        contentType: contentType,
        noteEntryId: noteEntryId,
      );
    }
    return NotebookEntryKey.fixture(
      contentType: contentType,
      stableKey: stableKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotebookEntryKey &&
      other.origin == origin &&
      other.contentType == contentType &&
      other.stableKey == stableKey;

  @override
  int get hashCode => Object.hash(origin, contentType, stableKey);

  @override
  String toString() => encoded;
}

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

  bool get isLive => source == NotebookDataSource.remote && remoteId != null;

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
    required this.key,
    required this.remoteNoteEntryId,
    required this.contentType,
    required this.term,
    required this.meaning,
    required this.addedAt,
    this.reviewCardId,
    this.reading,
    this.note,
    this.vocabularyRouteKey,
    this.sourceVocabularyId,
    this.sourceKanjiId,
  });

  final NotebookEntryKey key;
  final int? remoteNoteEntryId;
  final int? reviewCardId;
  final NotebookContentType contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final DateTime addedAt;

  /// Present only when a data source can prove the corresponding vocabulary
  /// route identity. The current Notebook API response does not expose it.
  final String? vocabularyRouteKey;
  final int? sourceVocabularyId;
  final int? sourceKanjiId;

  String get routeKey => key.encoded;

  NotebookItemOrigin get origin => key.origin;

  NotebookDataSource get source => origin == NotebookItemOrigin.live
      ? NotebookDataSource.remote
      : NotebookDataSource.fixture;

  NotebookEntry copyWith({
    String? vocabularyRouteKey,
    int? sourceVocabularyId,
    int? sourceKanjiId,
  }) {
    return NotebookEntry(
      key: key,
      remoteNoteEntryId: remoteNoteEntryId,
      reviewCardId: reviewCardId,
      contentType: contentType,
      term: term,
      reading: reading,
      meaning: meaning,
      note: note,
      addedAt: addedAt,
      vocabularyRouteKey: vocabularyRouteKey ?? this.vocabularyRouteKey,
      sourceVocabularyId: sourceVocabularyId ?? this.sourceVocabularyId,
      sourceKanjiId: sourceKanjiId ?? this.sourceKanjiId,
    );
  }
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

@immutable
class NotebookVocabularyDraft {
  const NotebookVocabularyDraft({
    required this.routeKey,
    required this.remoteId,
    required this.term,
    required this.reading,
    required this.meaning,
    required this.jlptLevel,
    this.exampleSentence,
  });

  /// Stable frontend identity established by the Vocabulary feature. This is
  /// deliberately separate from the optional backend numeric ID.
  final String routeKey;
  final int? remoteId;
  final String term;
  final String? reading;
  final String meaning;
  final String? jlptLevel;
  final String? exampleSentence;
}

@immutable
class NotebookKanjiDraft {
  const NotebookKanjiDraft({
    required this.remoteId,
    required this.character,
    required this.meaning,
    this.reading,
  });

  final int remoteId;
  final String character;
  final String meaning;
  final String? reading;
}

@immutable
class NotebookFixtureDraft {
  const NotebookFixtureDraft({
    required this.stableKey,
    required this.contentType,
    required this.term,
    required this.meaning,
    this.reading,
    this.note,
    this.jlptLevel,
  });

  final String stableKey;
  final NotebookContentType contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final String? jlptLevel;

  NotebookEntryKey get key =>
      NotebookEntryKey.fixture(contentType: contentType, stableKey: stableKey);
}
