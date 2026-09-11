// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VocabularyListsTable extends VocabularyLists
    with TableInfo<$VocabularyListsTable, VocabularyList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isDefault, updatedAt, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $VocabularyListsTable createAlias(String alias) {
    return $VocabularyListsTable(attachedDatabase, alias);
  }
}

class VocabularyList extends DataClass implements Insertable<VocabularyList> {
  final String id;
  final String name;
  final bool isDefault;
  final DateTime updatedAt;
  final bool dirty;
  const VocabularyList({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<bool>(isDefault);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  VocabularyListsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyListsCompanion(
      id: Value(id),
      name: Value(name),
      isDefault: Value(isDefault),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory VocabularyList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  VocabularyList copyWith({
    String? id,
    String? name,
    bool? isDefault,
    DateTime? updatedAt,
    bool? dirty,
  }) => VocabularyList(
    id: id ?? this.id,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  VocabularyList copyWithCompanion(VocabularyListsCompanion data) {
    return VocabularyList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault, updatedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyList &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class VocabularyListsCompanion extends UpdateCompanion<VocabularyList> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isDefault;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const VocabularyListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyListsCompanion.insert({
    required String id,
    required String name,
    this.isDefault = const Value.absent(),
    required DateTime updatedAt,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<VocabularyList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isDefault,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isDefault,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return VocabularyListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalVocabularyEntriesTable extends PersonalVocabularyEntries
    with TableInfo<$PersonalVocabularyEntriesTable, PersonalVocabularyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalVocabularyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceVocabularyIdMeta =
      const VerificationMeta('sourceVocabularyId');
  @override
  late final GeneratedColumn<String> sourceVocabularyId =
      GeneratedColumn<String>(
        'source_vocabulary_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_lists (id)',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jlptLevelMeta = const VerificationMeta(
    'jlptLevel',
  );
  @override
  late final GeneratedColumn<String> jlptLevel = GeneratedColumn<String>(
    'jlpt_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceVocabularyId,
    listId,
    word,
    reading,
    meaning,
    jlptLevel,
    exampleSentence,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
    updatedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_vocabulary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalVocabularyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_vocabulary_id')) {
      context.handle(
        _sourceVocabularyIdMeta,
        sourceVocabularyId.isAcceptableOrUnknown(
          data['source_vocabulary_id']!,
          _sourceVocabularyIdMeta,
        ),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('jlpt_level')) {
      context.handle(
        _jlptLevelMeta,
        jlptLevel.isAcceptableOrUnknown(data['jlpt_level']!, _jlptLevelMeta),
      );
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalVocabularyEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalVocabularyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceVocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_vocabulary_id'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      ),
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      jlptLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jlpt_level'],
      ),
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      ),
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $PersonalVocabularyEntriesTable createAlias(String alias) {
    return $PersonalVocabularyEntriesTable(attachedDatabase, alias);
  }
}

class PersonalVocabularyEntry extends DataClass
    implements Insertable<PersonalVocabularyEntry> {
  final String id;
  final String? sourceVocabularyId;
  final String? listId;
  final String word;
  final String? reading;
  final String meaning;
  final String? jlptLevel;
  final String? exampleSentence;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime updatedAt;
  final bool dirty;
  const PersonalVocabularyEntry({
    required this.id,
    this.sourceVocabularyId,
    this.listId,
    required this.word,
    this.reading,
    required this.meaning,
    this.jlptLevel,
    this.exampleSentence,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    this.nextReviewAt,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sourceVocabularyId != null) {
      map['source_vocabulary_id'] = Variable<String>(sourceVocabularyId);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || reading != null) {
      map['reading'] = Variable<String>(reading);
    }
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || jlptLevel != null) {
      map['jlpt_level'] = Variable<String>(jlptLevel);
    }
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  PersonalVocabularyEntriesCompanion toCompanion(bool nullToAbsent) {
    return PersonalVocabularyEntriesCompanion(
      id: Value(id),
      sourceVocabularyId: sourceVocabularyId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceVocabularyId),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      word: Value(word),
      reading: reading == null && nullToAbsent
          ? const Value.absent()
          : Value(reading),
      meaning: Value(meaning),
      jlptLevel: jlptLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(jlptLevel),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory PersonalVocabularyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalVocabularyEntry(
      id: serializer.fromJson<String>(json['id']),
      sourceVocabularyId: serializer.fromJson<String?>(
        json['sourceVocabularyId'],
      ),
      listId: serializer.fromJson<String?>(json['listId']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String?>(json['reading']),
      meaning: serializer.fromJson<String>(json['meaning']),
      jlptLevel: serializer.fromJson<String?>(json['jlptLevel']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceVocabularyId': serializer.toJson<String?>(sourceVocabularyId),
      'listId': serializer.toJson<String?>(listId),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String?>(reading),
      'meaning': serializer.toJson<String>(meaning),
      'jlptLevel': serializer.toJson<String?>(jlptLevel),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  PersonalVocabularyEntry copyWith({
    String? id,
    Value<String?> sourceVocabularyId = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    String? word,
    Value<String?> reading = const Value.absent(),
    String? meaning,
    Value<String?> jlptLevel = const Value.absent(),
    Value<String?> exampleSentence = const Value.absent(),
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    Value<DateTime?> nextReviewAt = const Value.absent(),
    DateTime? updatedAt,
    bool? dirty,
  }) => PersonalVocabularyEntry(
    id: id ?? this.id,
    sourceVocabularyId: sourceVocabularyId.present
        ? sourceVocabularyId.value
        : this.sourceVocabularyId,
    listId: listId.present ? listId.value : this.listId,
    word: word ?? this.word,
    reading: reading.present ? reading.value : this.reading,
    meaning: meaning ?? this.meaning,
    jlptLevel: jlptLevel.present ? jlptLevel.value : this.jlptLevel,
    exampleSentence: exampleSentence.present
        ? exampleSentence.value
        : this.exampleSentence,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  PersonalVocabularyEntry copyWithCompanion(
    PersonalVocabularyEntriesCompanion data,
  ) {
    return PersonalVocabularyEntry(
      id: data.id.present ? data.id.value : this.id,
      sourceVocabularyId: data.sourceVocabularyId.present
          ? data.sourceVocabularyId.value
          : this.sourceVocabularyId,
      listId: data.listId.present ? data.listId.value : this.listId,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      jlptLevel: data.jlptLevel.present ? data.jlptLevel.value : this.jlptLevel,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalVocabularyEntry(')
          ..write('id: $id, ')
          ..write('sourceVocabularyId: $sourceVocabularyId, ')
          ..write('listId: $listId, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning, ')
          ..write('jlptLevel: $jlptLevel, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceVocabularyId,
    listId,
    word,
    reading,
    meaning,
    jlptLevel,
    exampleSentence,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
    updatedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalVocabularyEntry &&
          other.id == this.id &&
          other.sourceVocabularyId == this.sourceVocabularyId &&
          other.listId == this.listId &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.meaning == this.meaning &&
          other.jlptLevel == this.jlptLevel &&
          other.exampleSentence == this.exampleSentence &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.nextReviewAt == this.nextReviewAt &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class PersonalVocabularyEntriesCompanion
    extends UpdateCompanion<PersonalVocabularyEntry> {
  final Value<String> id;
  final Value<String?> sourceVocabularyId;
  final Value<String?> listId;
  final Value<String> word;
  final Value<String?> reading;
  final Value<String> meaning;
  final Value<String?> jlptLevel;
  final Value<String?> exampleSentence;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const PersonalVocabularyEntriesCompanion({
    this.id = const Value.absent(),
    this.sourceVocabularyId = const Value.absent(),
    this.listId = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.meaning = const Value.absent(),
    this.jlptLevel = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalVocabularyEntriesCompanion.insert({
    required String id,
    this.sourceVocabularyId = const Value.absent(),
    this.listId = const Value.absent(),
    required String word,
    this.reading = const Value.absent(),
    required String meaning,
    this.jlptLevel = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    required DateTime updatedAt,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       word = Value(word),
       meaning = Value(meaning),
       updatedAt = Value(updatedAt);
  static Insertable<PersonalVocabularyEntry> custom({
    Expression<String>? id,
    Expression<String>? sourceVocabularyId,
    Expression<String>? listId,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? meaning,
    Expression<String>? jlptLevel,
    Expression<String>? exampleSentence,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceVocabularyId != null)
        'source_vocabulary_id': sourceVocabularyId,
      if (listId != null) 'list_id': listId,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (meaning != null) 'meaning': meaning,
      if (jlptLevel != null) 'jlpt_level': jlptLevel,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalVocabularyEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? sourceVocabularyId,
    Value<String?>? listId,
    Value<String>? word,
    Value<String?>? reading,
    Value<String>? meaning,
    Value<String?>? jlptLevel,
    Value<String?>? exampleSentence,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime?>? nextReviewAt,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return PersonalVocabularyEntriesCompanion(
      id: id ?? this.id,
      sourceVocabularyId: sourceVocabularyId ?? this.sourceVocabularyId,
      listId: listId ?? this.listId,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      meaning: meaning ?? this.meaning,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceVocabularyId.present) {
      map['source_vocabulary_id'] = Variable<String>(sourceVocabularyId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (jlptLevel.present) {
      map['jlpt_level'] = Variable<String>(jlptLevel.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalVocabularyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourceVocabularyId: $sourceVocabularyId, ')
          ..write('listId: $listId, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning, ')
          ..write('jlptLevel: $jlptLevel, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewQueueItemsTable extends ReviewQueueItems
    with TableInfo<$ReviewQueueItemsTable, ReviewQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personal_vocabulary_entries (id)',
    ),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vocabularyId,
    dueAt,
    serverVersion,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_version'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ReviewQueueItemsTable createAlias(String alias) {
    return $ReviewQueueItemsTable(attachedDatabase, alias);
  }
}

class ReviewQueueItem extends DataClass implements Insertable<ReviewQueueItem> {
  final String id;
  final String vocabularyId;
  final DateTime dueAt;
  final String? serverVersion;
  final bool dirty;
  const ReviewQueueItem({
    required this.id,
    required this.vocabularyId,
    required this.dueAt,
    this.serverVersion,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ReviewQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return ReviewQueueItemsCompanion(
      id: Value(id),
      vocabularyId: Value(vocabularyId),
      dueAt: Value(dueAt),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      dirty: Value(dirty),
    );
  }

  factory ReviewQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewQueueItem(
      id: serializer.fromJson<String>(json['id']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ReviewQueueItem copyWith({
    String? id,
    String? vocabularyId,
    DateTime? dueAt,
    Value<String?> serverVersion = const Value.absent(),
    bool? dirty,
  }) => ReviewQueueItem(
    id: id ?? this.id,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    dueAt: dueAt ?? this.dueAt,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    dirty: dirty ?? this.dirty,
  );
  ReviewQueueItem copyWithCompanion(ReviewQueueItemsCompanion data) {
    return ReviewQueueItem(
      id: data.id.present ? data.id.value : this.id,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewQueueItem(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('dueAt: $dueAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vocabularyId, dueAt, serverVersion, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewQueueItem &&
          other.id == this.id &&
          other.vocabularyId == this.vocabularyId &&
          other.dueAt == this.dueAt &&
          other.serverVersion == this.serverVersion &&
          other.dirty == this.dirty);
}

class ReviewQueueItemsCompanion extends UpdateCompanion<ReviewQueueItem> {
  final Value<String> id;
  final Value<String> vocabularyId;
  final Value<DateTime> dueAt;
  final Value<String?> serverVersion;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ReviewQueueItemsCompanion({
    this.id = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewQueueItemsCompanion.insert({
    required String id,
    required String vocabularyId,
    required DateTime dueAt,
    this.serverVersion = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vocabularyId = Value(vocabularyId),
       dueAt = Value(dueAt);
  static Insertable<ReviewQueueItem> custom({
    Expression<String>? id,
    Expression<String>? vocabularyId,
    Expression<DateTime>? dueAt,
    Expression<String>? serverVersion,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (dueAt != null) 'due_at': dueAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewQueueItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? vocabularyId,
    Value<DateTime>? dueAt,
    Value<String?>? serverVersion,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ReviewQueueItemsCompanion(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      dueAt: dueAt ?? this.dueAt,
      serverVersion: serverVersion ?? this.serverVersion,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('dueAt: $dueAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabularyIdMeta = const VerificationMeta(
    'vocabularyId',
  );
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
    'vocabulary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personal_vocabulary_entries (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vocabularyId,
    rating,
    reviewedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
        _vocabularyIdMeta,
        vocabularyId.isAcceptableOrUnknown(
          data['vocabulary_id']!,
          _vocabularyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vocabularyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocabulary_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final String id;
  final String vocabularyId;
  final int rating;
  final DateTime reviewedAt;
  final bool synced;
  const ReviewLog({
    required this.id,
    required this.vocabularyId,
    required this.rating,
    required this.reviewedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      vocabularyId: Value(vocabularyId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      synced: Value(synced),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<String>(json['id']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ReviewLog copyWith({
    String? id,
    String? vocabularyId,
    int? rating,
    DateTime? reviewedAt,
    bool? synced,
  }) => ReviewLog(
    id: id ?? this.id,
    vocabularyId: vocabularyId ?? this.vocabularyId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    synced: synced ?? this.synced,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vocabularyId, rating, reviewedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.vocabularyId == this.vocabularyId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.synced == this.synced);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<String> id;
  final Value<String> vocabularyId;
  final Value<int> rating;
  final Value<DateTime> reviewedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String vocabularyId,
    required int rating,
    required DateTime reviewedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vocabularyId = Value(vocabularyId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLog> custom({
    Expression<String>? id,
    Expression<String>? vocabularyId,
    Expression<int>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? vocabularyId,
    Value<int>? rating,
    Value<DateTime>? reviewedAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOperationsTable extends PendingSyncOperations
    with TableInfo<$PendingSyncOperationsTable, PendingSyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $PendingSyncOperationsTable createAlias(String alias) {
    return $PendingSyncOperationsTable(attachedDatabase, alias);
  }
}

class PendingSyncOperation extends DataClass
    implements Insertable<PendingSyncOperation> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  const PendingSyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  PendingSyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOperationsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
    );
  }

  factory PendingSyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOperation(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  PendingSyncOperation copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    DateTime? createdAt,
    int? retryCount,
  }) => PendingSyncOperation(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
  );
  PendingSyncOperation copyWithCompanion(PendingSyncOperationsCompanion data) {
    return PendingSyncOperation(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperation(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOperation &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount);
}

class PendingSyncOperationsCompanion
    extends UpdateCompanion<PendingSyncOperation> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  const PendingSyncOperationsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  PendingSyncOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingSyncOperation> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  PendingSyncOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
  }) {
    return PendingSyncOperationsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VocabularyListsTable vocabularyLists = $VocabularyListsTable(
    this,
  );
  late final $PersonalVocabularyEntriesTable personalVocabularyEntries =
      $PersonalVocabularyEntriesTable(this);
  late final $ReviewQueueItemsTable reviewQueueItems = $ReviewQueueItemsTable(
    this,
  );
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $PendingSyncOperationsTable pendingSyncOperations =
      $PendingSyncOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vocabularyLists,
    personalVocabularyEntries,
    reviewQueueItems,
    reviewLogs,
    pendingSyncOperations,
  ];
}

typedef $$VocabularyListsTableCreateCompanionBuilder =
    VocabularyListsCompanion Function({
      required String id,
      required String name,
      Value<bool> isDefault,
      required DateTime updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$VocabularyListsTableUpdateCompanionBuilder =
    VocabularyListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isDefault,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

final class $$VocabularyListsTableReferences
    extends
        BaseReferences<_$AppDatabase, $VocabularyListsTable, VocabularyList> {
  $$VocabularyListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PersonalVocabularyEntriesTable,
    List<PersonalVocabularyEntry>
  >
  _personalVocabularyEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.personalVocabularyEntries,
        aliasName: 'vocabulary_lists__id__personal_vocabulary_entries__list_id',
      );

  $$PersonalVocabularyEntriesTableProcessedTableManager
  get personalVocabularyEntriesRefs {
    final manager = $$PersonalVocabularyEntriesTableTableManager(
      $_db,
      $_db.personalVocabularyEntries,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personalVocabularyEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VocabularyListsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personalVocabularyEntriesRefs(
    Expression<bool> Function($$PersonalVocabularyEntriesTableFilterComposer f)
    f,
  ) {
    final $$PersonalVocabularyEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.listId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableFilterComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VocabularyListsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularyListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  Expression<T> personalVocabularyEntriesRefs<T extends Object>(
    Expression<T> Function($$PersonalVocabularyEntriesTableAnnotationComposer a)
    f,
  ) {
    final $$PersonalVocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.listId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VocabularyListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyListsTable,
          VocabularyList,
          $$VocabularyListsTableFilterComposer,
          $$VocabularyListsTableOrderingComposer,
          $$VocabularyListsTableAnnotationComposer,
          $$VocabularyListsTableCreateCompanionBuilder,
          $$VocabularyListsTableUpdateCompanionBuilder,
          (VocabularyList, $$VocabularyListsTableReferences),
          VocabularyList,
          PrefetchHooks Function({bool personalVocabularyEntriesRefs})
        > {
  $$VocabularyListsTableTableManager(
    _$AppDatabase db,
    $VocabularyListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyListsCompanion(
                id: id,
                name: name,
                isDefault: isDefault,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isDefault = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyListsCompanion.insert(
                id: id,
                name: name,
                isDefault: isDefault,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VocabularyListsTable, VocabularyList>(table),
                  $$VocabularyListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personalVocabularyEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (personalVocabularyEntriesRefs) db.personalVocabularyEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (personalVocabularyEntriesRefs)
                    await $_getPrefetchedData<
                      VocabularyList,
                      $VocabularyListsTable,
                      PersonalVocabularyEntry
                    >(
                      currentTable: table,
                      referencedTable: $$VocabularyListsTableReferences
                          ._personalVocabularyEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VocabularyListsTableReferences(
                            db,
                            table,
                            p0,
                          ).personalVocabularyEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VocabularyListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyListsTable,
      VocabularyList,
      $$VocabularyListsTableFilterComposer,
      $$VocabularyListsTableOrderingComposer,
      $$VocabularyListsTableAnnotationComposer,
      $$VocabularyListsTableCreateCompanionBuilder,
      $$VocabularyListsTableUpdateCompanionBuilder,
      (VocabularyList, $$VocabularyListsTableReferences),
      VocabularyList,
      PrefetchHooks Function({bool personalVocabularyEntriesRefs})
    >;
typedef $$PersonalVocabularyEntriesTableCreateCompanionBuilder =
    PersonalVocabularyEntriesCompanion Function({
      required String id,
      Value<String?> sourceVocabularyId,
      Value<String?> listId,
      required String word,
      Value<String?> reading,
      required String meaning,
      Value<String?> jlptLevel,
      Value<String?> exampleSentence,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime?> nextReviewAt,
      required DateTime updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$PersonalVocabularyEntriesTableUpdateCompanionBuilder =
    PersonalVocabularyEntriesCompanion Function({
      Value<String> id,
      Value<String?> sourceVocabularyId,
      Value<String?> listId,
      Value<String> word,
      Value<String?> reading,
      Value<String> meaning,
      Value<String?> jlptLevel,
      Value<String?> exampleSentence,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime?> nextReviewAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

final class $$PersonalVocabularyEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PersonalVocabularyEntriesTable,
          PersonalVocabularyEntry
        > {
  $$PersonalVocabularyEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VocabularyListsTable _listIdTable(_$AppDatabase db) =>
      db.vocabularyLists.createAlias(
        'personal_vocabulary_entries__list_id__vocabulary_lists__id',
      );

  $$VocabularyListsTableProcessedTableManager? get listId {
    final $_column = $_itemColumn<String>('list_id');
    if ($_column == null) return null;
    final manager = $$VocabularyListsTableTableManager(
      $_db,
      $_db.vocabularyLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewQueueItemsTable, List<ReviewQueueItem>>
  _reviewQueueItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewQueueItems,
    aliasName:
        'personal_vocabulary_entries__id__review_queue_items__vocabulary_id',
  );

  $$ReviewQueueItemsTableProcessedTableManager get reviewQueueItemsRefs {
    final manager = $$ReviewQueueItemsTableTableManager(
      $_db,
      $_db.reviewQueueItems,
    ).filter((f) => f.vocabularyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reviewQueueItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: 'personal_vocabulary_entries__id__review_logs__vocabulary_id',
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.vocabularyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonalVocabularyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalVocabularyEntriesTable> {
  $$PersonalVocabularyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceVocabularyId => $composableBuilder(
    column: $table.sourceVocabularyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyListsTableFilterComposer get listId {
    final $$VocabularyListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.vocabularyLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyListsTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewQueueItemsRefs(
    Expression<bool> Function($$ReviewQueueItemsTableFilterComposer f) f,
  ) {
    final $$ReviewQueueItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewQueueItems,
      getReferencedColumn: (t) => t.vocabularyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewQueueItemsTableFilterComposer(
            $db: $db,
            $table: $db.reviewQueueItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.vocabularyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonalVocabularyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalVocabularyEntriesTable> {
  $$PersonalVocabularyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceVocabularyId => $composableBuilder(
    column: $table.sourceVocabularyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyListsTableOrderingComposer get listId {
    final $$VocabularyListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.vocabularyLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyListsTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalVocabularyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalVocabularyEntriesTable> {
  $$PersonalVocabularyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceVocabularyId => $composableBuilder(
    column: $table.sourceVocabularyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get jlptLevel =>
      $composableBuilder(column: $table.jlptLevel, builder: (column) => column);

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $$VocabularyListsTableAnnotationComposer get listId {
    final $$VocabularyListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.vocabularyLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyListsTableAnnotationComposer(
            $db: $db,
            $table: $db.vocabularyLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewQueueItemsRefs<T extends Object>(
    Expression<T> Function($$ReviewQueueItemsTableAnnotationComposer a) f,
  ) {
    final $$ReviewQueueItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewQueueItems,
      getReferencedColumn: (t) => t.vocabularyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewQueueItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewQueueItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.vocabularyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonalVocabularyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalVocabularyEntriesTable,
          PersonalVocabularyEntry,
          $$PersonalVocabularyEntriesTableFilterComposer,
          $$PersonalVocabularyEntriesTableOrderingComposer,
          $$PersonalVocabularyEntriesTableAnnotationComposer,
          $$PersonalVocabularyEntriesTableCreateCompanionBuilder,
          $$PersonalVocabularyEntriesTableUpdateCompanionBuilder,
          (PersonalVocabularyEntry, $$PersonalVocabularyEntriesTableReferences),
          PersonalVocabularyEntry,
          PrefetchHooks Function({
            bool listId,
            bool reviewQueueItemsRefs,
            bool reviewLogsRefs,
          })
        > {
  $$PersonalVocabularyEntriesTableTableManager(
    _$AppDatabase db,
    $PersonalVocabularyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalVocabularyEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PersonalVocabularyEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersonalVocabularyEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sourceVocabularyId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> reading = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> jlptLevel = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalVocabularyEntriesCompanion(
                id: id,
                sourceVocabularyId: sourceVocabularyId,
                listId: listId,
                word: word,
                reading: reading,
                meaning: meaning,
                jlptLevel: jlptLevel,
                exampleSentence: exampleSentence,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sourceVocabularyId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                required String word,
                Value<String?> reading = const Value.absent(),
                required String meaning,
                Value<String?> jlptLevel = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalVocabularyEntriesCompanion.insert(
                id: id,
                sourceVocabularyId: sourceVocabularyId,
                listId: listId,
                word: word,
                reading: reading,
                meaning: meaning,
                jlptLevel: jlptLevel,
                exampleSentence: exampleSentence,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                updatedAt: updatedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PersonalVocabularyEntriesTable,
                    PersonalVocabularyEntry
                  >(table),
                  $$PersonalVocabularyEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                listId = false,
                reviewQueueItemsRefs = false,
                reviewLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewQueueItemsRefs) db.reviewQueueItems,
                    if (reviewLogsRefs) db.reviewLogs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (listId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.listId,
                                    referencedTable:
                                        $$PersonalVocabularyEntriesTableReferences
                                            ._listIdTable(db),
                                    referencedColumn:
                                        $$PersonalVocabularyEntriesTableReferences
                                            ._listIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewQueueItemsRefs)
                        await $_getPrefetchedData<
                          PersonalVocabularyEntry,
                          $PersonalVocabularyEntriesTable,
                          ReviewQueueItem
                        >(
                          currentTable: table,
                          referencedTable:
                              $$PersonalVocabularyEntriesTableReferences
                                  ._reviewQueueItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonalVocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewQueueItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vocabularyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewLogsRefs)
                        await $_getPrefetchedData<
                          PersonalVocabularyEntry,
                          $PersonalVocabularyEntriesTable,
                          ReviewLog
                        >(
                          currentTable: table,
                          referencedTable:
                              $$PersonalVocabularyEntriesTableReferences
                                  ._reviewLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonalVocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vocabularyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PersonalVocabularyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalVocabularyEntriesTable,
      PersonalVocabularyEntry,
      $$PersonalVocabularyEntriesTableFilterComposer,
      $$PersonalVocabularyEntriesTableOrderingComposer,
      $$PersonalVocabularyEntriesTableAnnotationComposer,
      $$PersonalVocabularyEntriesTableCreateCompanionBuilder,
      $$PersonalVocabularyEntriesTableUpdateCompanionBuilder,
      (PersonalVocabularyEntry, $$PersonalVocabularyEntriesTableReferences),
      PersonalVocabularyEntry,
      PrefetchHooks Function({
        bool listId,
        bool reviewQueueItemsRefs,
        bool reviewLogsRefs,
      })
    >;
typedef $$ReviewQueueItemsTableCreateCompanionBuilder =
    ReviewQueueItemsCompanion Function({
      required String id,
      required String vocabularyId,
      required DateTime dueAt,
      Value<String?> serverVersion,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$ReviewQueueItemsTableUpdateCompanionBuilder =
    ReviewQueueItemsCompanion Function({
      Value<String> id,
      Value<String> vocabularyId,
      Value<DateTime> dueAt,
      Value<String?> serverVersion,
      Value<bool> dirty,
      Value<int> rowid,
    });

final class $$ReviewQueueItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReviewQueueItemsTable, ReviewQueueItem> {
  $$ReviewQueueItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonalVocabularyEntriesTable _vocabularyIdTable(_$AppDatabase db) =>
      db.personalVocabularyEntries.createAlias(
        'review_queue_items__vocabulary_id__personal_vocabulary_entries__id',
      );

  $$PersonalVocabularyEntriesTableProcessedTableManager get vocabularyId {
    final $_column = $_itemColumn<String>('vocabulary_id')!;

    final manager = $$PersonalVocabularyEntriesTableTableManager(
      $_db,
      $_db.personalVocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vocabularyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewQueueItemsTable> {
  $$ReviewQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonalVocabularyEntriesTableFilterComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableFilterComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewQueueItemsTable> {
  $$ReviewQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonalVocabularyEntriesTableOrderingComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewQueueItemsTable> {
  $$ReviewQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $$PersonalVocabularyEntriesTableAnnotationComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewQueueItemsTable,
          ReviewQueueItem,
          $$ReviewQueueItemsTableFilterComposer,
          $$ReviewQueueItemsTableOrderingComposer,
          $$ReviewQueueItemsTableAnnotationComposer,
          $$ReviewQueueItemsTableCreateCompanionBuilder,
          $$ReviewQueueItemsTableUpdateCompanionBuilder,
          (ReviewQueueItem, $$ReviewQueueItemsTableReferences),
          ReviewQueueItem,
          PrefetchHooks Function({bool vocabularyId})
        > {
  $$ReviewQueueItemsTableTableManager(
    _$AppDatabase db,
    $ReviewQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<String?> serverVersion = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewQueueItemsCompanion(
                id: id,
                vocabularyId: vocabularyId,
                dueAt: dueAt,
                serverVersion: serverVersion,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vocabularyId,
                required DateTime dueAt,
                Value<String?> serverVersion = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewQueueItemsCompanion.insert(
                id: id,
                vocabularyId: vocabularyId,
                dueAt: dueAt,
                serverVersion: serverVersion,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewQueueItemsTable, ReviewQueueItem>(table),
                  $$ReviewQueueItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vocabularyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vocabularyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vocabularyId,
                                referencedTable:
                                    $$ReviewQueueItemsTableReferences
                                        ._vocabularyIdTable(db),
                                referencedColumn:
                                    $$ReviewQueueItemsTableReferences
                                        ._vocabularyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewQueueItemsTable,
      ReviewQueueItem,
      $$ReviewQueueItemsTableFilterComposer,
      $$ReviewQueueItemsTableOrderingComposer,
      $$ReviewQueueItemsTableAnnotationComposer,
      $$ReviewQueueItemsTableCreateCompanionBuilder,
      $$ReviewQueueItemsTableUpdateCompanionBuilder,
      (ReviewQueueItem, $$ReviewQueueItemsTableReferences),
      ReviewQueueItem,
      PrefetchHooks Function({bool vocabularyId})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      required String id,
      required String vocabularyId,
      required int rating,
      required DateTime reviewedAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<String> id,
      Value<String> vocabularyId,
      Value<int> rating,
      Value<DateTime> reviewedAt,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PersonalVocabularyEntriesTable _vocabularyIdTable(_$AppDatabase db) =>
      db.personalVocabularyEntries.createAlias(
        'review_logs__vocabulary_id__personal_vocabulary_entries__id',
      );

  $$PersonalVocabularyEntriesTableProcessedTableManager get vocabularyId {
    final $_column = $_itemColumn<String>('vocabulary_id')!;

    final manager = $$PersonalVocabularyEntriesTableTableManager(
      $_db,
      $_db.personalVocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vocabularyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonalVocabularyEntriesTableFilterComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableFilterComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonalVocabularyEntriesTableOrderingComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  $$PersonalVocabularyEntriesTableAnnotationComposer get vocabularyId {
    final $$PersonalVocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.vocabularyId,
          referencedTable: $db.personalVocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonalVocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.personalVocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool vocabularyId})
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vocabularyId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                vocabularyId: vocabularyId,
                rating: rating,
                reviewedAt: reviewedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vocabularyId,
                required int rating,
                required DateTime reviewedAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                vocabularyId: vocabularyId,
                rating: rating,
                reviewedAt: reviewedAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogsTable, ReviewLog>(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vocabularyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vocabularyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vocabularyId,
                                referencedTable: $$ReviewLogsTableReferences
                                    ._vocabularyIdTable(db),
                                referencedColumn: $$ReviewLogsTableReferences
                                    ._vocabularyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool vocabularyId})
    >;
typedef $$PendingSyncOperationsTableCreateCompanionBuilder =
    PendingSyncOperationsCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String operation,
      required String payloadJson,
      required DateTime createdAt,
      Value<int> retryCount,
    });
typedef $$PendingSyncOperationsTableUpdateCompanionBuilder =
    PendingSyncOperationsCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
    });

class $$PendingSyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$PendingSyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSyncOperationsTable,
          PendingSyncOperation,
          $$PendingSyncOperationsTableFilterComposer,
          $$PendingSyncOperationsTableOrderingComposer,
          $$PendingSyncOperationsTableAnnotationComposer,
          $$PendingSyncOperationsTableCreateCompanionBuilder,
          $$PendingSyncOperationsTableUpdateCompanionBuilder,
          (
            PendingSyncOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingSyncOperationsTable,
              PendingSyncOperation
            >,
          ),
          PendingSyncOperation,
          PrefetchHooks Function()
        > {
  $$PendingSyncOperationsTableTableManager(
    _$AppDatabase db,
    $PendingSyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncOperationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingSyncOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingSyncOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => PendingSyncOperationsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String operation,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
              }) => PendingSyncOperationsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PendingSyncOperationsTable,
                    PendingSyncOperation
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingSyncOperationsTable,
                    PendingSyncOperation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSyncOperationsTable,
      PendingSyncOperation,
      $$PendingSyncOperationsTableFilterComposer,
      $$PendingSyncOperationsTableOrderingComposer,
      $$PendingSyncOperationsTableAnnotationComposer,
      $$PendingSyncOperationsTableCreateCompanionBuilder,
      $$PendingSyncOperationsTableUpdateCompanionBuilder,
      (
        PendingSyncOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingSyncOperationsTable,
          PendingSyncOperation
        >,
      ),
      PendingSyncOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VocabularyListsTableTableManager get vocabularyLists =>
      $$VocabularyListsTableTableManager(_db, _db.vocabularyLists);
  $$PersonalVocabularyEntriesTableTableManager get personalVocabularyEntries =>
      $$PersonalVocabularyEntriesTableTableManager(
        _db,
        _db.personalVocabularyEntries,
      );
  $$ReviewQueueItemsTableTableManager get reviewQueueItems =>
      $$ReviewQueueItemsTableTableManager(_db, _db.reviewQueueItems);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$PendingSyncOperationsTableTableManager get pendingSyncOperations =>
      $$PendingSyncOperationsTableTableManager(_db, _db.pendingSyncOperations);
}
