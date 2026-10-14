import 'package:flutter_test/flutter_test.dart';

import '../app_harness.dart';
import '../helpers.dart';

void main() {
  testWidgets('the ribbon in the reader saves a piece to Library → Saved', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = await tester.runAsync(seededDb);
    await tester.runAsync(() => repoFor(db!).ensureToday(testToday));
    await pumpApp(tester, db!);

    await tester.tap(find.text('A Dream Within a Dream'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Favourite'));
    await settle(tester);
    final favs = await tester.runAsync(() => repoFor(db).favorites());
    expect([for (final f in favs!) f.work.title], ['A Dream Within a Dream']);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    await tester.tap(find.text('Library'));
    await settle(tester);
    await tester.tap(find.text('SAVED'));
    await settle(tester);
    expect(find.text('POEM  ·  NIGHT 1'), findsOneWidget);
    expect(find.text('A Dream Within a Dream'), findsOneWidget);

    // a saved piece opens in the reader
    await tester.tap(find.text('A Dream Within a Dream'));
    await settle(tester);
    expect(find.text('A DREAM WITHIN A DREAM'), findsOneWidget);

    await tearDownApp(tester, db);
  });
}
