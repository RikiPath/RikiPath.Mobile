class JlptLevelCatalogDto {
  const JlptLevelCatalogDto({
    required this.id,
    required this.code,
    required this.description,
    required this.sortOrder,
  });

  factory JlptLevelCatalogDto.fromJson(Map<String, Object?> json) {
    return JlptLevelCatalogDto(
      id: _requiredInt(json, 'id'),
      code: _requiredString(json, 'code'),
      description: _optionalString(json, 'description'),
      sortOrder: _requiredInt(json, 'sortOrder'),
    );
  }

  final int id;
  final String code;
  final String? description;
  final int sortOrder;
}

List<JlptLevelCatalogDto> readJlptLevelCatalog(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful catalog envelope.');
  }
  final result = envelope['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a catalog list.');
  }
  return result
      .map((item) => JlptLevelCatalogDto.fromJson(_stringKeyedMap(item)))
      .toList(growable: false);
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map((key, item) {
    if (key is! String) {
      throw const FormatException('Expected string JSON keys.');
    }
    return MapEntry(key, item);
  });
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Expected an integer field named $field.');
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
