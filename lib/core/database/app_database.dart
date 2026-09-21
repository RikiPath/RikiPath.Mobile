import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class VocabularyLists extends Table {
  TextColumn get id => text()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  IntColumn get entryCount => integer().withDefault(const Constant(0))();
  BoolColumn get entriesCached =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PersonalVocabularyEntries extends Table {
  TextColumn get id => text()();
  IntColumn get remoteNoteEntryId => integer().nullable()();
  IntColumn get reviewItemId => integer().nullable()();
  TextColumn get sourceVocabularyId => text().nullable()();
  TextColumn get listId => text().nullable().references(VocabularyLists, #id)();
  TextColumn get contentType =>
      text().withDefault(const Constant('vocabulary'))();
  TextColumn get source => text().withDefault(const Constant('local'))();
  TextColumn get word => text()();
  TextColumn get reading => text().nullable()();
  TextColumn get meaning => text()();
  TextColumn get note => text().nullable()();
  TextColumn get jlptLevel => text().nullable()();
  TextColumn get exampleSentence => text().nullable()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get addedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get vocabularyId =>
      text().references(PersonalVocabularyEntries, #id)();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get serverVersion => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get vocabularyId =>
      text().references(PersonalVocabularyEntries, #id)();
  IntColumn get rating => integer()(); // 0 Again, 1 Hard, 2 Good, 3 Easy
  DateTimeColumn get reviewedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create, update, delete, review
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: [
    VocabularyLists,
    PersonalVocabularyEntries,
    ReviewQueueItems,
    ReviewLogs,
    PendingSyncOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'rikipath_mobile'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(vocabularyLists, vocabularyLists.remoteId);
        await migrator.addColumn(vocabularyLists, vocabularyLists.description);
        await migrator.addColumn(vocabularyLists, vocabularyLists.source);
        await migrator.addColumn(vocabularyLists, vocabularyLists.createdAt);
        await migrator.addColumn(vocabularyLists, vocabularyLists.entryCount);
        await migrator.addColumn(
          vocabularyLists,
          vocabularyLists.entriesCached,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.remoteNoteEntryId,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.reviewItemId,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.contentType,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.source,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.note,
        );
        await migrator.addColumn(
          personalVocabularyEntries,
          personalVocabularyEntries.addedAt,
        );
      }
    },
  );

  Stream<List<PersonalVocabularyEntry>> watchDueVocabulary(DateTime now) {
    return (select(personalVocabularyEntries)
          ..where((row) => row.nextReviewAt.isSmallerOrEqualValue(now))
          ..orderBy([(row) => OrderingTerm.asc(row.nextReviewAt)]))
        .watch();
  }

  Future<void> upsertVocabulary(PersonalVocabularyEntriesCompanion entry) {
    return into(personalVocabularyEntries).insertOnConflictUpdate(entry);
  }

  Future<int> enqueueSync(PendingSyncOperationsCompanion operation) {
    return into(pendingSyncOperations).insert(operation);
  }
}
