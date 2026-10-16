import 'package:drift/drift.dart';

part 'database.g.dart';

/// One piece of writing: a short story, poem or essay.
@DataClassName('Work')
class Works extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // story | poem | essay
  TextColumn get title => text()();
  TextColumn get author => text()();
  IntColumn get year => integer()();
  IntColumn get wordCount => integer()();
  IntColumn get estMinutes => integer()();
  TextColumn get partLabel => text().nullable()();
  TextColumn get textMd => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sourceRef => text()();
  TextColumn get rightsNote => text()();
  // Not in the PRD schema: the line shown on the night complete screen.
  TextColumn get pullQuote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The fixed nightly sequence: one row per night, from content packs.
@DataClassName('Day')
class Days extends Table {
  IntColumn get dayNumber => integer()();
  TextColumn get storyId => text().references(Works, #id)();
  TextColumn get poemId => text().references(Works, #id)();
  TextColumn get essayId => text().references(Works, #id)();
  IntColumn get packId => integer()();

  @override
  Set<Column> get primaryKey => {dayNumber};
}

/// One row per piece opened.
@DataClassName('ProgressRow')
class Progress extends Table {
  TextColumn get workId => text().references(Works, #id)();
  IntColumn get dayNumber => integer()();
  RealColumn get scrollPos => real().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  // Not in the PRD schema: drives "total time read" on Journey.
  IntColumn get secondsRead => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {workId, dayNumber};
}

/// The user's nights. Dates are local calendar dates as 'YYYY-MM-DD'.
@DataClassName('Night')
class Nights extends Table {
  IntColumn get dayNumber => integer()();
  TextColumn get unlockedOn => text()();
  TextColumn get completedOn => text().nullable()();
  IntColumn get piecesDone => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dayNumber};
}

/// Single row (id = 1).
@DataClassName('StreakRow')
class Streak extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get current => integer().withDefault(const Constant(0))();
  IntColumn get longest => integer().withDefault(const Constant(0))();
  TextColumn get lastReadDate => text().nullable()();
  IntColumn get freezesLeft => integer().withDefault(const Constant(0))();
  TextColumn get freezesResetOn => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Highlight')
class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workId => text().references(Works, #id)();
  IntColumn get startOffset => integer()(); // into text_md
  IntColumn get endOffset => integer()();
  TextColumn get body => text().named('text')();
  DateTimeColumn get createdAt => dateTime()();
}

/// Not in the PRD schema: pieces the user keeps (Library → Saved). Added in
/// schema version 2.
@DataClassName('Favorite')
class Favorites extends Table {
  TextColumn get workId => text().references(Works, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {workId};
}

/// Single row (id = 1).
@DataClassName('SettingsRow')
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get reminderTime => text().nullable()(); // 'HH:mm'
  TextColumn get theme => text().withDefault(const Constant('night'))();
  IntColumn get fontStep => integer().withDefault(const Constant(2))(); // 0..4
  IntColumn get lineStep => integer().withDefault(const Constant(1))(); // 0..2
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  // Not in the PRD schema: the "streak at risk" reminder at 10 pm. Added in
  // schema version 3.
  BoolColumn get streakReminder => boolean().withDefault(const Constant(true))();
  // Debug only: shifts "today" so a tester can walk through nights.
  IntColumn get debugDayOffset => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Content packs already imported, so the importer is idempotent.
@DataClassName('ImportedPack')
class ImportedPacks extends Table {
  IntColumn get packId => integer()();
  IntColumn get version => integer()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {packId};
}

@DriftDatabase(tables: [Works, Days, Progress, Nights, Streak, Highlights, Favorites, Settings, ImportedPacks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(streak).insert(const StreakCompanion());
      await into(settings).insert(const SettingsCompanion());
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(favorites);
      if (from < 3) await m.addColumn(settings, settings.streakReminder);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<SettingsRow> getSettings() => select(settings).getSingle();
  Future<StreakRow> getStreak() => select(streak).getSingle();

  Future<void> resetUserState() => transaction(() async {
    await delete(progress).go();
    await delete(nights).go();
    await delete(highlights).go();
    await delete(favorites).go();
    await update(streak).write(
      const StreakCompanion(
        current: Value(0),
        longest: Value(0),
        lastReadDate: Value(null),
        freezesLeft: Value(0),
        freezesResetOn: Value(null),
      ),
    );
    await update(settings).write(const SettingsCompanion(debugDayOffset: Value(0)));
  });
}
