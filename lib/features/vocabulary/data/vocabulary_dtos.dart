class VocabularySearchFilterDto {
  const VocabularySearchFilterDto({
    required this.keyword,
    required this.jlptLevelId,
    required this.page,
    required this.pageSize,
  });

  final String? keyword;
  final int? jlptLevelId;
  final int page;
  final int pageSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'jlptLevelId': jlptLevelId,
    'keyword': keyword,
    'page': page,
    'pageSize': pageSize,
  };
}

class VocabularyCardDto {
  const VocabularyCardDto({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.partOfSpeech,
    required this.exampleSentence,
    required this.audioUrl,
    required this.jlptLevelName,
  });

  factory VocabularyCardDto.fromJson(Map<String, Object?> json) {
    return VocabularyCardDto(
      id: _requiredInt(json, 'id'),
      word: _requiredString(json, 'word'),
      reading: _requiredString(json, 'reading'),
      meaning: _requiredString(json, 'meaning'),
      partOfSpeech: _optionalString(json, 'partOfSpeech'),
      // The source response declares a string, but its mapper assigns a
      // nullable entity field while null JSON values are omitted globally.
      exampleSentence: _optionalString(json, 'exampleSentence'),
      audioUrl: _optionalString(json, 'audioUrl'),
      jlptLevelName: _requiredString(json, 'jlptLevelName'),
    );
  }

  final int id;
  final String word;
  final String reading;
  final String meaning;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? audioUrl;
  final String jlptLevelName;
}

class VocabularyPageDto {
  const VocabularyPageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory VocabularyPageDto.fromEnvelope(Object? body) {
    final result = _readResult(body);
    final rawItems = result['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('Expected items to be a JSON array.');
    }

    return VocabularyPageDto(
      items: rawItems
          .map(_stringKeyedMap)
          .map(VocabularyCardDto.fromJson)
          .toList(growable: false),
      page: _requiredInt(result, 'page'),
      pageSize: _requiredInt(result, 'pageSize'),
      totalCount: _requiredInt(result, 'totalCount'),
      totalPages: _requiredInt(result, 'totalPages'),
    );
  }

  final List<VocabularyCardDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}

VocabularyCardDto readVocabularyDetail(Object? body) {
  return VocabularyCardDto.fromJson(_readResult(body));
}

Map<String, Object?> _readResult(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful API envelope.');
  }
  return _stringKeyedMap(envelope['result']);
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
  if (value is num) return value.toInt();
  throw FormatException('Expected an integer field named $field.');
}
