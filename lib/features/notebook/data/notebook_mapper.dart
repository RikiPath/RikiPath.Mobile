import 'package:rikipath_mobile/features/notebook/data/notebook_dtos.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

abstract final class NotebookMapper {
  static NotebookCollection collectionFromRemote(NotebookCollectionDto dto) {
    return NotebookCollection(
      routeKey: 'remote-list-${dto.id}',
      remoteId: dto.id,
      name: dto.name,
      description: _nonEmpty(dto.description),
      entryCount: dto.entryCount,
      createdAt: dto.createdAt,
      source: NotebookDataSource.remote,
    );
  }

  static NotebookEntry entryFromRemote(NotebookEntryDto dto) {
    final contentType = _contentType(dto.contentType);
    return NotebookEntry(
      key: NotebookEntryKey.live(
        contentType: contentType,
        noteEntryId: dto.noteEntryId,
      ),
      remoteNoteEntryId: dto.noteEntryId,
      reviewCardId: dto.reviewCardId,
      contentType: contentType,
      term: dto.term,
      reading: _nonEmpty(dto.reading),
      meaning: dto.meaning,
      note: _nonEmpty(dto.note),
      addedAt: dto.addedAt,
      // The backend response omits VocabularyEntryId, so no detail route can
      // be derived safely here.
      vocabularyRouteKey: null,
    );
  }

  static NotebookContentType _contentType(String value) {
    return switch (value.trim().toLowerCase()) {
      'vocabulary' => NotebookContentType.vocabulary,
      'kanji' => NotebookContentType.kanji,
      'grammar' => NotebookContentType.grammar,
      'manual' => NotebookContentType.manual,
      _ => NotebookContentType.unknown,
    };
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
