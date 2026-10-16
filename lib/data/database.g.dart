// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorksTable extends Works with TableInfo<$WorksTable, Work> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta('wordCount');
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta('estMinutes');
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partLabelMeta = const VerificationMeta('partLabel');
  @override
  late final GeneratedColumn<String> partLabel = GeneratedColumn<String>(
    'part_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textMdMeta = const VerificationMeta('textMd');
  @override
  late final GeneratedColumn<String> textMd = GeneratedColumn<String>(
    'text_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta('sourceRef');
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightsNoteMeta = const VerificationMeta('rightsNote');
  @override
  late final GeneratedColumn<String> rightsNote = GeneratedColumn<String>(
    'rights_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pullQuoteMeta = const VerificationMeta('pullQuote');
  @override
  late final GeneratedColumn<String> pullQuote = GeneratedColumn<String>(
    'pull_quote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    author,
    year,
    wordCount,
    estMinutes,
    partLabel,
    textMd,
    imagePath,
    sourceRef,
    rightsNote,
    pullQuote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'works';
  @override
  VerificationContext validateIntegrity(Insertable<Work> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta, author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('year')) {
      context.handle(_yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(_wordCountMeta, wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta));
    } else if (isInserting) {
      context.missing(_wordCountMeta);
    }
    if (data.containsKey('est_minutes')) {
      context.handle(_estMinutesMeta, estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta));
    } else if (isInserting) {
      context.missing(_estMinutesMeta);
    }
    if (data.containsKey('part_label')) {
      context.handle(_partLabelMeta, partLabel.isAcceptableOrUnknown(data['part_label']!, _partLabelMeta));
    }
    if (data.containsKey('text_md')) {
      context.handle(_textMdMeta, textMd.isAcceptableOrUnknown(data['text_md']!, _textMdMeta));
    } else if (isInserting) {
      context.missing(_textMdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta, imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('source_ref')) {
      context.handle(_sourceRefMeta, sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta));
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    if (data.containsKey('rights_note')) {
      context.handle(_rightsNoteMeta, rightsNote.isAcceptableOrUnknown(data['rights_note']!, _rightsNoteMeta));
    } else if (isInserting) {
      context.missing(_rightsNoteMeta);
    }
    if (data.containsKey('pull_quote')) {
      context.handle(_pullQuoteMeta, pullQuote.isAcceptableOrUnknown(data['pull_quote']!, _pullQuoteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Work map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Work(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}author'])!,
      year: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      wordCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}word_count'])!,
      estMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}est_minutes'])!,
      partLabel: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}part_label']),
      textMd: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}text_md'])!,
      imagePath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      sourceRef: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_ref'])!,
      rightsNote: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}rights_note'])!,
      pullQuote: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pull_quote']),
    );
  }

  @override
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }
}

class Work extends DataClass implements Insertable<Work> {
  final String id;
  final String type;
  final String title;
  final String author;
  final int year;
  final int wordCount;
  final int estMinutes;
  final String? partLabel;
  final String textMd;
  final String? imagePath;
  final String sourceRef;
  final String rightsNote;
  final String? pullQuote;
  const Work({
    required this.id,
    required this.type,
    required this.title,
    required this.author,
    required this.year,
    required this.wordCount,
    required this.estMinutes,
    this.partLabel,
    required this.textMd,
    this.imagePath,
    required this.sourceRef,
    required this.rightsNote,
    this.pullQuote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['year'] = Variable<int>(year);
    map['word_count'] = Variable<int>(wordCount);
    map['est_minutes'] = Variable<int>(estMinutes);
    if (!nullToAbsent || partLabel != null) {
      map['part_label'] = Variable<String>(partLabel);
    }
    map['text_md'] = Variable<String>(textMd);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['source_ref'] = Variable<String>(sourceRef);
    map['rights_note'] = Variable<String>(rightsNote);
    if (!nullToAbsent || pullQuote != null) {
      map['pull_quote'] = Variable<String>(pullQuote);
    }
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      author: Value(author),
      year: Value(year),
      wordCount: Value(wordCount),
      estMinutes: Value(estMinutes),
      partLabel: partLabel == null && nullToAbsent ? const Value.absent() : Value(partLabel),
      textMd: Value(textMd),
      imagePath: imagePath == null && nullToAbsent ? const Value.absent() : Value(imagePath),
      sourceRef: Value(sourceRef),
      rightsNote: Value(rightsNote),
      pullQuote: pullQuote == null && nullToAbsent ? const Value.absent() : Value(pullQuote),
    );
  }

