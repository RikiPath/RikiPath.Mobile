class GrammarSearchFilterDto {
  const GrammarSearchFilterDto({
    required this.jlptLevelId,
    required this.keyword,
    required this.page,
    required this.pageSize,
  });

  final int? jlptLevelId;
  final String? keyword;
  final int page;
  final int pageSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'jlptLevelId': jlptLevelId,
    'keyword': keyword,
    'page': page,
    'pageSize': pageSize,
  };
}

class GrammarCardDto {
  const GrammarCardDto({
    required this.id,
    required this.title,
    required this.structure,
    required this.explanation,
    required this.exampleSentence,
    required this.jlptLevelName,
  });

  factory GrammarCardDto.fromJson(Map<String, Object?> json) {
    return GrammarCardDto(
      id: _requiredInt(json, 'id'),
      title: _requiredString(json, 'title'),
      structure: _requiredString(json, 'structure'),
      // These response properties are declared non-nullable, but their source
      // entity fields are nullable and null JSON fields are globally omitted.
      explanation: _optionalString(json, 'explanation'),
      exampleSentence: _optionalString(json, 'exampleSentence'),
      jlptLevelName: _requiredString(json, 'jlptLevelName'),
    );
  }

  final int id;
  final String title;
  final String structure;
  final String? explanation;
  final String? exampleSentence;
  final String jlptLevelName;
}

class GrammarPageDto {
  const GrammarPageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory GrammarPageDto.fromEnvelope(Object? body) {
    final result = _readEnvelopeResult(body);
    final rawItems = result['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('Expected items to be a JSON array.');
    }
    return GrammarPageDto(
      items: rawItems
          .map(_stringKeyedMap)
          .map(GrammarCardDto.fromJson)
          .toList(growable: false),
      page: _requiredInt(result, 'page'),
      pageSize: _requiredInt(result, 'pageSize'),
      totalCount: _requiredInt(result, 'totalCount'),
      totalPages: _requiredInt(result, 'totalPages'),
    );
  }

  final List<GrammarCardDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}

class GrammarBookmarkDto {
  const GrammarBookmarkDto({
    required this.reviewCardId,
    required this.grammarPatternId,
    required this.grammarTitle,
  });

  factory GrammarBookmarkDto.fromJson(Map<String, Object?> json) {
    return GrammarBookmarkDto(
      reviewCardId: _requiredInt(json, 'reviewCardId'),
      grammarPatternId: _requiredInt(json, 'grammarPatternId'),
      grammarTitle: _requiredString(json, 'grammarTitle'),
    );
  }

  final int reviewCardId;
  final int grammarPatternId;
  final String grammarTitle;
}

GrammarCardDto readGrammarDetail(Object? body) {
  return GrammarCardDto.fromJson(_readEnvelopeResult(body));
}

GrammarBookmarkDto readGrammarBookmark(Object? body) {
  return GrammarBookmarkDto.fromJson(_readEnvelopeResult(body));
}

Map<String, Object?> _readEnvelopeResult(Object? body) {
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
    if (entry.key case final String key) {
      result[key] = entry.value;
    } else {
      throw const FormatException('Expected JSON object keys to be strings.');
    }
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
  throw FormatException('Expected an integer field named $field.');
}
