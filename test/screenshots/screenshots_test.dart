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
import 'package:thousand_nights/core/router.dart';
import 'package:thousand_nights/core/theme.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/features/share/share_card.dart';

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

/// Renders one share card on its own at 1080 x 1350.
Future<void> _shareCard(WidgetTester tester, String name, ShareCardData data) async {
  tester.view.physicalSize = const Size(1080, 1350);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.runAsync(loadAppFonts);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Center(
        child: RepaintBoundary(key: _boundary, child: ShareCard(data)),
      ),
    ),
  );
  final image = data.imagePath;
  if (image != null) await tester.runAsync(() => precacheImage(AssetImage(image), _boundary.currentContext!));
  await _capture(tester, name);
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

  // Onboarding, page by page, after each page's entrance has played out.
  Future<void> onboarding(WidgetTester tester, String name, List<String> taps) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    await pumpApp(tester, db, onboardingDone: false, boundaryKey: _boundary);
    await _precacheImages(tester);
    for (final t in taps) {
      await tester.tap(find.text(t));
      await settle(tester);
    }
    await tester.pump(const Duration(seconds: 7));
    await _capture(tester, name);
    await tearDownApp(tester, db);
  }

  testWidgets('onboarding-welcome', (tester) => onboarding(tester, 'onboarding-welcome', []), skip: !_enabled);

  testWidgets('onboarding-card', (tester) => onboarding(tester, 'onboarding-card', ['Begin']), skip: !_enabled);

  testWidgets(
    'onboarding-reader',
    (tester) => onboarding(tester, 'onboarding-reader', ['Begin', 'Continue']),
    skip: !_enabled,
  );

  testWidgets(
    'onboarding-journey',
    (tester) => onboarding(tester, 'onboarding-journey', ['Begin', 'Continue', 'Continue']),
    skip: !_enabled,
  );

  testWidgets('onboarding-time', (tester) => onboarding(tester, 'onboarding-time', ['Begin', 'Skip']), skip: !_enabled);

  testWidgets(
    'onboarding-notify',
    (tester) => onboarding(tester, 'onboarding-notify', ['Begin', 'Skip', 'Continue']),
    skip: !_enabled,
  );

  testWidgets(
    'onboarding-begin',
    (tester) => onboarding(tester, 'onboarding-begin', ['Begin', 'Skip', 'Continue', 'Allow']),
    skip: !_enabled,
  );

  testWidgets('reminders', (tester) async {
    usePhoneSize(tester);
    final db = await _db(tester);
    await tester.runAsync(() async {
      await repoFor(db).debugJumpTo(7, testToday);
      await db.update(db.settings).write(const SettingsCompanion(reminderTime: Value('21:30')));
    });
    await pumpApp(
      tester,
      db,
      location: Routes.journey,
      boundaryKey: _boundary,
      reminders: FakeReminderScheduler()..granted = true,
    );
    await tester.tap(find.bySemanticsLabel('Reminders'));
    await settle(tester);
    await _capture(tester, 'reminders');
    await tearDownApp(tester, db);
  }, skip: !_enabled);

  testWidgets('share-highlight', (tester) async {
    final db = await _db(tester);
    final work = (await tester.runAsync(() => repoFor(db).work('wilde-the-nightingale-and-the-rose')))!;
    await tester.runAsync(db.close);
    await _shareCard(
      tester,
      'share-highlight',
      HighlightShare.of('“Ah, on what little things does happiness depend!', work, dayNumber: 1),
    );
  }, skip: !_enabled);

  testWidgets('share-night', (tester) async {
    final db = await _db(tester);
    final repo = repoFor(db);
    final night = (await tester.runAsync(() async {
      await repo.debugJumpTo(7, testToday);
      for (final p in (await repo.night(7))!.pieces) {
        await repo.finishPiece(p.work.id, 7, now: testNow(), today: testToday);
      }
      return repo.night(7);
    }))!;
    await tester.runAsync(db.close);
    await _shareCard(tester, 'share-night', NightShare.of(night));
  }, skip: !_enabled);

  testWidgets('share-milestone', (tester) async {
    await _shareCard(
      tester,
      'share-milestone',
      const MilestoneShare(milestone: 30, nightsCompleted: 30, streak: 30, longestStreak: 30),
    );
  }, skip: !_enabled);
}
