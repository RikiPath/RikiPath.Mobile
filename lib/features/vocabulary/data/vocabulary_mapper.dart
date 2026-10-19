import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/vocabulary/data/vocabulary_dtos.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';

abstract final class VocabularyMapper {
  static VocabularyEntry fromRemote(VocabularyCardDto dto) {
    return VocabularyEntry(
      routeKey: 'remote-${dto.id}',
      remoteId: dto.id,
      word: dto.word,
      reading: dto.reading,
      meaning: dto.meaning,
      level: _parseLevel(dto.jlptLevelName),
      source: VocabularyDataSource.remote,
      partOfSpeech: _nonEmpty(dto.partOfSpeech),
      exampleSentence: _nonEmpty(dto.exampleSentence),
      audioUrl: _audioUri(dto.audioUrl),
    );
  }

  static JlptLevel _parseLevel(String value) {
    final level = JlptLevel.tryParse(value);
    if (level != null) return level;
    throw FormatException(
      'Unsupported learner JLPT level returned by the API: $value',
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Uri? _audioUri(String? value) {
    final normalized = _nonEmpty(value);
    if (normalized == null) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri;
  }
}
