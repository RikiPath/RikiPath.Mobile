import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class VocabularyLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PersonalVocabularyEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sourceVocabularyId => text().nullable()();
  TextColumn get listId => text().nullable().references(VocabularyLists, #id)();
  TextColumn get word => text()();
  TextColumn get reading => text().nullable()();
  TextColumn get meaning => text()();
  TextColumn get jlptLevel => text().nullable()();
  TextColumn get exampleSentence => text().nullable()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get vocabularyId => text().references(PersonalVocabularyEntries, #id)();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get serverVersion => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get vocabularyId => text().references(PersonalVocabularyEntries, #id)();
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
  int get schemaVersion => 1;

  Stream<List<PersonalVocabularyEntry>> watchDueVocabulary(DateTime now) {
    return (select(personalVocabularyEntries)
          ..where(
            (row) => row.nextReviewAt.isSmallerOrEqualValue(now),
          )
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
