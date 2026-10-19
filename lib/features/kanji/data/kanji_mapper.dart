import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/kanji/data/kanji_dtos.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';

abstract final class KanjiMapper {
  static KanjiEntry fromRemote(KanjiCardDto dto) {
    return KanjiEntry(
      routeKey: 'remote-${dto.id}',
      remoteId: dto.id,
      character: dto.character,
      meaning: dto.meaning,
      strokeCount: dto.strokeCount,
      level: parseLevel(dto.jlptLevelName),
      source: KanjiDataSource.remote,
      onYomi: nonEmpty(dto.onYomi),
      kunYomi: nonEmpty(dto.kunYomi),
      sinoVietnamese: nonEmpty(dto.sinoVietnamese),
      strokeOrderUrl: publicUri(dto.strokeOrderUrl),
      audioUrl: publicUri(dto.audioUrl),
    );
  }

  static KanjiNotebookList listFromRemote(KanjiNotebookListDto dto) {
    return KanjiNotebookList(
      id: dto.id,
      name: dto.name,
      entryCount: dto.entryCount,
      description: nonEmpty(dto.description),
    );
  }

  static JlptLevel parseLevel(String value) {
    final level = JlptLevel.tryParse(value);
    if (level != null) return level;
    throw FormatException(
      'Unsupported learner JLPT level returned by the API: $value',
    );
  }

  static String? nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Uri? publicUri(String? value) {
    final normalized = nonEmpty(value);
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
