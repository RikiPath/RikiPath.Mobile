import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

enum GrammarDataSource { remote, fixture }

@immutable
class GrammarEntry {
  const GrammarEntry({
    required this.routeKey,
    required this.remoteId,
    required this.title,
    required this.structure,
    required this.level,
    required this.source,
    this.explanation,
    this.exampleSentence,
    this.enrichment,
  });

  final String routeKey;
  final int? remoteId;
  final String title;
  final String structure;
  final String? explanation;
  final String? exampleSentence;
  final JlptLevel level;
  final GrammarDataSource source;

  /// Presentation-only content for the isolated local fixture repository.
  /// Remote API mapping never populates this field.
  final GrammarEnrichment? enrichment;
}

@immutable
class GrammarEnrichment {
  const GrammarEnrichment({
    this.examples = const <GrammarExample>[],
    this.usageNotes = const <String>[],
    this.cautions = const <String>[],
    this.related = const <RelatedGrammar>[],
  });

  final List<GrammarExample> examples;
  final List<String> usageNotes;
  final List<String> cautions;
  final List<RelatedGrammar> related;
}

@immutable
class GrammarExample {
  const GrammarExample({required this.sentence, this.translation});

  final String sentence;
  final String? translation;
}

@immutable
class RelatedGrammar {
  const RelatedGrammar({
    required this.routeKey,
    required this.title,
    required this.summary,
    required this.level,
  });

  final String routeKey;
  final String title;
  final String summary;
  final JlptLevel level;
}

@immutable
class GrammarQuery {
  const GrammarQuery({
    this.keyword = '',
    this.level,
    this.page = 1,
    this.pageSize = 20,
  });

  final String keyword;
  final JlptLevel? level;
  final int page;
  final int pageSize;
}

@immutable
class GrammarPage {
  const GrammarPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.source,
  });

  final List<GrammarEntry> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final GrammarDataSource source;

  bool get hasNextPage => page < totalPages;
}
