import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

enum KanjiDataSource { remote, fixture }

@immutable
class KanjiEntry {
  const KanjiEntry({
    required this.routeKey,
    required this.remoteId,
    required this.character,
    required this.meaning,
    required this.strokeCount,
    required this.level,
    required this.source,
    this.onYomi,
    this.kunYomi,
    this.sinoVietnamese,
    this.strokeOrderUrl,
    this.audioUrl,
    this.isSaved,
    this.enrichment,
  });

  final String routeKey;
  final int? remoteId;
  final String character;
  final String meaning;
  final String? onYomi;
  final String? kunYomi;
  final String? sinoVietnamese;
  final int strokeCount;
  final Uri? strokeOrderUrl;
  final Uri? audioUrl;
  final JlptLevel level;
  final KanjiDataSource source;

  /// `null` means the API does not expose saved state for this bank entry.
  final bool? isSaved;

  /// Stitch-only presentation data. Remote DTOs never populate this field.
  final KanjiEnrichment? enrichment;

  KanjiEntry copyWith({bool? isSaved}) {
    return KanjiEntry(
      routeKey: routeKey,
      remoteId: remoteId,
      character: character,
      meaning: meaning,
      strokeCount: strokeCount,
      level: level,
      source: source,
      onYomi: onYomi,
      kunYomi: kunYomi,
      sinoVietnamese: sinoVietnamese,
      strokeOrderUrl: strokeOrderUrl,
      audioUrl: audioUrl,
      isSaved: isSaved ?? this.isSaved,
      enrichment: enrichment,
    );
  }
}

@immutable
class KanjiEnrichment {
  const KanjiEnrichment({
    this.radical,
    this.mnemonic,
    this.compounds = const <KanjiCompound>[],
    this.example,
    this.strokeSteps = const <KanjiStrokeStep>[],
    this.strokeRules = const <String>[],
  });

  final String? radical;
  final String? mnemonic;
  final List<KanjiCompound> compounds;
  final KanjiExample? example;
  final List<KanjiStrokeStep> strokeSteps;
  final List<String> strokeRules;
}

@immutable
class KanjiCompound {
  const KanjiCompound({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  final String word;
  final String reading;
  final String meaning;
}

@immutable
class KanjiExample {
  const KanjiExample({required this.sentence, required this.translation});

  final String sentence;
  final String translation;
}

@immutable
class KanjiStrokeStep {
  const KanjiStrokeStep({required this.number, required this.preview});

  final int number;
  final String preview;
}

@immutable
class KanjiQuery {
  const KanjiQuery({
    this.keyword = '',
    this.level,
    this.page = 1,
    this.pageSize = 20,
    this.minStrokeCount,
    this.maxStrokeCount,
  });

  final String keyword;
  final JlptLevelCatalogItem? level;
  final int page;
  final int pageSize;
  final int? minStrokeCount;
  final int? maxStrokeCount;
}

@immutable
class KanjiPage {
  const KanjiPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.source,
  });

  final List<KanjiEntry> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final KanjiDataSource source;

  bool get hasNextPage => page < totalPages;
}

@immutable
class KanjiNotebookList {
  const KanjiNotebookList({
    required this.id,
    required this.name,
    required this.entryCount,
    this.description,
  });

  final int id;
  final String name;
  final int entryCount;
  final String? description;
}

@immutable
class KanjiBookmark {
  const KanjiBookmark({
    required this.noteEntryId,
    required this.listId,
    required this.listName,
  });

  final int? noteEntryId;
  final int listId;
  final String listName;
}
