import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/data/content_pack.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/data/reading_repository.dart';
import 'package:thousand_nights/domain/local_date.dart';

import '../helpers.dart';

void main() {
  const day1 = LocalDate(2026, 10, 3);
  DateTime at(LocalDate d, [int h = 21]) => DateTime(d.year, d.month, d.day, h);

  late AppDatabase db;
  late ReadingRepository repo;

  setUp(() async {
    db = await seededDb();
    repo = ReadingRepository(db);
  });
  tearDown(() => db.close());

  Future<void> finishAll(int night, LocalDate d) async {
    final view = (await repo.night(night))!;
    for (final p in view.pieces) {
      await repo.finishPiece(p.work.id, night, now: at(d), today: d, addSeconds: 600);
    }
  }

  test('first launch unlocks night 1 with three pieces in order', () async {
    await repo.ensureToday(day1);
    final t = await repo.tonight();
    expect(t.tonight!.dayNumber, 1);
    expect([for (final p in t.tonight!.pieces) p.work.type], ['story', 'poem', 'essay']);
    expect(t.tomorrow!.first.title, 'The Gift of the Magi');
  });

  test('one finished piece counts the night; the next unlocks only after midnight', () async {
    await repo.ensureToday(day1);
    final poem = (await repo.night(1))!.pieces[1].work;
    final r = await repo.finishPiece(poem.id, 1, now: at(day1), today: day1);
    expect(r.nightComplete, isFalse);

    await repo.ensureToday(day1);
    expect((await repo.tonight()).tonight!.dayNumber, 1);
    expect((await repo.tonight()).streak, 1);

    await repo.ensureToday(day1.addDays(1));
    expect((await repo.tonight()).tonight!.dayNumber, 2);
  });

  test('finishing all three completes the night', () async {
    await repo.ensureToday(day1);
    final view = (await repo.night(1))!;
    FinishResult? last;
    for (final p in view.pieces) {
      last = await repo.finishPiece(p.work.id, 1, now: at(day1), today: day1);
    }
    expect(last!.nightComplete, isTrue);
    expect((await repo.night(1))!.allDone, isTrue);
  });

  test('finishing a piece twice does not double count', () async {
    await repo.ensureToday(day1);
    final story = (await repo.night(1))!.pieces.first.work;
    await repo.finishPiece(story.id, 1, now: at(day1), today: day1);
    await repo.finishPiece(story.id, 1, now: at(day1), today: day1);
    expect((await repo.night(1))!.night.piecesDone, 1);
  });

  test('seven nights in a row, then a missed day resets the streak but not nights', () async {
    var d = day1;
    for (var n = 1; n <= 7; n++) {
      await repo.ensureToday(d);
      expect((await repo.tonight()).tonight!.dayNumber, n);
      await finishAll(n, d);
      d = d.addDays(1);
    }
    var j = await repo.journey();
    expect(j.nightsCompleted, 7);
    expect(j.streak, 7);
    expect(j.secondsRead, 21 * 600);

    // skip a day
    await repo.ensureToday(d.addDays(1));
    j = await repo.journey();
    expect(j.streak, 0);
    expect(j.nightsCompleted, 7, reason: 'nights completed never decreases');
  });

  test('past the last night of content, tonight stays on the last night', () async {
    var d = day1;
    for (var n = 1; n <= 7; n++) {
      await repo.ensureToday(d);
      await finishAll(n, d);
      d = d.addDays(1);
    }
    await repo.ensureToday(d);
    expect((await repo.tonight()).tonight!.dayNumber, 7);
    expect((await repo.tonight()).tomorrow, isNull);
  });

  test('scroll position and time read are saved', () async {
    await repo.ensureToday(day1);
    final story = (await repo.night(1))!.pieces.first.work;
    await repo.startPiece(story.id, 1, at(day1));
    await repo.saveReading(story.id, 1, scrollPos: 0.42, addSeconds: 90);
    await repo.saveReading(story.id, 1, scrollPos: 0.5, addSeconds: 30);
    final p = await repo.progressFor(story.id, 1);
    expect(p!.scrollPos, 0.5);
    expect(p.secondsRead, 120);
  });

  test('highlights are stored and listed with their work', () async {
    await repo.ensureToday(day1);
    final story = (await repo.night(1))!.pieces.first.work;
    final id = await repo.addHighlight(story.id, 10, 40, 'a sentence');
    expect((await repo.allHighlights()).single.work.title, 'The Nightingale and the Rose');
    await repo.removeHighlight(id);
    expect(await repo.allHighlights(), isEmpty);
  });

  test('week dots mark days with a finished piece', () async {
    await repo.ensureToday(day1);
    await finishAll(1, day1);
    await repo.ensureToday(day1.addDays(1));
    await finishAll(2, day1.addDays(1));
    expect(await repo.week(day1.addDays(1)), [false, false, false, false, false, true, true]);
  });

  test('debug jump rewrites history to night n', () async {
    await repo.debugJumpTo(5, day1);
    final t = await repo.tonight();
    expect(t.tonight!.dayNumber, 5);
    expect(t.streak, 4);
    expect((await repo.journey()).litNights, [1, 2, 3, 4]);
  });

  test('phase 1 gate: progress survives an app restart', () async {
    final dir = await Directory.systemTemp.createTemp('nights');
    final file = File('${dir.path}/db.sqlite');
    var fileDb = AppDatabase(NativeDatabase(file));
    await PackImporter(fileDb).import(loadPack1());
    var r = ReadingRepository(fileDb);
    await r.ensureToday(day1);
    final story = (await r.night(1))!.pieces.first.work;
    await r.finishPiece(story.id, 1, now: at(day1), today: day1);
    await fileDb.close();

    fileDb = AppDatabase(NativeDatabase(file));
    expect(
      await PackImporter(fileDb).import(ContentPack.decode(File('assets/packs/pack-001.json').readAsStringSync())),
      isFalse,
    );
    r = ReadingRepository(fileDb);
    await r.ensureToday(day1);
    final t = await r.tonight();
    expect(t.tonight!.pieces.first.done, isTrue);
    expect(t.streak, 1);
    await fileDb.close();
    await dir.delete(recursive: true);
  });
}
