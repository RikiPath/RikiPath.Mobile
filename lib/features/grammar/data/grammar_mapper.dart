import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/grammar/data/grammar_dtos.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';

abstract final class GrammarMapper {
  static GrammarEntry fromRemote(GrammarCardDto dto) {
    return GrammarEntry(
      routeKey: 'remote-${dto.id}',
      remoteId: dto.id,
      title: dto.title,
      structure: dto.structure,
      explanation: nonEmpty(dto.explanation),
      exampleSentence: nonEmpty(dto.exampleSentence),
      level: parseLevel(dto.jlptLevelName),
      source: GrammarDataSource.remote,
    );
  }

  static JlptLevel parseLevel(String value) {
    return switch (value.trim().toUpperCase()) {
      'N5' => JlptLevel.n5,
      'N4' => JlptLevel.n4,
      'N3' => JlptLevel.n3,
      _ => throw FormatException(
        'Unsupported learner JLPT level returned by the API: $value',
      ),
    };
  }

  static String? nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
