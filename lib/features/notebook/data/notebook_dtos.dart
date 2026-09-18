class NotebookCollectionDto {
  const NotebookCollectionDto({
    required this.id,
    required this.name,
    required this.description,
    required this.entryCount,
    required this.createdAt,
  });

  factory NotebookCollectionDto.fromJson(Map<String, Object?> json) {
    return NotebookCollectionDto(
      id: _requiredInt(json, 'id'),
      name: _requiredString(json, 'name'),
      description: _optionalString(json, 'description'),
      entryCount: _requiredInt(json, 'entryCount'),
      createdAt: _requiredDateTime(json, 'createdAt'),
    );
  }

  final int id;
  final String name;
  final String? description;
  final int entryCount;
  final DateTime createdAt;
}

class NotebookEntryDto {
  const NotebookEntryDto({
    required this.noteEntryId,
    required this.reviewItemId,
    required this.contentType,
    required this.term,
    required this.reading,
    required this.meaning,
    required this.note,
    required this.addedAt,
  });

  factory NotebookEntryDto.fromJson(Map<String, Object?> json) {
    return NotebookEntryDto(
      noteEntryId: _requiredInt(json, 'noteEntryId'),
      reviewItemId: _optionalInt(json, 'reviewItemId'),
      contentType: _requiredString(json, 'contentType'),
      term: _requiredString(json, 'term'),
      reading: _optionalString(json, 'reading'),
      meaning: _requiredString(json, 'meaning'),
      note: _optionalString(json, 'note'),
      addedAt: _requiredDateTime(json, 'addedAt'),
    );
  }

  final int noteEntryId;
  final int? reviewItemId;
  final String contentType;
  final String term;
  final String? reading;
  final String meaning;
  final String? note;
  final DateTime addedAt;
}

class CreateNotebookCollectionRequestDto {
  const CreateNotebookCollectionRequestDto({
    required this.name,
    required this.description,
  });

  final String name;
  final String? description;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'description': description,
  };
}

class AddManualNotebookEntryRequestDto {
  const AddManualNotebookEntryRequestDto({
    required this.vocabularyListId,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.note,
  });

  final int vocabularyListId;
  final String word;
  final String? reading;
  final String meaning;
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
    'vocabularyListId': vocabularyListId,
    'word': word,
    'reading': reading,
    'meaning': meaning,
    'note': note,
  };
}

class BookmarkVocabularyRequestDto {
  const BookmarkVocabularyRequestDto({
    required this.vocabularyListId,
    required this.vocabularyEntryId,
  });

  final int vocabularyListId;
  final int vocabularyEntryId;

  Map<String, Object?> toJson() => <String, Object?>{
    'vocabularyListId': vocabularyListId,
    'vocabularyEntryId': vocabularyEntryId,
  };
}

List<NotebookCollectionDto> readNotebookCollections(Object? body) {
  final result = _readResult(body);
  if (result is! List<Object?>) {
    throw const FormatException('Expected result to be a JSON array.');
  }
  return result
      .map(_stringKeyedMap)
      .map(NotebookCollectionDto.fromJson)
      .toList(growable: false);
}

List<NotebookEntryDto> readNotebookEntries(Object? body) {
  final result = _readResult(body);
  if (result is! List<Object?>) {
    throw const FormatException('Expected result to be a JSON array.');
  }
  return result
      .map(_stringKeyedMap)
      .map(NotebookEntryDto.fromJson)
      .toList(growable: false);
}

NotebookCollectionDto readNotebookCollection(Object? body) {
  return NotebookCollectionDto.fromJson(_stringKeyedMap(_readResult(body)));
}

NotebookEntryDto readNotebookEntry(Object? body) {
  return NotebookEntryDto.fromJson(_stringKeyedMap(_readResult(body)));
}

Object? _readResult(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful API envelope.');
  }
  return envelope['result'];
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw const FormatException('Expected JSON object keys to be strings.');
    }
    result[key] = entry.value;
  }
  return result;
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected a nullable string field named $field.');
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Expected an integer field named $field.');
}

int? _optionalInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Expected a nullable integer field named $field.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String field) {
  final value = _requiredString(json, field);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Expected an ISO-8601 field named $field.');
  }
  return parsed;
}
