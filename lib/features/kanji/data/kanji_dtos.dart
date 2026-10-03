class KanjiSearchFilterDto {
  const KanjiSearchFilterDto({
    required this.jlptLevelId,
    required this.keyword,
    required this.page,
    required this.pageSize,
    required this.minStrokeCount,
    required this.maxStrokeCount,
  });

  final int? jlptLevelId;
  final String? keyword;
  final int page;
  final int pageSize;
  final int? minStrokeCount;
  final int? maxStrokeCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'jlptLevelId': jlptLevelId,
    'keyword': keyword,
    'page': page,
    'pageSize': pageSize,
    'minStrokeCount': minStrokeCount,
    'maxStrokeCount': maxStrokeCount,
  };
}

class KanjiCardDto {
  const KanjiCardDto({
    required this.id,
    required this.character,
    required this.onYomi,
    required this.kunYomi,
    required this.sinoVietnamese,
    required this.meaning,
    required this.strokeCount,
    required this.strokeOrderUrl,
    required this.audioUrl,
    required this.jlptLevelName,
  });

  factory KanjiCardDto.fromJson(Map<String, Object?> json) {
    return KanjiCardDto(
      id: requiredInt(json, 'id'),
      character: requiredString(json, 'character'),
      // The entity is nullable even though the response model is declared
      // non-nullable, and global JSON settings omit null fields.
      onYomi: optionalString(json, 'onYomi'),
      kunYomi: optionalString(json, 'kunYomi'),
      sinoVietnamese: optionalString(json, 'sinoVietnamese'),
      meaning: requiredString(json, 'meaning'),
      strokeCount: requiredInt(json, 'strokeCount'),
      strokeOrderUrl: optionalString(json, 'strokeOrderUrl'),
      audioUrl: optionalString(json, 'audioUrl'),
      jlptLevelName: requiredString(json, 'jlptLevelName'),
    );
  }

  final int id;
  final String character;
  final String? onYomi;
  final String? kunYomi;
  final String? sinoVietnamese;
  final String meaning;
  final int strokeCount;
  final String? strokeOrderUrl;
  final String? audioUrl;
  final String jlptLevelName;
}

class KanjiPageDto {
  const KanjiPageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory KanjiPageDto.fromEnvelope(Object? body) {
    final result = readEnvelopeResult(body);
    final rawItems = result['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('Expected items to be a JSON array.');
    }
    return KanjiPageDto(
      items: rawItems
          .map(stringKeyedMap)
          .map(KanjiCardDto.fromJson)
          .toList(growable: false),
      page: requiredInt(result, 'page'),
      pageSize: requiredInt(result, 'pageSize'),
      totalCount: requiredInt(result, 'totalCount'),
      totalPages: requiredInt(result, 'totalPages'),
    );
  }

  final List<KanjiCardDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}

class KanjiNotebookListDto {
  const KanjiNotebookListDto({
    required this.id,
    required this.name,
    required this.entryCount,
    required this.description,
  });

  factory KanjiNotebookListDto.fromJson(Map<String, Object?> json) {
    return KanjiNotebookListDto(
      id: requiredInt(json, 'id'),
      name: requiredString(json, 'name'),
      entryCount: requiredInt(json, 'entryCount'),
      description: optionalString(json, 'description'),
    );
  }

  final int id;
  final String name;
  final int entryCount;
  final String? description;
}

class BookmarkKanjiRequestDto {
  const BookmarkKanjiRequestDto({
    required this.learnerNoteId,
    required this.kanjiId,
  });

  final int learnerNoteId;
  final int kanjiId;

  Map<String, Object?> toJson() => <String, Object?>{
    'learnerNoteId': learnerNoteId,
    'kanjiId': kanjiId,
  };
}

class KanjiNotebookEntryDto {
  const KanjiNotebookEntryDto({required this.noteEntryId});

  factory KanjiNotebookEntryDto.fromEnvelope(Object? body) {
    return KanjiNotebookEntryDto(
      noteEntryId: requiredInt(readEnvelopeResult(body), 'noteEntryId'),
    );
  }

  final int noteEntryId;
}

KanjiCardDto readKanjiDetail(Object? body) {
  return KanjiCardDto.fromJson(readEnvelopeResult(body));
}

List<KanjiNotebookListDto> readKanjiNotebookLists(Object? body) {
  final envelope = stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful API envelope.');
  }
  final rawResult = envelope['result'];
  if (rawResult is! List<Object?>) {
    throw const FormatException('Expected result to be a JSON array.');
  }
  return rawResult
      .map(stringKeyedMap)
      .map(KanjiNotebookListDto.fromJson)
      .toList(growable: false);
}

Map<String, Object?> readEnvelopeResult(Object? body) {
  final envelope = stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful API envelope.');
  }
  return stringKeyedMap(envelope['result']);
}

Map<String, Object?> stringKeyedMap(Object? value) {
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

String requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected a nullable string field named $field.');
}

int requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Expected an integer field named $field.');
}
