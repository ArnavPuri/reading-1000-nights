import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/analytics.dart';
import 'package:thousand_nights/core/providers.dart';
import 'package:thousand_nights/features/journey/constellation.dart';
import 'package:thousand_nights/features/share/share_card.dart';
import 'package:thousand_nights/features/share/share_sheet.dart';

import '../app_harness.dart';
import '../helpers.dart';

class _RecordingAnalytics extends Analytics {
  final events = <(AnalyticsEvent, int?, Map<String, Object?>)>[];

  @override
  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}}) =>
      events.add((event, dayNumber, props));
}

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(Uint8List png) {
  expect(png.sublist(1, 4), 'PNG'.codeUnits);
  final d = ByteData.sublistView(png);
  return (d.getUint32(16), d.getUint32(20));
}

/// A Semantics-labelled control, without turning semantics on.
Finder _labelled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

void _expectEvent((AnalyticsEvent, int?, Map<String, Object?>) e, AnalyticsEvent event, int day, String kind) {
  expect(e.$1, event);
  expect(e.$2, day);
  expect(e.$3, {'kind': kind});
}

final _shareButton = find.ancestor(of: find.text('Share'), matching: find.byWidgetPredicate((w) => w is FilledButton));

void main() {
  testWidgets('Night complete: Share opens the preview, and sharing hands over a 1080 x 1350 PNG', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    final repo = repoFor(db);
    await tester.runAsync(() async {
      await repo.debugJumpTo(7, testToday);
      for (final p in (await repo.night(7))!.pieces) {
        await repo.finishPiece(p.work.id, 7, now: testNow(), today: testToday);
      }
    });
    final analytics = _RecordingAnalytics();
    final shared = <SharePayload>[];
    await pumpApp(
      tester,
      db,
      location: '/night-complete/7',
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        shareFunctionProvider.overrideWithValue((p) async {
          shared.add(p);
          return true;
        }),
      ],
    );

    await tester.tap(find.text('Share'));
    await settle(tester);
    expect(find.byType(ShareCard), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    _expectEvent(analytics.events.last, AnalyticsEvent.shareCardOpened, 7, 'night');

    await tester.tap(_shareButton);
    await settle(tester);
    expect(shared, hasLength(1));
    expect(_pngSize(shared.single.png), (1080, 1350));
    expect(shared.single.fileName, '${ShareBrand.slug}-night-7.png');
    expect(shared.single.text, contains(ShareBrand.name));
    _expectEvent(analytics.events.last, AnalyticsEvent.shareCardShared, 7, 'night');

    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.byType(ShareCard), findsNothing);

    await tearDownApp(tester, db);
  });

  testWidgets('Library highlight: the share button opens its card on the night of the work', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    final repo = repoFor(db);
    await tester.runAsync(() async {
      await repo.debugJumpTo(3, testToday);
      await repo.addHighlight('dickinson-hope', 0, 10, 'Hope is the thing with feathers');
    });
    await pumpApp(
      tester,
      db,
      location: '/library',
      overrides: [shareFunctionProvider.overrideWithValue((_) async => true)],
    );

    await tester.tap(find.text('HIGHLIGHTS'));
    await settle(tester);
    await tester.tap(_labelled('Share highlight'));
    await settle(tester);
    expect(find.byType(ShareCard), findsOneWidget);
    expect(find.text('NIGHT 2 OF 1000'), findsOneWidget);

    await tearDownApp(tester, db);
  });

  testWidgets('Journey: the share button appears once a milestone is reached', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    final repo = repoFor(db);
    await tester.runAsync(() => repo.debugJumpTo(7, testToday));
    await pumpApp(tester, db, location: '/journey');
    // six nights read: no milestone yet
    expect(_labelled('Share milestone'), findsNothing);

    await tester.runAsync(() async {
      for (final p in (await repo.night(7))!.pieces) {
        await repo.finishPiece(p.work.id, 7, now: testNow(), today: testToday);
      }
    });
    await settle(tester);
    await tester.tap(_labelled('Share milestone'));
    await settle(tester);
    expect(find.byType(ShareCard), findsOneWidget);
    expect(find.text('THE CANDLE'), findsWidgets);
    expect(find.text('Night 7'), findsOneWidget);

    // the map: a tap on the milestone's name shares it, a tap on a star still opens its night
    await tester.tap(find.text('Close'));
    await settle(tester);
    final map = find.byWidgetPredicate((w) => w is CustomPaint && '${w.painter.runtimeType}' == '_MapPainter');
    final origin = tester.getTopLeft(map);
    final size = tester.getSize(map);
    // _MapPainter.toCanvas, with its padding of (20, 34, 26, 120)
    Offset star(int day) {
      final p = ConstellationLayout.standard().pointFor(day);
      return origin + Offset(20 + p.dx * (size.width - 46), 34 + p.dy * (size.height - 154));
    }

    await tester.tapAt(star(7) + const Offset(40, 0));
    await settle(tester);
    expect(find.byType(ShareCard), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle(tester);

    await tester.tapAt(star(7));
    await settle(tester);
    expect(find.byType(ShareCard), findsNothing);
    expect(find.text('NIGHT 7'), findsOneWidget);

    await tearDownApp(tester, db);
  });

  test('latestMilestone', () {
    expect(latestMilestone(6), isNull);
    expect(latestMilestone(7), 7);
    expect(latestMilestone(99), 30);
    expect(latestMilestone(1000), 1000);
  });
}
