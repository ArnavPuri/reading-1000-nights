import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/data/reading_repository.dart';

/// The schema as drift created it at version 1, before favourites.
const _v1Schema = [
  'CREATE TABLE "works" ("id" TEXT NOT NULL, "type" TEXT NOT NULL, "title" TEXT NOT NULL, "author" TEXT NOT NULL, '
      '"year" INTEGER NOT NULL, "word_count" INTEGER NOT NULL, "est_minutes" INTEGER NOT NULL, "part_label" TEXT NULL, '
      '"text_md" TEXT NOT NULL, "image_path" TEXT NULL, "source_ref" TEXT NOT NULL, "rights_note" TEXT NOT NULL, '
      '"pull_quote" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "days" ("day_number" INTEGER NOT NULL, "story_id" TEXT NOT NULL REFERENCES works (id), '
      '"poem_id" TEXT NOT NULL REFERENCES works (id), "essay_id" TEXT NOT NULL REFERENCES works (id), '
      '"pack_id" INTEGER NOT NULL, PRIMARY KEY ("day_number"))',
  'CREATE TABLE "progress" ("work_id" TEXT NOT NULL REFERENCES works (id), "day_number" INTEGER NOT NULL, '
      '"scroll_pos" REAL NOT NULL DEFAULT 0.0, "started_at" INTEGER NOT NULL, "completed_at" INTEGER NULL, '
      '"seconds_read" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("work_id", "day_number"))',
  'CREATE TABLE "nights" ("day_number" INTEGER NOT NULL, "unlocked_on" TEXT NOT NULL, "completed_on" TEXT NULL, '
      '"pieces_done" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("day_number"))',
  'CREATE TABLE "streak" ("id" INTEGER NOT NULL DEFAULT 1, "current" INTEGER NOT NULL DEFAULT 0, '
      '"longest" INTEGER NOT NULL DEFAULT 0, "last_read_date" TEXT NULL, "freezes_left" INTEGER NOT NULL DEFAULT 0, '
      '"freezes_reset_on" TEXT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "highlights" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"work_id" TEXT NOT NULL REFERENCES works (id), "start_offset" INTEGER NOT NULL, "end_offset" INTEGER NOT NULL, '
      '"text" TEXT NOT NULL, "created_at" INTEGER NOT NULL)',
  'CREATE TABLE "settings" ("id" INTEGER NOT NULL DEFAULT 1, "reminder_time" TEXT NULL, '
      '"theme" TEXT NOT NULL DEFAULT \'night\', "font_step" INTEGER NOT NULL DEFAULT 2, '
      '"line_step" INTEGER NOT NULL DEFAULT 1, '
      '"onboarding_done" INTEGER NOT NULL DEFAULT 0 CHECK ("onboarding_done" IN (0, 1)), '
      '"debug_day_offset" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"))',
  'CREATE TABLE "imported_packs" ("pack_id" INTEGER NOT NULL, "version" INTEGER NOT NULL, '
      '"imported_at" INTEGER NOT NULL, PRIMARY KEY ("pack_id"))',
];

/// Version 2 added favourites.
const _v2Schema = [
  ..._v1Schema,
  'CREATE TABLE "favorites" ("work_id" TEXT NOT NULL REFERENCES works (id), "created_at" INTEGER NOT NULL, '
      'PRIMARY KEY ("work_id"))',
];

/// A version 1 install with one night read and one highlight.
const _v1Data = [
  "INSERT INTO works VALUES ('s1', 'story', 'A Story', 'An Author', 1900, 1000, 5, NULL, 'Once.', NULL, 'src', "
      "'PD', NULL)",
  "INSERT INTO works VALUES ('p1', 'poem', 'A Poem', 'A Poet', 1900, 100, 1, NULL, 'Lo.', NULL, 'src', 'PD', NULL)",
  "INSERT INTO works VALUES ('e1', 'essay', 'An Essay', 'An Essayist', 1900, 900, 4, NULL, 'Of.', NULL, 'src', "
      "'PD', NULL)",
  "INSERT INTO days VALUES (1, 's1', 'p1', 'e1', 1)",
  "INSERT INTO nights VALUES (1, '2026-10-03', '2026-10-03', 1)",
  "INSERT INTO progress VALUES ('p1', 1, 1.0, 1790000000, 1790000600, 600)",
  "INSERT INTO streak (id, current, longest, last_read_date) VALUES (1, 1, 1, '2026-10-03')",
  "INSERT INTO settings (id, theme) VALUES (1, 'sepia')",
  "INSERT INTO highlights (work_id, start_offset, end_offset, text, created_at) VALUES ('p1', 0, 3, 'Lo.', "
      "1790000300)",
];

/// A version 2 install: the same data plus a reminder time and a favourite.
const _v2Data = [
  ..._v1Data,
  "UPDATE settings SET reminder_time = '21:30', onboarding_done = 1",
  "INSERT INTO favorites VALUES ('s1', 1790000700)",
];

/// Opens a file as drift would at an old schema version and fills it in.
class _OldInstall extends QueryExecutorUser {
  _OldInstall(this.schemaVersion, this.statements);

  @override
  final int schemaVersion;
  final List<String> statements;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    for (final sql in statements) {
      await executor.runCustom(sql);
    }
  }
}

/// Writes an old install to a temporary file and opens it with the current
/// schema, which runs the migration.
Future<(AppDatabase, Directory)> _upgrade(int from, List<String> statements) async {
  final dir = await Directory.systemTemp.createTemp('nights-migration');
  final file = File('${dir.path}/db.sqlite');
  final old = NativeDatabase(file);
  await old.ensureOpen(_OldInstall(from, statements));
  await old.close();
  final db = AppDatabase(NativeDatabase(file));
  final version = await db.customSelect('PRAGMA user_version').map((r) => r.read<int>('user_version')).getSingle();
  expect(version, 3);
  return (db, dir);
}

void main() {
  test('upgrading from version 1 adds favourites and the streak reminder and keeps existing data', () async {
    final (db, dir) = await _upgrade(1, [..._v1Schema, ..._v1Data]);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'favorites'")
        .get();
    expect(tables, hasLength(1));

    final repo = ReadingRepository(db);
    final night = (await repo.night(1))!;
    expect([for (final p in night.pieces) p.work.title], ['A Story', 'A Poem', 'An Essay']);
    expect([for (final p in night.pieces) p.done], [false, true, false]);
    expect((await db.getStreak()).current, 1);
    final settings = await db.getSettings();
    expect(settings.theme, 'sepia');
    expect(settings.streakReminder, isTrue);
    expect((await repo.allHighlights()).single.highlight.body, 'Lo.');

    expect(await repo.toggleFavorite('p1', now: DateTime(2026, 10, 14)), isTrue);
    expect((await repo.favorites()).single.dayNumber, 1);

    await db.close();
    await dir.delete(recursive: true);
  });

  test('upgrading from version 2 adds the streak reminder and keeps settings and favourites', () async {
    final (db, dir) = await _upgrade(2, [..._v2Schema, ..._v2Data]);

    final settings = await db.getSettings();
    expect(settings.theme, 'sepia');
    expect(settings.reminderTime, '21:30');
    expect(settings.onboardingDone, isTrue);
    expect(settings.streakReminder, isTrue);
    await db.update(db.settings).write(const SettingsCompanion(streakReminder: Value(false)));
    expect((await db.getSettings()).streakReminder, isFalse);

    final repo = ReadingRepository(db);
    expect((await repo.favorites()).single.work.id, 's1');
    expect((await db.getStreak()).current, 1);

    await db.close();
    await dir.delete(recursive: true);
  });
}