  factory Work.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Work(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      year: serializer.fromJson<int>(json['year']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      estMinutes: serializer.fromJson<int>(json['estMinutes']),
      partLabel: serializer.fromJson<String?>(json['partLabel']),
      textMd: serializer.fromJson<String>(json['textMd']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      rightsNote: serializer.fromJson<String>(json['rightsNote']),
      pullQuote: serializer.fromJson<String?>(json['pullQuote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'year': serializer.toJson<int>(year),
      'wordCount': serializer.toJson<int>(wordCount),
      'estMinutes': serializer.toJson<int>(estMinutes),
      'partLabel': serializer.toJson<String?>(partLabel),
      'textMd': serializer.toJson<String>(textMd),
      'imagePath': serializer.toJson<String?>(imagePath),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'rightsNote': serializer.toJson<String>(rightsNote),
      'pullQuote': serializer.toJson<String?>(pullQuote),
    };
  }

  Work copyWith({
    String? id,
    String? type,
    String? title,
    String? author,
    int? year,
    int? wordCount,
    int? estMinutes,
    Value<String?> partLabel = const Value.absent(),
    String? textMd,
    Value<String?> imagePath = const Value.absent(),
    String? sourceRef,
    String? rightsNote,
    Value<String?> pullQuote = const Value.absent(),
  }) => Work(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    author: author ?? this.author,
    year: year ?? this.year,
    wordCount: wordCount ?? this.wordCount,
    estMinutes: estMinutes ?? this.estMinutes,
    partLabel: partLabel.present ? partLabel.value : this.partLabel,
    textMd: textMd ?? this.textMd,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    sourceRef: sourceRef ?? this.sourceRef,
    rightsNote: rightsNote ?? this.rightsNote,
    pullQuote: pullQuote.present ? pullQuote.value : this.pullQuote,
  );
  Work copyWithCompanion(WorksCompanion data) {
    return Work(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      year: data.year.present ? data.year.value : this.year,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      estMinutes: data.estMinutes.present ? data.estMinutes.value : this.estMinutes,
      partLabel: data.partLabel.present ? data.partLabel.value : this.partLabel,
      textMd: data.textMd.present ? data.textMd.value : this.textMd,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      rightsNote: data.rightsNote.present ? data.rightsNote.value : this.rightsNote,
      pullQuote: data.pullQuote.present ? data.pullQuote.value : this.pullQuote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Work(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('year: $year, ')
          ..write('wordCount: $wordCount, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('partLabel: $partLabel, ')
          ..write('textMd: $textMd, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('rightsNote: $rightsNote, ')
          ..write('pullQuote: $pullQuote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    author,
    year,
    wordCount,
    estMinutes,
    partLabel,
    textMd,
    imagePath,
    sourceRef,
    rightsNote,
    pullQuote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Work &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.author == this.author &&
          other.year == this.year &&
          other.wordCount == this.wordCount &&
          other.estMinutes == this.estMinutes &&
          other.partLabel == this.partLabel &&
          other.textMd == this.textMd &&
          other.imagePath == this.imagePath &&
          other.sourceRef == this.sourceRef &&
          other.rightsNote == this.rightsNote &&
          other.pullQuote == this.pullQuote);
}

class WorksCompanion extends UpdateCompanion<Work> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> author;
  final Value<int> year;
  final Value<int> wordCount;
  final Value<int> estMinutes;
  final Value<String?> partLabel;
  final Value<String> textMd;
  final Value<String?> imagePath;
  final Value<String> sourceRef;
  final Value<String> rightsNote;
  final Value<String?> pullQuote;
  final Value<int> rowid;
  const WorksCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.year = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.partLabel = const Value.absent(),
    this.textMd = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.rightsNote = const Value.absent(),
    this.pullQuote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String id,
    required String type,
    required String title,
    required String author,
    required int year,
    required int wordCount,
    required int estMinutes,
    this.partLabel = const Value.absent(),
    required String textMd,
    this.imagePath = const Value.absent(),
    required String sourceRef,
    required String rightsNote,
    this.pullQuote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       author = Value(author),
       year = Value(year),
       wordCount = Value(wordCount),
       estMinutes = Value(estMinutes),
       textMd = Value(textMd),
       sourceRef = Value(sourceRef),
       rightsNote = Value(rightsNote);
  static Insertable<Work> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? author,
    Expression<int>? year,
    Expression<int>? wordCount,
    Expression<int>? estMinutes,
    Expression<String>? partLabel,
    Expression<String>? textMd,
    Expression<String>? imagePath,
    Expression<String>? sourceRef,
    Expression<String>? rightsNote,
    Expression<String>? pullQuote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (year != null) 'year': year,
      if (wordCount != null) 'word_count': wordCount,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (partLabel != null) 'part_label': partLabel,
      if (textMd != null) 'text_md': textMd,
      if (imagePath != null) 'image_path': imagePath,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (rightsNote != null) 'rights_note': rightsNote,
      if (pullQuote != null) 'pull_quote': pullQuote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? author,
    Value<int>? year,
    Value<int>? wordCount,
    Value<int>? estMinutes,
    Value<String?>? partLabel,
    Value<String>? textMd,
    Value<String?>? imagePath,
    Value<String>? sourceRef,
    Value<String>? rightsNote,
    Value<String?>? pullQuote,
    Value<int>? rowid,
  }) {
    return WorksCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      wordCount: wordCount ?? this.wordCount,
      estMinutes: estMinutes ?? this.estMinutes,
      partLabel: partLabel ?? this.partLabel,
      textMd: textMd ?? this.textMd,
      imagePath: imagePath ?? this.imagePath,
      sourceRef: sourceRef ?? this.sourceRef,
      rightsNote: rightsNote ?? this.rightsNote,
      pullQuote: pullQuote ?? this.pullQuote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (partLabel.present) {
      map['part_label'] = Variable<String>(partLabel.value);
    }
    if (textMd.present) {
      map['text_md'] = Variable<String>(textMd.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (rightsNote.present) {
      map['rights_note'] = Variable<String>(rightsNote.value);
    }
    if (pullQuote.present) {
      map['pull_quote'] = Variable<String>(pullQuote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('year: $year, ')
          ..write('wordCount: $wordCount, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('partLabel: $partLabel, ')
          ..write('textMd: $textMd, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('rightsNote: $rightsNote, ')
          ..write('pullQuote: $pullQuote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DaysTable extends Days with TableInfo<$DaysTable, Day> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayNumberMeta = const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<String> poemId = GeneratedColumn<String>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _essayIdMeta = const VerificationMeta('essayId');
  @override
  late final GeneratedColumn<String> essayId = GeneratedColumn<String>(
    'essay_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dayNumber, storyId, poemId, essayId, packId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'days';
  @override
  VerificationContext validateIntegrity(Insertable<Day> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta, dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta, storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('poem_id')) {
      context.handle(_poemIdMeta, poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta));
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('essay_id')) {
      context.handle(_essayIdMeta, essayId.isAcceptableOrUnknown(data['essay_id']!, _essayIdMeta));
    } else if (isInserting) {
      context.missing(_essayIdMeta);
    }
    if (data.containsKey('pack_id')) {
      context.handle(_packIdMeta, packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayNumber};
  @override
  Day map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Day(
      dayNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      storyId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}story_id'])!,
      poemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poem_id'])!,
      essayId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}essay_id'])!,
      packId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}pack_id'])!,
    );
  }

  @override
  $DaysTable createAlias(String alias) {
    return $DaysTable(attachedDatabase, alias);
  }
}

class Day extends DataClass implements Insertable<Day> {
  final int dayNumber;
  final String storyId;
  final String poemId;
  final String essayId;
  final int packId;
  const Day({
    required this.dayNumber,
    required this.storyId,
    required this.poemId,
    required this.essayId,
    required this.packId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_number'] = Variable<int>(dayNumber);
    map['story_id'] = Variable<String>(storyId);
    map['poem_id'] = Variable<String>(poemId);
    map['essay_id'] = Variable<String>(essayId);
    map['pack_id'] = Variable<int>(packId);
    return map;
  }

  DaysCompanion toCompanion(bool nullToAbsent) {
    return DaysCompanion(
      dayNumber: Value(dayNumber),
      storyId: Value(storyId),
      poemId: Value(poemId),
      essayId: Value(essayId),
      packId: Value(packId),
    );
  }

  factory Day.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Day(
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      storyId: serializer.fromJson<String>(json['storyId']),
      poemId: serializer.fromJson<String>(json['poemId']),
      essayId: serializer.fromJson<String>(json['essayId']),
      packId: serializer.fromJson<int>(json['packId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayNumber': serializer.toJson<int>(dayNumber),
      'storyId': serializer.toJson<String>(storyId),
      'poemId': serializer.toJson<String>(poemId),
      'essayId': serializer.toJson<String>(essayId),
      'packId': serializer.toJson<int>(packId),
    };
  }

  Day copyWith({int? dayNumber, String? storyId, String? poemId, String? essayId, int? packId}) => Day(
    dayNumber: dayNumber ?? this.dayNumber,
    storyId: storyId ?? this.storyId,
    poemId: poemId ?? this.poemId,
    essayId: essayId ?? this.essayId,
    packId: packId ?? this.packId,
  );
  Day copyWithCompanion(DaysCompanion data) {
    return Day(
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      essayId: data.essayId.present ? data.essayId.value : this.essayId,
      packId: data.packId.present ? data.packId.value : this.packId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Day(')
          ..write('dayNumber: $dayNumber, ')
          ..write('storyId: $storyId, ')
          ..write('poemId: $poemId, ')
          ..write('essayId: $essayId, ')
          ..write('packId: $packId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayNumber, storyId, poemId, essayId, packId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Day &&
          other.dayNumber == this.dayNumber &&
          other.storyId == this.storyId &&
          other.poemId == this.poemId &&
          other.essayId == this.essayId &&
          other.packId == this.packId);
}

class DaysCompanion extends UpdateCompanion<Day> {
  final Value<int> dayNumber;
  final Value<String> storyId;
  final Value<String> poemId;
  final Value<String> essayId;
  final Value<int> packId;
  const DaysCompanion({
    this.dayNumber = const Value.absent(),
    this.storyId = const Value.absent(),
    this.poemId = const Value.absent(),
    this.essayId = const Value.absent(),
    this.packId = const Value.absent(),
  });
  DaysCompanion.insert({
    this.dayNumber = const Value.absent(),
    required String storyId,
    required String poemId,
    required String essayId,
    required int packId,
  }) : storyId = Value(storyId),
       poemId = Value(poemId),
       essayId = Value(essayId),
       packId = Value(packId);
  static Insertable<Day> custom({
    Expression<int>? dayNumber,
    Expression<String>? storyId,
    Expression<String>? poemId,
    Expression<String>? essayId,
    Expression<int>? packId,
  }) {
    return RawValuesInsertable({
      if (dayNumber != null) 'day_number': dayNumber,
      if (storyId != null) 'story_id': storyId,
      if (poemId != null) 'poem_id': poemId,
      if (essayId != null) 'essay_id': essayId,
      if (packId != null) 'pack_id': packId,
    });
  }

  DaysCompanion copyWith({
    Value<int>? dayNumber,
    Value<String>? storyId,
    Value<String>? poemId,
    Value<String>? essayId,
    Value<int>? packId,
  }) {
    return DaysCompanion(
      dayNumber: dayNumber ?? this.dayNumber,
      storyId: storyId ?? this.storyId,
      poemId: poemId ?? this.poemId,
      essayId: essayId ?? this.essayId,
      packId: packId ?? this.packId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<String>(poemId.value);
    }
    if (essayId.present) {
      map['essay_id'] = Variable<String>(essayId.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaysCompanion(')
          ..write('dayNumber: $dayNumber, ')
          ..write('storyId: $storyId, ')
          ..write('poemId: $poemId, ')
          ..write('essayId: $essayId, ')
          ..write('packId: $packId')
          ..write(')'))
        .toString();
  }
}

class $ProgressTable extends Progress with TableInfo<$ProgressTable, ProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scrollPosMeta = const VerificationMeta('scrollPos');
  @override
  late final GeneratedColumn<double> scrollPos = GeneratedColumn<double>(
    'scroll_pos',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondsReadMeta = const VerificationMeta('secondsRead');
  @override
  late final GeneratedColumn<int> secondsRead = GeneratedColumn<int>(
    'seconds_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [workId, dayNumber, scrollPos, startedAt, completedAt, secondsRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress';
  @override
  VerificationContext validateIntegrity(Insertable<ProgressRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta, workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta, dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('scroll_pos')) {
      context.handle(_scrollPosMeta, scrollPos.isAcceptableOrUnknown(data['scroll_pos']!, _scrollPosMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('seconds_read')) {
      context.handle(_secondsReadMeta, secondsRead.isAcceptableOrUnknown(data['seconds_read']!, _secondsReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workId, dayNumber};
  @override
  ProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressRow(
      workId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}work_id'])!,
      dayNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      scrollPos: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}scroll_pos'])!,
      startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      secondsRead: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seconds_read'])!,
    );
  }

  @override
  $ProgressTable createAlias(String alias) {
    return $ProgressTable(attachedDatabase, alias);
  }
}

class ProgressRow extends DataClass implements Insertable<ProgressRow> {
  final String workId;
  final int dayNumber;
  final double scrollPos;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int secondsRead;
  const ProgressRow({
    required this.workId,
    required this.dayNumber,
    required this.scrollPos,
    required this.startedAt,
    this.completedAt,
    required this.secondsRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_id'] = Variable<String>(workId);
    map['day_number'] = Variable<int>(dayNumber);
    map['scroll_pos'] = Variable<double>(scrollPos);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['seconds_read'] = Variable<int>(secondsRead);
    return map;
  }

  ProgressCompanion toCompanion(bool nullToAbsent) {
    return ProgressCompanion(
      workId: Value(workId),
      dayNumber: Value(dayNumber),
      scrollPos: Value(scrollPos),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      secondsRead: Value(secondsRead),
    );
  }

  factory ProgressRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressRow(
      workId: serializer.fromJson<String>(json['workId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      scrollPos: serializer.fromJson<double>(json['scrollPos']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      secondsRead: serializer.fromJson<int>(json['secondsRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workId': serializer.toJson<String>(workId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'scrollPos': serializer.toJson<double>(scrollPos),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'secondsRead': serializer.toJson<int>(secondsRead),
    };
  }

  ProgressRow copyWith({
    String? workId,
    int? dayNumber,
    double? scrollPos,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? secondsRead,
  }) => ProgressRow(
    workId: workId ?? this.workId,
    dayNumber: dayNumber ?? this.dayNumber,
    scrollPos: scrollPos ?? this.scrollPos,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    secondsRead: secondsRead ?? this.secondsRead,
  );
  ProgressRow copyWithCompanion(ProgressCompanion data) {
    return ProgressRow(
      workId: data.workId.present ? data.workId.value : this.workId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      scrollPos: data.scrollPos.present ? data.scrollPos.value : this.scrollPos,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      secondsRead: data.secondsRead.present ? data.secondsRead.value : this.secondsRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRow(')
          ..write('workId: $workId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('scrollPos: $scrollPos, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('secondsRead: $secondsRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workId, dayNumber, scrollPos, startedAt, completedAt, secondsRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressRow &&
          other.workId == this.workId &&
          other.dayNumber == this.dayNumber &&
          other.scrollPos == this.scrollPos &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.secondsRead == this.secondsRead);
}

class ProgressCompanion extends UpdateCompanion<ProgressRow> {
  final Value<String> workId;
  final Value<int> dayNumber;
  final Value<double> scrollPos;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> secondsRead;
  final Value<int> rowid;
  const ProgressCompanion({
    this.workId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.scrollPos = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.secondsRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressCompanion.insert({
    required String workId,
    required int dayNumber,
    this.scrollPos = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.secondsRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workId = Value(workId),
       dayNumber = Value(dayNumber),
       startedAt = Value(startedAt);
  static Insertable<ProgressRow> custom({
    Expression<String>? workId,
    Expression<int>? dayNumber,
    Expression<double>? scrollPos,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? secondsRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workId != null) 'work_id': workId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (scrollPos != null) 'scroll_pos': scrollPos,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (secondsRead != null) 'seconds_read': secondsRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressCompanion copyWith({
    Value<String>? workId,
    Value<int>? dayNumber,
    Value<double>? scrollPos,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? secondsRead,
    Value<int>? rowid,
  }) {
    return ProgressCompanion(
      workId: workId ?? this.workId,
      dayNumber: dayNumber ?? this.dayNumber,
      scrollPos: scrollPos ?? this.scrollPos,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      secondsRead: secondsRead ?? this.secondsRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (scrollPos.present) {
      map['scroll_pos'] = Variable<double>(scrollPos.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (secondsRead.present) {
      map['seconds_read'] = Variable<int>(secondsRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressCompanion(')
          ..write('workId: $workId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('scrollPos: $scrollPos, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('secondsRead: $secondsRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NightsTable extends Nights with TableInfo<$NightsTable, Night> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayNumberMeta = const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unlockedOnMeta = const VerificationMeta('unlockedOn');
  @override
  late final GeneratedColumn<String> unlockedOn = GeneratedColumn<String>(
    'unlocked_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedOnMeta = const VerificationMeta('completedOn');
  @override
  late final GeneratedColumn<String> completedOn = GeneratedColumn<String>(
    'completed_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _piecesDoneMeta = const VerificationMeta('piecesDone');
  @override
  late final GeneratedColumn<int> piecesDone = GeneratedColumn<int>(
    'pieces_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [dayNumber, unlockedOn, completedOn, piecesDone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nights';
  @override
  VerificationContext validateIntegrity(Insertable<Night> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta, dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    }
    if (data.containsKey('unlocked_on')) {
      context.handle(_unlockedOnMeta, unlockedOn.isAcceptableOrUnknown(data['unlocked_on']!, _unlockedOnMeta));
    } else if (isInserting) {
      context.missing(_unlockedOnMeta);
    }
    if (data.containsKey('completed_on')) {
      context.handle(_completedOnMeta, completedOn.isAcceptableOrUnknown(data['completed_on']!, _completedOnMeta));
    }
    if (data.containsKey('pieces_done')) {
      context.handle(_piecesDoneMeta, piecesDone.isAcceptableOrUnknown(data['pieces_done']!, _piecesDoneMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayNumber};
  @override
  Night map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Night(
      dayNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      unlockedOn: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unlocked_on'])!,
      completedOn: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}completed_on']),
      piecesDone: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}pieces_done'])!,
    );
  }

  @override
  $NightsTable createAlias(String alias) {
    return $NightsTable(attachedDatabase, alias);
  }
}

class Night extends DataClass implements Insertable<Night> {
  final int dayNumber;
  final String unlockedOn;
  final String? completedOn;
  final int piecesDone;
  const Night({required this.dayNumber, required this.unlockedOn, this.completedOn, required this.piecesDone});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_number'] = Variable<int>(dayNumber);
    map['unlocked_on'] = Variable<String>(unlockedOn);
    if (!nullToAbsent || completedOn != null) {
      map['completed_on'] = Variable<String>(completedOn);
    }
    map['pieces_done'] = Variable<int>(piecesDone);
    return map;
  }

  NightsCompanion toCompanion(bool nullToAbsent) {
    return NightsCompanion(
      dayNumber: Value(dayNumber),
      unlockedOn: Value(unlockedOn),
      completedOn: completedOn == null && nullToAbsent ? const Value.absent() : Value(completedOn),
      piecesDone: Value(piecesDone),
    );
  }

  factory Night.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Night(
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      unlockedOn: serializer.fromJson<String>(json['unlockedOn']),
      completedOn: serializer.fromJson<String?>(json['completedOn']),
      piecesDone: serializer.fromJson<int>(json['piecesDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayNumber': serializer.toJson<int>(dayNumber),
      'unlockedOn': serializer.toJson<String>(unlockedOn),
      'completedOn': serializer.toJson<String?>(completedOn),
      'piecesDone': serializer.toJson<int>(piecesDone),
    };
  }

  Night copyWith({
    int? dayNumber,
    String? unlockedOn,
    Value<String?> completedOn = const Value.absent(),
    int? piecesDone,
  }) => Night(
    dayNumber: dayNumber ?? this.dayNumber,
    unlockedOn: unlockedOn ?? this.unlockedOn,
    completedOn: completedOn.present ? completedOn.value : this.completedOn,
    piecesDone: piecesDone ?? this.piecesDone,
  );
  Night copyWithCompanion(NightsCompanion data) {
    return Night(
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      unlockedOn: data.unlockedOn.present ? data.unlockedOn.value : this.unlockedOn,
      completedOn: data.completedOn.present ? data.completedOn.value : this.completedOn,
      piecesDone: data.piecesDone.present ? data.piecesDone.value : this.piecesDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Night(')
          ..write('dayNumber: $dayNumber, ')
          ..write('unlockedOn: $unlockedOn, ')
          ..write('completedOn: $completedOn, ')
          ..write('piecesDone: $piecesDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayNumber, unlockedOn, completedOn, piecesDone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Night &&
          other.dayNumber == this.dayNumber &&
          other.unlockedOn == this.unlockedOn &&
          other.completedOn == this.completedOn &&
          other.piecesDone == this.piecesDone);
}

class NightsCompanion extends UpdateCompanion<Night> {
  final Value<int> dayNumber;
  final Value<String> unlockedOn;
  final Value<String?> completedOn;
  final Value<int> piecesDone;
  const NightsCompanion({
    this.dayNumber = const Value.absent(),
    this.unlockedOn = const Value.absent(),
    this.completedOn = const Value.absent(),
    this.piecesDone = const Value.absent(),
  });
  NightsCompanion.insert({
    this.dayNumber = const Value.absent(),
    required String unlockedOn,
    this.completedOn = const Value.absent(),
    this.piecesDone = const Value.absent(),
  }) : unlockedOn = Value(unlockedOn);
  static Insertable<Night> custom({
    Expression<int>? dayNumber,
    Expression<String>? unlockedOn,
    Expression<String>? completedOn,
    Expression<int>? piecesDone,
  }) {
    return RawValuesInsertable({
      if (dayNumber != null) 'day_number': dayNumber,
      if (unlockedOn != null) 'unlocked_on': unlockedOn,
      if (completedOn != null) 'completed_on': completedOn,
      if (piecesDone != null) 'pieces_done': piecesDone,
    });
  }

  NightsCompanion copyWith({
    Value<int>? dayNumber,
    Value<String>? unlockedOn,
    Value<String?>? completedOn,
    Value<int>? piecesDone,
  }) {
    return NightsCompanion(
      dayNumber: dayNumber ?? this.dayNumber,
      unlockedOn: unlockedOn ?? this.unlockedOn,
      completedOn: completedOn ?? this.completedOn,
      piecesDone: piecesDone ?? this.piecesDone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (unlockedOn.present) {
      map['unlocked_on'] = Variable<String>(unlockedOn.value);
    }
    if (completedOn.present) {
      map['completed_on'] = Variable<String>(completedOn.value);
    }
    if (piecesDone.present) {
      map['pieces_done'] = Variable<int>(piecesDone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NightsCompanion(')
          ..write('dayNumber: $dayNumber, ')
          ..write('unlockedOn: $unlockedOn, ')
          ..write('completedOn: $completedOn, ')
          ..write('piecesDone: $piecesDone')
          ..write(')'))
        .toString();
  }
}

class $StreakTable extends Streak with TableInfo<$StreakTable, StreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentMeta = const VerificationMeta('current');
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestMeta = const VerificationMeta('longest');
  @override
  late final GeneratedColumn<int> longest = GeneratedColumn<int>(
    'longest',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadDateMeta = const VerificationMeta('lastReadDate');
  @override
  late final GeneratedColumn<String> lastReadDate = GeneratedColumn<String>(
    'last_read_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freezesLeftMeta = const VerificationMeta('freezesLeft');
  @override
  late final GeneratedColumn<int> freezesLeft = GeneratedColumn<int>(
    'freezes_left',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freezesResetOnMeta = const VerificationMeta('freezesResetOn');
  @override
  late final GeneratedColumn<String> freezesResetOn = GeneratedColumn<String>(
    'freezes_reset_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, current, longest, lastReadDate, freezesLeft, freezesResetOn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak';
  @override
  VerificationContext validateIntegrity(Insertable<StreakRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current')) {
      context.handle(_currentMeta, current.isAcceptableOrUnknown(data['current']!, _currentMeta));
    }
    if (data.containsKey('longest')) {
      context.handle(_longestMeta, longest.isAcceptableOrUnknown(data['longest']!, _longestMeta));
    }
    if (data.containsKey('last_read_date')) {
      context.handle(_lastReadDateMeta, lastReadDate.isAcceptableOrUnknown(data['last_read_date']!, _lastReadDateMeta));
    }
    if (data.containsKey('freezes_left')) {
      context.handle(_freezesLeftMeta, freezesLeft.isAcceptableOrUnknown(data['freezes_left']!, _freezesLeftMeta));
    }
    if (data.containsKey('freezes_reset_on')) {
      context.handle(
        _freezesResetOnMeta,
        freezesResetOn.isAcceptableOrUnknown(data['freezes_reset_on']!, _freezesResetOnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      current: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}current'])!,
      longest: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}longest'])!,
      lastReadDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last_read_date']),
      freezesLeft: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}freezes_left'])!,
      freezesResetOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freezes_reset_on'],
      ),
    );
  }

  @override
  $StreakTable createAlias(String alias) {
    return $StreakTable(attachedDatabase, alias);
  }
}

class StreakRow extends DataClass implements Insertable<StreakRow> {
  final int id;
  final int current;
  final int longest;
  final String? lastReadDate;
  final int freezesLeft;
  final String? freezesResetOn;
  const StreakRow({
    required this.id,
    required this.current,
    required this.longest,
    this.lastReadDate,
    required this.freezesLeft,
    this.freezesResetOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current'] = Variable<int>(current);
    map['longest'] = Variable<int>(longest);
    if (!nullToAbsent || lastReadDate != null) {
      map['last_read_date'] = Variable<String>(lastReadDate);
    }
    map['freezes_left'] = Variable<int>(freezesLeft);
    if (!nullToAbsent || freezesResetOn != null) {
      map['freezes_reset_on'] = Variable<String>(freezesResetOn);
    }
    return map;
  }

  StreakCompanion toCompanion(bool nullToAbsent) {
    return StreakCompanion(
      id: Value(id),
      current: Value(current),
      longest: Value(longest),
      lastReadDate: lastReadDate == null && nullToAbsent ? const Value.absent() : Value(lastReadDate),
      freezesLeft: Value(freezesLeft),
      freezesResetOn: freezesResetOn == null && nullToAbsent ? const Value.absent() : Value(freezesResetOn),
    );
  }

  factory StreakRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakRow(
      id: serializer.fromJson<int>(json['id']),
      current: serializer.fromJson<int>(json['current']),
      longest: serializer.fromJson<int>(json['longest']),
      lastReadDate: serializer.fromJson<String?>(json['lastReadDate']),
      freezesLeft: serializer.fromJson<int>(json['freezesLeft']),
      freezesResetOn: serializer.fromJson<String?>(json['freezesResetOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'current': serializer.toJson<int>(current),
      'longest': serializer.toJson<int>(longest),
      'lastReadDate': serializer.toJson<String?>(lastReadDate),
      'freezesLeft': serializer.toJson<int>(freezesLeft),
      'freezesResetOn': serializer.toJson<String?>(freezesResetOn),
    };
  }

  StreakRow copyWith({
    int? id,
    int? current,
    int? longest,
    Value<String?> lastReadDate = const Value.absent(),
    int? freezesLeft,
    Value<String?> freezesResetOn = const Value.absent(),
  }) => StreakRow(
    id: id ?? this.id,
    current: current ?? this.current,
    longest: longest ?? this.longest,
    lastReadDate: lastReadDate.present ? lastReadDate.value : this.lastReadDate,
    freezesLeft: freezesLeft ?? this.freezesLeft,
    freezesResetOn: freezesResetOn.present ? freezesResetOn.value : this.freezesResetOn,
  );
  StreakRow copyWithCompanion(StreakCompanion data) {
    return StreakRow(
      id: data.id.present ? data.id.value : this.id,
      current: data.current.present ? data.current.value : this.current,
      longest: data.longest.present ? data.longest.value : this.longest,
      lastReadDate: data.lastReadDate.present ? data.lastReadDate.value : this.lastReadDate,
      freezesLeft: data.freezesLeft.present ? data.freezesLeft.value : this.freezesLeft,
      freezesResetOn: data.freezesResetOn.present ? data.freezesResetOn.value : this.freezesResetOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakRow(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('lastReadDate: $lastReadDate, ')
          ..write('freezesLeft: $freezesLeft, ')
          ..write('freezesResetOn: $freezesResetOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, current, longest, lastReadDate, freezesLeft, freezesResetOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakRow &&
          other.id == this.id &&
          other.current == this.current &&
          other.longest == this.longest &&
          other.lastReadDate == this.lastReadDate &&
          other.freezesLeft == this.freezesLeft &&
          other.freezesResetOn == this.freezesResetOn);
}

class StreakCompanion extends UpdateCompanion<StreakRow> {
  final Value<int> id;
  final Value<int> current;
  final Value<int> longest;
  final Value<String?> lastReadDate;
  final Value<int> freezesLeft;
  final Value<String?> freezesResetOn;
  const StreakCompanion({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.lastReadDate = const Value.absent(),
    this.freezesLeft = const Value.absent(),
    this.freezesResetOn = const Value.absent(),
  });
  StreakCompanion.insert({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.lastReadDate = const Value.absent(),
    this.freezesLeft = const Value.absent(),
    this.freezesResetOn = const Value.absent(),
  });
  static Insertable<StreakRow> custom({
    Expression<int>? id,
    Expression<int>? current,
    Expression<int>? longest,
    Expression<String>? lastReadDate,
    Expression<int>? freezesLeft,
    Expression<String>? freezesResetOn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (current != null) 'current': current,
      if (longest != null) 'longest': longest,
      if (lastReadDate != null) 'last_read_date': lastReadDate,
      if (freezesLeft != null) 'freezes_left': freezesLeft,
      if (freezesResetOn != null) 'freezes_reset_on': freezesResetOn,
    });
  }

  StreakCompanion copyWith({
    Value<int>? id,
    Value<int>? current,
    Value<int>? longest,
    Value<String?>? lastReadDate,
    Value<int>? freezesLeft,
    Value<String?>? freezesResetOn,
  }) {
    return StreakCompanion(
      id: id ?? this.id,
      current: current ?? this.current,
      longest: longest ?? this.longest,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      freezesLeft: freezesLeft ?? this.freezesLeft,
      freezesResetOn: freezesResetOn ?? this.freezesResetOn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (longest.present) {
      map['longest'] = Variable<int>(longest.value);
    }
    if (lastReadDate.present) {
      map['last_read_date'] = Variable<String>(lastReadDate.value);
    }
    if (freezesLeft.present) {
      map['freezes_left'] = Variable<int>(freezesLeft.value);
    }
    if (freezesResetOn.present) {
      map['freezes_reset_on'] = Variable<String>(freezesResetOn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakCompanion(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('lastReadDate: $lastReadDate, ')
          ..write('freezesLeft: $freezesLeft, ')
          ..write('freezesResetOn: $freezesResetOn')
          ..write(')'))
        .toString();
  }
}

class $HighlightsTable extends Highlights with TableInfo<$HighlightsTable, Highlight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _startOffsetMeta = const VerificationMeta('startOffset');
  @override
  late final GeneratedColumn<int> startOffset = GeneratedColumn<int>(
    'start_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endOffsetMeta = const VerificationMeta('endOffset');
  @override
  late final GeneratedColumn<int> endOffset = GeneratedColumn<int>(
    'end_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, workId, startOffset, endOffset, body, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(Insertable<Highlight> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta, workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('start_offset')) {
      context.handle(_startOffsetMeta, startOffset.isAcceptableOrUnknown(data['start_offset']!, _startOffsetMeta));
    } else if (isInserting) {
      context.missing(_startOffsetMeta);
    }
    if (data.containsKey('end_offset')) {
      context.handle(_endOffsetMeta, endOffset.isAcceptableOrUnknown(data['end_offset']!, _endOffsetMeta));
    } else if (isInserting) {
      context.missing(_endOffsetMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['text']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Highlight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Highlight(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      workId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}work_id'])!,
      startOffset: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}start_offset'])!,
      endOffset: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}end_offset'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }
}

class Highlight extends DataClass implements Insertable<Highlight> {
  final int id;
  final String workId;
  final int startOffset;
  final int endOffset;
  final String body;
  final DateTime createdAt;
  const Highlight({
    required this.id,
    required this.workId,
    required this.startOffset,
    required this.endOffset,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['work_id'] = Variable<String>(workId);
    map['start_offset'] = Variable<int>(startOffset);
    map['end_offset'] = Variable<int>(endOffset);
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      workId: Value(workId),
      startOffset: Value(startOffset),
      endOffset: Value(endOffset),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory Highlight.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Highlight(
      id: serializer.fromJson<int>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      startOffset: serializer.fromJson<int>(json['startOffset']),
      endOffset: serializer.fromJson<int>(json['endOffset']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workId': serializer.toJson<String>(workId),
      'startOffset': serializer.toJson<int>(startOffset),
      'endOffset': serializer.toJson<int>(endOffset),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Highlight copyWith({int? id, String? workId, int? startOffset, int? endOffset, String? body, DateTime? createdAt}) =>
      Highlight(
        id: id ?? this.id,
        workId: workId ?? this.workId,
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
      );
  Highlight copyWithCompanion(HighlightsCompanion data) {
    return Highlight(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      startOffset: data.startOffset.present ? data.startOffset.value : this.startOffset,
      endOffset: data.endOffset.present ? data.endOffset.value : this.endOffset,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Highlight(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workId, startOffset, endOffset, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Highlight &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.startOffset == this.startOffset &&
          other.endOffset == this.endOffset &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class HighlightsCompanion extends UpdateCompanion<Highlight> {
  final Value<int> id;
  final Value<String> workId;
  final Value<int> startOffset;
  final Value<int> endOffset;
  final Value<String> body;
  final Value<DateTime> createdAt;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.startOffset = const Value.absent(),
    this.endOffset = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HighlightsCompanion.insert({
    this.id = const Value.absent(),
    required String workId,
    required int startOffset,
    required int endOffset,
    required String body,
    required DateTime createdAt,
  }) : workId = Value(workId),
       startOffset = Value(startOffset),
       endOffset = Value(endOffset),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<Highlight> custom({
    Expression<int>? id,
    Expression<String>? workId,
    Expression<int>? startOffset,
    Expression<int>? endOffset,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (startOffset != null) 'start_offset': startOffset,
      if (endOffset != null) 'end_offset': endOffset,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HighlightsCompanion copyWith({
    Value<int>? id,
    Value<String>? workId,
    Value<int>? startOffset,
    Value<int>? endOffset,
    Value<String>? body,
    Value<DateTime>? createdAt,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (startOffset.present) {
      map['start_offset'] = Variable<int>(startOffset.value);
    }
    if (endOffset.present) {
      map['end_offset'] = Variable<int>(endOffset.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES works (id)'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [workId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<Favorite> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta, workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      workId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}work_id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String workId;
  final DateTime createdAt;
  const Favorite({required this.workId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_id'] = Variable<String>(workId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(workId: Value(workId), createdAt: Value(createdAt));
  }

  factory Favorite.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      workId: serializer.fromJson<String>(json['workId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workId': serializer.toJson<String>(workId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({String? workId, DateTime? createdAt}) =>
      Favorite(workId: workId ?? this.workId, createdAt: createdAt ?? this.createdAt);
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      workId: data.workId.present ? data.workId.value : this.workId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('workId: $workId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Favorite && other.workId == this.workId && other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> workId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.workId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({required String workId, required DateTime createdAt, this.rowid = const Value.absent()})
    : workId = Value(workId),
      createdAt = Value(createdAt);
  static Insertable<Favorite> custom({
    Expression<String>? workId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workId != null) 'work_id': workId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({Value<String>? workId, Value<DateTime>? createdAt, Value<int>? rowid}) {
    return FavoritesCompanion(
      workId: workId ?? this.workId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('workId: $workId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta('reminderTime');
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('night'),
  );
  static const VerificationMeta _fontStepMeta = const VerificationMeta('fontStep');
  @override
  late final GeneratedColumn<int> fontStep = GeneratedColumn<int>(
    'font_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _lineStepMeta = const VerificationMeta('lineStep');
  @override
  late final GeneratedColumn<int> lineStep = GeneratedColumn<int>(
    'line_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta('onboardingDone');
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("onboarding_done" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _streakReminderMeta = const VerificationMeta('streakReminder');
  @override
  late final GeneratedColumn<bool> streakReminder = GeneratedColumn<bool>(
    'streak_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("streak_reminder" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _debugDayOffsetMeta = const VerificationMeta('debugDayOffset');
  @override
  late final GeneratedColumn<int> debugDayOffset = GeneratedColumn<int>(
    'debug_day_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderTime,
    theme,
    fontStep,
    lineStep,
    onboardingDone,
    streakReminder,
    debugDayOffset,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_time')) {
      context.handle(_reminderTimeMeta, reminderTime.isAcceptableOrUnknown(data['reminder_time']!, _reminderTimeMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(_themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));
    }
    if (data.containsKey('font_step')) {
      context.handle(_fontStepMeta, fontStep.isAcceptableOrUnknown(data['font_step']!, _fontStepMeta));
    }
    if (data.containsKey('line_step')) {
      context.handle(_lineStepMeta, lineStep.isAcceptableOrUnknown(data['line_step']!, _lineStepMeta));
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(data['onboarding_done']!, _onboardingDoneMeta),
      );
    }
    if (data.containsKey('streak_reminder')) {
      context.handle(
        _streakReminderMeta,
        streakReminder.isAcceptableOrUnknown(data['streak_reminder']!, _streakReminderMeta),
      );
    }
    if (data.containsKey('debug_day_offset')) {
      context.handle(
        _debugDayOffsetMeta,
        debugDayOffset.isAcceptableOrUnknown(data['debug_day_offset']!, _debugDayOffsetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      reminderTime: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reminder_time']),
      theme: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}theme'])!,
      fontStep: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}font_step'])!,
      lineStep: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}line_step'])!,
      onboardingDone: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}onboarding_done'])!,
      streakReminder: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}streak_reminder'])!,
      debugDayOffset: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}debug_day_offset'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String? reminderTime;
  final String theme;
  final int fontStep;
  final int lineStep;
  final bool onboardingDone;
  final bool streakReminder;
  final int debugDayOffset;
  const SettingsRow({
    required this.id,
    this.reminderTime,
    required this.theme,
    required this.fontStep,
    required this.lineStep,
    required this.onboardingDone,
    required this.streakReminder,
    required this.debugDayOffset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    map['theme'] = Variable<String>(theme);
    map['font_step'] = Variable<int>(fontStep);
    map['line_step'] = Variable<int>(lineStep);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['streak_reminder'] = Variable<bool>(streakReminder);
    map['debug_day_offset'] = Variable<int>(debugDayOffset);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      reminderTime: reminderTime == null && nullToAbsent ? const Value.absent() : Value(reminderTime),
      theme: Value(theme),
      fontStep: Value(fontStep),
      lineStep: Value(lineStep),
      onboardingDone: Value(onboardingDone),
      streakReminder: Value(streakReminder),
      debugDayOffset: Value(debugDayOffset),
    );
  }

  factory SettingsRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      theme: serializer.fromJson<String>(json['theme']),
      fontStep: serializer.fromJson<int>(json['fontStep']),
      lineStep: serializer.fromJson<int>(json['lineStep']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      streakReminder: serializer.fromJson<bool>(json['streakReminder']),
      debugDayOffset: serializer.fromJson<int>(json['debugDayOffset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'theme': serializer.toJson<String>(theme),
      'fontStep': serializer.toJson<int>(fontStep),
      'lineStep': serializer.toJson<int>(lineStep),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'streakReminder': serializer.toJson<bool>(streakReminder),
      'debugDayOffset': serializer.toJson<int>(debugDayOffset),
    };
  }

  SettingsRow copyWith({
    int? id,
    Value<String?> reminderTime = const Value.absent(),
    String? theme,
    int? fontStep,
    int? lineStep,
    bool? onboardingDone,
    bool? streakReminder,
    int? debugDayOffset,
  }) => SettingsRow(
    id: id ?? this.id,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    theme: theme ?? this.theme,
    fontStep: fontStep ?? this.fontStep,
    lineStep: lineStep ?? this.lineStep,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    streakReminder: streakReminder ?? this.streakReminder,
    debugDayOffset: debugDayOffset ?? this.debugDayOffset,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      reminderTime: data.reminderTime.present ? data.reminderTime.value : this.reminderTime,
      theme: data.theme.present ? data.theme.value : this.theme,
      fontStep: data.fontStep.present ? data.fontStep.value : this.fontStep,
      lineStep: data.lineStep.present ? data.lineStep.value : this.lineStep,
      onboardingDone: data.onboardingDone.present ? data.onboardingDone.value : this.onboardingDone,
      streakReminder: data.streakReminder.present ? data.streakReminder.value : this.streakReminder,
      debugDayOffset: data.debugDayOffset.present ? data.debugDayOffset.value : this.debugDayOffset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('theme: $theme, ')
          ..write('fontStep: $fontStep, ')
          ..write('lineStep: $lineStep, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('streakReminder: $streakReminder, ')
          ..write('debugDayOffset: $debugDayOffset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reminderTime, theme, fontStep, lineStep, onboardingDone, streakReminder, debugDayOffset);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.reminderTime == this.reminderTime &&
          other.theme == this.theme &&
          other.fontStep == this.fontStep &&
          other.lineStep == this.lineStep &&
          other.onboardingDone == this.onboardingDone &&
          other.streakReminder == this.streakReminder &&
          other.debugDayOffset == this.debugDayOffset);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> reminderTime;
  final Value<String> theme;
  final Value<int> fontStep;
  final Value<int> lineStep;
  final Value<bool> onboardingDone;
  final Value<bool> streakReminder;
  final Value<int> debugDayOffset;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.theme = const Value.absent(),
    this.fontStep = const Value.absent(),
    this.lineStep = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.streakReminder = const Value.absent(),
    this.debugDayOffset = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.theme = const Value.absent(),
    this.fontStep = const Value.absent(),
    this.lineStep = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.streakReminder = const Value.absent(),
    this.debugDayOffset = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? reminderTime,
    Expression<String>? theme,
    Expression<int>? fontStep,
    Expression<int>? lineStep,
    Expression<bool>? onboardingDone,
    Expression<bool>? streakReminder,
    Expression<int>? debugDayOffset,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (theme != null) 'theme': theme,
      if (fontStep != null) 'font_step': fontStep,
      if (lineStep != null) 'line_step': lineStep,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (streakReminder != null) 'streak_reminder': streakReminder,
      if (debugDayOffset != null) 'debug_day_offset': debugDayOffset,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? reminderTime,
    Value<String>? theme,
    Value<int>? fontStep,
    Value<int>? lineStep,
    Value<bool>? onboardingDone,
    Value<bool>? streakReminder,
    Value<int>? debugDayOffset,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      reminderTime: reminderTime ?? this.reminderTime,
      theme: theme ?? this.theme,
      fontStep: fontStep ?? this.fontStep,
      lineStep: lineStep ?? this.lineStep,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      streakReminder: streakReminder ?? this.streakReminder,
      debugDayOffset: debugDayOffset ?? this.debugDayOffset,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (fontStep.present) {
      map['font_step'] = Variable<int>(fontStep.value);
    }
    if (lineStep.present) {
      map['line_step'] = Variable<int>(lineStep.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (streakReminder.present) {
      map['streak_reminder'] = Variable<bool>(streakReminder.value);
    }
    if (debugDayOffset.present) {
      map['debug_day_offset'] = Variable<int>(debugDayOffset.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('theme: $theme, ')
          ..write('fontStep: $fontStep, ')
          ..write('lineStep: $lineStep, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('streakReminder: $streakReminder, ')
          ..write('debugDayOffset: $debugDayOffset')
          ..write(')'))
        .toString();
  }
}

class $ImportedPacksTable extends ImportedPacks with TableInfo<$ImportedPacksTable, ImportedPack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportedPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [packId, version, importedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imported_packs';
  @override
  VerificationContext validateIntegrity(Insertable<ImportedPack> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(_packIdMeta, packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(_importedAtMeta, importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId};
  @override
  ImportedPack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportedPack(
      packId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}pack_id'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      importedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}imported_at'])!,
    );
  }

  @override
  $ImportedPacksTable createAlias(String alias) {
    return $ImportedPacksTable(attachedDatabase, alias);
  }
}

class ImportedPack extends DataClass implements Insertable<ImportedPack> {
  final int packId;
  final int version;
  final DateTime importedAt;
  const ImportedPack({required this.packId, required this.version, required this.importedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<int>(packId);
    map['version'] = Variable<int>(version);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportedPacksCompanion toCompanion(bool nullToAbsent) {
    return ImportedPacksCompanion(packId: Value(packId), version: Value(version), importedAt: Value(importedAt));
  }

  factory ImportedPack.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportedPack(
      packId: serializer.fromJson<int>(json['packId']),
      version: serializer.fromJson<int>(json['version']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<int>(packId),
      'version': serializer.toJson<int>(version),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ImportedPack copyWith({int? packId, int? version, DateTime? importedAt}) => ImportedPack(
    packId: packId ?? this.packId,
    version: version ?? this.version,
    importedAt: importedAt ?? this.importedAt,
  );
  ImportedPack copyWithCompanion(ImportedPacksCompanion data) {
    return ImportedPack(
      packId: data.packId.present ? data.packId.value : this.packId,
      version: data.version.present ? data.version.value : this.version,
      importedAt: data.importedAt.present ? data.importedAt.value : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportedPack(')
          ..write('packId: $packId, ')
          ..write('version: $version, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packId, version, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedPack &&
          other.packId == this.packId &&
          other.version == this.version &&
          other.importedAt == this.importedAt);
}

class ImportedPacksCompanion extends UpdateCompanion<ImportedPack> {
  final Value<int> packId;
  final Value<int> version;
  final Value<DateTime> importedAt;
  const ImportedPacksCompanion({
    this.packId = const Value.absent(),
    this.version = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  ImportedPacksCompanion.insert({
    this.packId = const Value.absent(),
    required int version,
    required DateTime importedAt,
  }) : version = Value(version),
       importedAt = Value(importedAt);
  static Insertable<ImportedPack> custom({
    Expression<int>? packId,
    Expression<int>? version,
    Expression<DateTime>? importedAt,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (version != null) 'version': version,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  ImportedPacksCompanion copyWith({Value<int>? packId, Value<int>? version, Value<DateTime>? importedAt}) {
    return ImportedPacksCompanion(
      packId: packId ?? this.packId,
      version: version ?? this.version,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportedPacksCompanion(')
          ..write('packId: $packId, ')
          ..write('version: $version, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $WorksTable works = $WorksTable(this);
  late final $DaysTable days = $DaysTable(this);
  late final $ProgressTable progress = $ProgressTable(this);
  late final $NightsTable nights = $NightsTable(this);
  late final $StreakTable streak = $StreakTable(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ImportedPacksTable importedPacks = $ImportedPacksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    works,
    days,
    progress,
    nights,
    streak,
    highlights,
    favorites,
    settings,
    importedPacks,
  ];
}
