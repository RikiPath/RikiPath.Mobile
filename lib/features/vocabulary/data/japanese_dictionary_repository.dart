import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';

@immutable
class JapaneseDictionaryCandidate {
  const JapaneseDictionaryCandidate({
    required this.id,
    required this.surface,
    required this.readingKana,
    this.meaning,
    this.sinoVietnamese,
  });

  factory JapaneseDictionaryCandidate.fromJson(Map<String, Object?> json) {
    return JapaneseDictionaryCandidate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      surface: json['surface'] as String? ?? '',
      readingKana: json['readingKana'] as String? ?? '',
      meaning: json['meaning'] as String?,
      sinoVietnamese: json['sinoVietnamese'] as String?,
    );
  }

  final int id;
  final String surface;
  final String readingKana;
  final String? meaning;
  final String? sinoVietnamese;
}

class JapaneseDictionaryRepository {
  const JapaneseDictionaryRepository(this._client);

  final ApiClient _client;

  Future<List<JapaneseDictionaryCandidate>> searchByKana(
    String readingKana,
  ) async {
    final response = await _client.get<Object?>(
      '/api/japanese-dictionary/search',
      queryParameters: <String, Object?>{'readingKana': readingKana.trim()},
    );
    final body = response.data;
    final rawList = body is Map
        ? (body['result'] ?? body['data'])
        : body;
    if (rawList is! List) return const <JapaneseDictionaryCandidate>[];
    return rawList
        .whereType<Map>()
        .map(
          (item) => JapaneseDictionaryCandidate.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }
}

final japaneseDictionaryRepositoryProvider =
    Provider<JapaneseDictionaryRepository>(
      (ref) => JapaneseDictionaryRepository(ref.watch(apiClientProvider)),
    );
