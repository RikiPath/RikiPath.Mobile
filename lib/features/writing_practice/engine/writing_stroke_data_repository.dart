import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';

final writingStrokeDataRepositoryProvider =
    Provider<WritingStrokeDataRepository>((ref) {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          headers: const <String, Object?>{'Accept': 'application/json'},
        ),
      );
      ref.onDispose(() => dio.close());
      return CachedNetworkWritingStrokeDataRepository(
        dio,
        ref.watch(jsonPreferenceStoreProvider),
      );
    });

abstract interface class WritingStrokeDataRepository {
  Future<String> load({
    required String character,
    required WritingScript script,
  });
}

class CachedNetworkWritingStrokeDataRepository
    implements WritingStrokeDataRepository {
  CachedNetworkWritingStrokeDataRepository(this._dio, this._cache);

  final Dio _dio;
  final JsonPreferenceStore _cache;

  @override
  Future<String> load({
    required String character,
    required WritingScript script,
  }) async {
    if (character.runes.length != 1) {
      throw const WritingStrokeDataException('Unsupported character.');
    }
    final cacheKey = _cacheKey(character, script);
    try {
      final cached = await _cache.read(cacheKey);
      if (cached != null && _isValidStrokeData(cached)) return cached;
    } catch (_) {
      // A cache failure must not prevent the authoritative public data fetch.
    }

    try {
      final response = await _dio.get<Object?>(_sourceUri(character, script));
      final raw = switch (response.data) {
        final String value => value,
        final Map<Object?, Object?> value => jsonEncode(value),
        _ => throw const FormatException('Unexpected stroke data response.'),
      };
      if (!_isValidStrokeData(raw)) {
        throw const FormatException('Invalid stroke data response.');
      }
      try {
        await _cache.write(cacheKey, raw);
      } catch (_) {
        // Practice can continue even when the local cache is unavailable.
      }
      return raw;
    } catch (error) {
      throw WritingStrokeDataException('Stroke data unavailable.', error);
    }
  }
}

class WritingStrokeDataException implements Exception {
  const WritingStrokeDataException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

String _sourceUri(String character, WritingScript script) {
  final encoded = Uri.encodeComponent(character);
  return switch (script) {
    WritingScript.hiragana || WritingScript.katakana =>
      'https://cdn.jsdelivr.net/gh/ailectra/kana-json@v0.0.1/data/$encoded.json',
    WritingScript.kanji =>
      'https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/$encoded.json',
  };
}

String _cacheKey(String character, WritingScript script) {
  final codePoint = character.runes.single.toRadixString(16);
  return 'writing.stroke.v1.${script.name}.$codePoint';
}

bool _isValidStrokeData(String raw) {
  try {
    final value = jsonDecode(raw);
    if (value is! Map<String, Object?>) return false;
    final strokes = value['strokes'];
    final medians = value['medians'];
    return strokes is List<Object?> &&
        medians is List<Object?> &&
        strokes.isNotEmpty &&
        strokes.length == medians.length;
  } catch (_) {
    return false;
  }
}
