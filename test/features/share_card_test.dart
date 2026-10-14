import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/theme.dart';
import 'package:thousand_nights/features/share/share_card.dart';

import '../app_harness.dart';

/// Renders [data] alone at the card's own size, 360 x 450.
Future<void> _pumpCard(WidgetTester tester, ShareCardData data) async {
  tester.view.physicalSize = const Size(1080, 1350);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.runAsync(loadAppFonts);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Center(child: ShareCard(data)),
    ),
  );
  final image = data.imagePath;
  if (image != null) {
    await tester.runAsync(() => precacheImage(AssetImage(image), tester.element(find.byType(ShareCard))));
  }
  await settle(tester);
  expect(tester.getSize(find.byType(ShareCard)), ShareCard.size);
}

void main() {
  testWidgets('highlight card: quote, attribution, night and footer', (tester) async {
    await _pumpCard(
      tester,
      const HighlightShare(
        dayNumber: 12,
        quote: '“Ah, on what little things does happiness depend!',
        title: 'The Nightingale and the Rose',
        author: 'Oscar Wilde',
        imagePath: 'assets/packs/pack-001/images/rose.webp',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Ah, on what little things does happiness depend!'), findsOneWidget);
    expect(find.text('NIGHT 12 OF 1000'), findsOneWidget);
    expect(find.textContaining('OSCAR WILDE'), findsOneWidget);
    expect(find.text(ShareBrand.name.toUpperCase()), findsOneWidget);
    expect(find.text(ShareBrand.tagline), findsOneWidget);
  });

  testWidgets('highlight card shrinks a long quote, and copes without an image', (tester) async {
    await _pumpCard(
      tester,
      HighlightShare(
        dayNumber: 3,
        quote: List.filled(40, 'Night after night have I sung of him, though I knew him not.').join(' '),
        title: 'A title long enough that it cannot share one line with its author',
        author: 'Somebody Wordy',
      ),
    );
    expect(tester.takeException(), isNull);
    final quote = tester.widget<Text>(find.textContaining('Night after night'));
    expect(quote.style!.fontSize, lessThan(25));
    expect(quote.overflow, TextOverflow.ellipsis);
    expect(quote.maxLines, lessThanOrEqualTo(8));
  });

  testWidgets('night card: candle, title, pull quote and three titles', (tester) async {
    await _pumpCard(
      tester,
      const NightShare(
        dayNumber: 7,
        titles: ['Kew Gardens', 'The Chariot', 'On Noise'],
        quote: 'Because I could not stop for Death, he kindly stopped for me.',
        quoteAuthor: 'Emily Dickinson',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Night 7 complete'), findsOneWidget);
    expect(find.text('EMILY DICKINSON'), findsOneWidget);
    expect(find.text('On Noise'), findsOneWidget);
  });

  testWidgets('milestone card: figure, name and stats', (tester) async {
    for (final m in [7, 30, 100, 365, 1000]) {
      await _pumpCard(tester, MilestoneShare(milestone: m, nightsCompleted: m, streak: 12, longestStreak: 40));
      expect(tester.takeException(), isNull);
      expect(find.text('Night $m'), findsOneWidget);
    }
    expect(find.text('THE THOUSAND'), findsOneWidget);
    expect(find.text('LONGEST'), findsOneWidget);
  });

  test('stripOuterQuotes drops quote marks around a sentence but keeps inner ones', () {
    expect(
      stripOuterQuotes('“Ah, on what little things does happiness depend!'),
      'Ah, on what little things does happiness depend!',
    );
    expect(stripOuterQuotes('made wretched.”'), 'made wretched.');
    expect(stripOuterQuotes('‘Hope is the thing with feathers.’'), 'Hope is the thing with feathers.');
    expect(stripOuterQuotes('“No red rose!” he cried.'), '“No red rose!” he cried.');
    expect(stripOuterQuotes('the Student’s sorrow.'), 'the Student’s sorrow.');
  });
}
