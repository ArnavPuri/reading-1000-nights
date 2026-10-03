// Renders real app screens to docs/screenshots/*.png for the README.
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//   python3 tool/frame_screenshots.py
//
// Skipped in normal test runs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:thousand_nights/data/database.dart';

import '../app_harness.dart';
import '../helpers.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');

final _boundary = GlobalKey();

Future<void> _capture(WidgetTester tester, String name) async {
  await settle(tester);
  await tester.runAsync(() async {
    final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await ro.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('docs/screenshots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Decodes every card image up front: decoding is real async work.
Future<void> _precacheImages(WidgetTester tester) async {
  final ctx = _boundary.currentContext!;
  final dir = Directory('assets/packs/pack-001/images');
  for (final f in dir.listSync().whereType<File>()) {
    await tester.runAsync(() => precacheImage(AssetImage(f.path), ctx));
  }
}

Future<AppDatabase> _db(WidgetTester tester) async {
  await tester.runAsync(loadAppFonts);
  return (await tester.runAsync(seededDb))!;
}

void main() {
  testWidgets('tonight', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() => repoFor(db).debugJumpTo(7, testToday));
    await pumpApp(tester, db, boundaryKey: _boundary);
    await _precacheImages(tester);
    await _capture(tester, 'tonight');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('tonight-progress', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    final repo = repoFor(db);
    await tester.runAsync(() async {
      await repo.debugJumpTo(3, testToday);
      final poem = (await repo.night(3))!.pieces[1].work;
      await repo.finishPiece(poem.id, 3, now: testNow(), today: testToday, addSeconds: 120);
    });
    await pumpApp(tester, db, boundaryKey: _boundary);
    await _precacheImages(tester);
    await _capture(tester, 'tonight-progress');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('reader', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    final repo = repoFor(db);
    const id = 'wilde-the-nightingale-and-the-rose';
    await tester.runAsync(() async {
      await repo.ensureToday(testToday);
      final work = await repo.work(id);
      const sentence = 'Ah, on what little things does happiness depend!';
      final start = work.textMd.indexOf(sentence) - 1; // opening quote
      await repo.addHighlight(id, start, start + sentence.length + 2, '‘$sentence’');
    });
    await pumpApp(tester, db, location: '/read/1/$id', boundaryKey: _boundary);
    await _capture(tester, 'reader');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('reader-poem-sepia', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() async {
      await repoFor(db).ensureToday(testToday);
      await db.update(db.settings).write(const SettingsCompanion(theme: Value('sepia')));
    });
    await pumpApp(tester, db, location: '/read/1/poe-a-dream-within-a-dream', boundaryKey: _boundary);
    await _capture(tester, 'reader-poem-sepia');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('reader-settings', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    await pumpApp(tester, db, location: '/read/1/stevenson-el-dorado', boundaryKey: _boundary);
    await tester.tap(find.text('Aa'));
    await _capture(tester, 'reader-settings');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('journey', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    final repo = repoFor(db);
    await tester.runAsync(() async {
      await repo.debugJumpTo(7, testToday);
      for (final p in (await repo.night(7))!.pieces) {
        await repo.finishPiece(p.work.id, 7, now: testNow(), today: testToday, addSeconds: p.work.estMinutes * 60);
      }
    });
    await pumpApp(tester, db, location: '/journey', boundaryKey: _boundary);
    await tester.pump(const Duration(seconds: 2));
    await _capture(tester, 'journey');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('night-complete', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    final repo = repoFor(db);
    await tester.runAsync(() async {
      await repo.debugJumpTo(7, testToday);
      for (final p in (await repo.night(7))!.pieces) {
        await repo.finishPiece(p.work.id, 7, now: testNow(), today: testToday);
      }
    });
    await pumpApp(tester, db, location: '/night-complete/7', boundaryKey: _boundary);
    await _capture(tester, 'night-complete');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('library', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() => repoFor(db).debugJumpTo(7, testToday));
    await pumpApp(tester, db, location: '/library', boundaryKey: _boundary);
    await _capture(tester, 'library');
    await tearDownApp(tester, db);
  }, skip: !_enabled);
}
