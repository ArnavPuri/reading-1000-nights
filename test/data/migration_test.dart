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

/// Opens a file as drift would at schema version 1 and fills it in.
class _V1Install extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    for (final sql in [..._v1Schema, ..._v1Data]) {
      await executor.runCustom(sql);
    }
  }
}

void main() {
  test('upgrading from version 1 adds favourites and keeps existing data', () async {
    final dir = await Directory.systemTemp.createTemp('nights-migration');
    final file = File('${dir.path}/db.sqlite');
    final v1 = NativeDatabase(file);
    await v1.ensureOpen(_V1Install());
    await v1.close();

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').map((r) => r.read<int>('user_version')).getSingle();
    expect(version, 2);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'favorites'")
        .get();
    expect(tables, hasLength(1));

    final repo = ReadingRepository(db);
    final night = (await repo.night(1))!;
    expect([for (final p in night.pieces) p.work.title], ['A Story', 'A Poem', 'An Essay']);
    expect([for (final p in night.pieces) p.done], [false, true, false]);
    expect((await db.getStreak()).current, 1);
    expect((await db.getSettings()).theme, 'sepia');
    expect((await repo.allHighlights()).single.highlight.body, 'Lo.');

    expect(await repo.toggleFavorite('p1', now: DateTime(2026, 10, 14)), isTrue);
    expect((await repo.favorites()).single.dayNumber, 1);

    await db.close();
    await dir.delete(recursive: true);
  });
}
