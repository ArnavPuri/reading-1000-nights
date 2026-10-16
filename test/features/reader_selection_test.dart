import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/data/database.dart';

import '../app_harness.dart';
import '../helpers.dart';

const _id = 'wilde-the-nightingale-and-the-rose';

/// Global centre of [word] where it appears inside [phrase] in the reader.
Offset _at(WidgetTester tester, String phrase, [String? word]) {
  word ??= phrase;
  final finder = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(phrase));
  final rp = tester.renderObject<RenderParagraph>(finder.first);
  final i = rp.text.toPlainText().indexOf(phrase) + phrase.indexOf(word);
  final box = rp.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + word.length)).first;
  return rp.localToGlobal(box.toRect().center);
}

final _startHandle = find.byKey(const ValueKey('reader-selection-start-handle'));
final _endHandle = find.byKey(const ValueKey('reader-selection-end-handle'));

Future<(AppDatabase, String)> _open(WidgetTester tester) async {
  usePhoneSize(tester);
  await tester.runAsync(loadAppFonts);
  final db = (await tester.runAsync(seededDb))!;
  final md = (await tester.runAsync(() async {
    await repoFor(db).ensureToday(testToday);
    return (await repoFor(db).work(_id)).textMd;
  }))!;
  await pumpApp(tester, db, location: '/read/1/$_id');
  return (db, md);
}

Future<List<Highlight>> _stored(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => repoFor(db).highlightsFor(_id)))!;

void main() {
  testWidgets('long-press, drag the end handle into the next paragraph, Highlight; tap it, Remove', (tester) async {
    final (db, md) = await _open(tester);

    // long-press a word beside the drop cap: that word, two handles, a menu
    await tester.longPressAt(_at(tester, 'the young Student', 'young'));
    await settle(tester);
    expect(_startHandle, findsOneWidget);
    expect(_endHandle, findsOneWidget);
    expect(find.bySemanticsLabel('Highlight'), findsOneWidget);
    expect(find.bySemanticsLabel('Copy'), findsOneWidget);
    expect(find.bySemanticsLabel('Share'), findsOneWidget);

    // drag the end handle onto "Nightingale" in the second paragraph
    final from = tester.getCenter(_endHandle);
    await tester.timedDragFrom(
      from,
      _at(tester, 'the Nightingale heard', 'Nightingale') - from,
      const Duration(milliseconds: 400),
    );
    await settle(tester);
    // the start handle stayed put
    expect(tester.getCenter(_startHandle).dx, closeTo(_at(tester, 'the young Student', 'young').dx - 17, 20));

    await tester.tap(find.bySemanticsLabel('Highlight'));
    await settle(tester);
    expect(_startHandle, findsNothing);
    expect(find.text('Highlight saved to your Library'), findsOneWidget);

    final h = (await _stored(tester, db)).single;
    expect(h.startOffset, md.indexOf('young Student'));
    expect(h.endOffset, md.indexOf('Nightingale heard') + 'Nightingale'.length);
    expect(
      h.body,
      'young Student; “but in all my garden there is no red rose.”\n\nFrom her nest in the holm-oak tree the Nightingale',
    );

    // a tap on the highlight selects it, with Remove
    await tester.tapAt(_at(tester, 'From her nest', 'nest'));
    await settle(tester);
    expect(_endHandle, findsOneWidget);
    expect(find.bySemanticsLabel('Remove'), findsOneWidget);
    expect(find.bySemanticsLabel('Highlight'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Remove'));
    await settle(tester);
    expect(await _stored(tester, db), isEmpty);
    expect(_endHandle, findsNothing);

    await tearDownApp(tester, db);
  });

  testWidgets('a highlight that overlaps a stored one merges with it; a tap elsewhere dismisses', (tester) async {
    final (db, md) = await _open(tester);
    const sentence = 'Ah, on what little things does happiness depend!';
    final s = md.indexOf(sentence);
    await tester.runAsync(() => repoFor(db).addHighlight(_id, s, s + sentence.length, sentence));
    await settle(tester);

    // a tap on other text dismisses a selection
    await tester.longPressAt(_at(tester, 'his beautiful eyes', 'beautiful'));
    await settle(tester);
    expect(find.bySemanticsLabel('Highlight'), findsOneWidget);
    await tester.tapAt(_at(tester, 'From her nest', 'nest'));
    await settle(tester);
    expect(_endHandle, findsNothing);

    // select "beautiful" and drag the end into the stored sentence
    await tester.longPressAt(_at(tester, 'his beautiful eyes', 'beautiful'));
    await settle(tester);
    final from = tester.getCenter(_endHandle);
    await tester.timedDragFrom(from, _at(tester, 'little things', 'little') - from, const Duration(milliseconds: 400));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Highlight'));
    await settle(tester);

    final h = (await _stored(tester, db)).single;
    expect(h.startOffset, md.indexOf('beautiful eyes'));
    expect(h.endOffset, s + sentence.length);
    expect(h.body, 'beautiful eyes filled with tears. “$sentence');

    // Copy puts the selection on the clipboard
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    await tester.longPressAt(_at(tester, 'From her nest', 'nest'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settle(tester);
    expect(copied, 'nest');
    expect(_endHandle, findsNothing);

    await tearDownApp(tester, db);
  });

  testWidgets('VoiceOver: each paragraph can be highlighted with a custom action', (tester) async {
    final semantics = tester.ensureSemantics();
    final (db, md) = await _open(tester);

    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('^From her nest')),
      const CustomSemanticsAction(label: 'Highlight paragraph'),
    );
    await settle(tester);
    final h = (await _stored(tester, db)).single;
    expect(
      h.body,
      'From her nest in the holm-oak tree the Nightingale heard him, and she looked out through the leaves, '
      'and wondered.',
    );
    expect(md.substring(h.startOffset, h.endOffset), h.body);

    semantics.dispose();
    await tearDownApp(tester, db);
  });
}
