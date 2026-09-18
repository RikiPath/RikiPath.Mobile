import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

enum VocabularyDataSource { remote, fixture }

@immutable
class VocabularyEntry {
  const VocabularyEntry({
    required this.routeKey,
    required this.remoteId,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.level,
    required this.source,
    this.partOfSpeech,
    this.exampleSentence,
    this.audioUrl,
    this.isSaved,
    this.enrichment,
  });

  final String routeKey;
  final int? remoteId;
  final String word;
  final String reading;
  final String meaning;
  final String? partOfSpeech;
  final String? exampleSentence;
  final Uri? audioUrl;
  final JlptLevel level;
  final VocabularyDataSource source;

  /// `null` means that the backend did not publish a reliable saved-state
  /// relationship for this bank entry.
  final bool? isSaved;
  final VocabularyEnrichment? enrichment;

  VocabularyEntry copyWith({bool? isSaved}) {
    return VocabularyEntry(
      routeKey: routeKey,
      remoteId: remoteId,
      word: word,
      reading: reading,
      meaning: meaning,
      level: level,
      source: source,
      partOfSpeech: partOfSpeech,
      exampleSentence: exampleSentence,
      audioUrl: audioUrl,
      isSaved: isSaved ?? this.isSaved,
      enrichment: enrichment,
    );
  }
}

@immutable
class VocabularyEnrichment {
  const VocabularyEnrichment({
    this.sinoVietnamese,
    this.definition,
    this.examples = const <VocabularyExample>[],
    this.collocations = const <VocabularyCollocation>[],
    this.nuance,
    this.kanji = const <VocabularyKanjiPart>[],
    this.relatedLessons = const <VocabularyRelatedLesson>[],
    this.frequencyLabel,
  });

  final String? sinoVietnamese;
  final String? definition;
  final List<VocabularyExample> examples;
  final List<VocabularyCollocation> collocations;
  final String? nuance;
  final List<VocabularyKanjiPart> kanji;
  final List<VocabularyRelatedLesson> relatedLessons;
  final String? frequencyLabel;
}

@immutable
class VocabularyExample {
  const VocabularyExample({required this.sentence, this.translation});

  final String sentence;
  final String? translation;
}

@immutable
class VocabularyCollocation {
  const VocabularyCollocation({required this.phrase, required this.meaning});

  final String phrase;
  final String meaning;
}

@immutable
class VocabularyKanjiPart {
  const VocabularyKanjiPart({
    required this.character,
    required this.sinoVietnamese,
    required this.meaning,
    required this.onReading,
  });

  final String character;
  final String sinoVietnamese;
  final String meaning;
  final String onReading;
}

@immutable
class VocabularyRelatedLesson {
  const VocabularyRelatedLesson({
    required this.routeId,
    required this.number,
    required this.title,
    required this.subtitle,
  });

  /// Local fixture lesson route key, never a claimed backend lesson ID.
  final String routeId;
  final int number;
  final String title;
  final String subtitle;
}

@immutable
class VocabularyQuery {
  const VocabularyQuery({
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
class VocabularyPage {
  const VocabularyPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.source,
  });

  final List<VocabularyEntry> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final VocabularyDataSource source;

  bool get hasNextPage => page < totalPages;
}
