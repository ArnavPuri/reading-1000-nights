import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_harness.dart';
import '../helpers.dart';

void main() {
  testWidgets('Tonight shows night 1; reading and finishing a piece marks it done', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = await tester.runAsync(seededDb);
    await tester.runAsync(() => repoFor(db!).ensureToday(testToday));
    await pumpApp(tester, db!);

    expect(find.text('NIGHT 1 OF 1000'), findsOneWidget);
    expect(find.text('Tonight’s reading'), findsOneWidget);
    expect(find.text('The Nightingale and the Rose'), findsOneWidget);
    expect(find.text('A Dream Within a Dream'), findsOneWidget);
    expect(find.text('El Dorado'), findsOneWidget);

    // open the poem: the tab bar hides while reading
    await tester.tap(find.text('A Dream Within a Dream'));
    await settle(tester);
    expect(find.text('Tonight'), findsNothing);
    expect(find.text('A DREAM WITHIN A DREAM'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Finish'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Finish'));
    await settle(tester);

    expect(find.text('Tonight’s reading'), findsOneWidget);
    final progress = await tester.runAsync(() => repoFor(db).tonight());
    expect(progress!.tonight!.pieces[1].done, isTrue);
    expect(progress.streak, 1);

    await tearDownApp(tester, db);
  });

  testWidgets('Journey shows stats and Library lists unlocked nights', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = await tester.runAsync(seededDb);
    await tester.runAsync(() => repoFor(db!).debugJumpTo(4, testToday));
    await pumpApp(tester, db!, location: '/journey');

    expect(find.text('Your journey'), findsOneWidget);
    expect(find.text('NIGHTS'), findsOneWidget);
    expect(find.text('DAY STREAK'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await settle(tester);
    expect(find.text('4'), findsWidgets);
    expect(find.textContaining('The Gift of the Magi', findRichText: true), findsOneWidget);

    await tearDownApp(tester, db);
  });
}
