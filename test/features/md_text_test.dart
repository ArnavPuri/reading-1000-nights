import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/features/reader/md_text.dart';

void main() {
  test('splits blocks and strips italics, keeping offsets into the markdown', () {
    const md = 'First *italic* words.\n\nSecond block.\n';
    final blocks = parseMarkdown(md, verse: false);
    expect(blocks.map((b) => b.plain), ['First italic words.', 'Second block.']);
    final b = blocks.first;
    expect(b.italicAt(6), isTrue);
    expect(b.italicAt(0), isFalse);
    // 'italic' starts at md offset 7 (after the asterisk)
    expect(b.mdOffsetOf(6), 7);
    expect(md.substring(blocks[1].mdStart, blocks[1].mdEnd), 'Second block.');
  });

  test('verse keeps line breaks', () {
    final b = parseMarkdown('Hope is the thing\nWith feathers', verse: true).single;
    expect(b.plain, 'Hope is the thing\nWith feathers');
  });

  test('sentenceAt finds the sentence under the finger, with closing quotes', () {
    final b = parseMarkdown(
      '“No red rose!” he cried. “Ah, on what little things does happiness depend!” Then silence.',
      verse: false,
    ).single;
    final i = b.plain.indexOf('little');
    final (s, e) = b.sentenceAt(i);
    expect(b.plain.substring(s, e), '“Ah, on what little things does happiness depend!”');
  });

  test('plainRangeOf maps a stored highlight back onto the block', () {
    const md = 'One. Two *three* four.';
    final b = parseMarkdown(md, verse: false).single;
    final (s, e) = b.sentenceAt(b.plain.indexOf('three'));
    final range = b.plainRangeOf(b.mdOffsetOf(s), b.mdOffsetOf(e));
    expect(b.plain.substring(range!.$1, range.$2), 'Two three four.');
  });

  group('selection', () {
    const md = '“No *red* rose!” he cried. It’s well-known.\n\nFrom her nest the Nightingale heard him.\n\nThe end.';
    final blocks = parseMarkdown(md, verse: false);
    String plain(int b, (int, int) r) => blocks[b].plain.substring(r.$1, r.$2);

    test('wordAt: words keep inner apostrophes and hyphens; punctuation stands alone', () {
      final b = blocks.first;
      expect(plain(0, b.wordAt(b.plain.indexOf('ell-'))), 'well-known');
      expect(plain(0, b.wordAt(b.plain.indexOf('t’s'))), 'It’s');
      expect(plain(0, b.wordAt(0)), '“');
      expect(plain(0, b.wordAt(b.plain.indexOf('!'))), '!');
      // on a space: the word before it
      expect(plain(0, b.wordAt(b.plain.indexOf(' he'))), '”');
    });

    test('snapStart and snapEnd move to word edges and past spaces', () {
      final b = blocks.first;
      final rose = b.plain.indexOf('rose');
      expect(b.snapStart(rose + 2), rose);
      expect(b.snapEnd(rose + 2), rose + 4);
      expect(b.snapStart(rose - 1), rose); // on the space before
      expect(b.snapEnd(rose), rose - 1); // back over the space
    });

    test('a range across blocks maps back onto each block, partial at both ends', () {
      final start = blocks.snapStart(0, blocks[0].plain.indexOf('well'));
      final end = blocks.snapEnd(1, blocks[1].plain.indexOf('Nightingale') + 3);
      expect(md.substring(start, end), 'well-known.\n\nFrom her nest the Nightingale');
      expect(blocks[0].plainRangeOf(start, end), (blocks[0].plain.indexOf('well'), blocks[0].plain.length));
      expect(blocks[1].plainRangeOf(start, end), (0, blocks[1].plain.indexOf(' heard')));
      expect(blocks[2].plainRangeOf(start, end), isNull);
      expect(blocks.textOf(start, end), 'well-known.\n\nFrom her nest the Nightingale');
    });

    test('italic markers stay out of the text and round-trip through offsets', () {
      final (s, e) = blocks.wordRange(0, blocks[0].plain.indexOf('red'));
      expect(md.substring(s, e), 'red*');
      expect(blocks.textOf(s, e), 'red');
      expect(blocks.startOf(s), (0, blocks[0].plain.indexOf('red')));
      expect(blocks.endOf(e), (0, blocks[0].plain.indexOf(' rose')));
    });

    test('edges at a block boundary belong to the text they touch', () {
      // a start at the very end of a block moves to the next block
      expect(blocks.snapStart(0, blocks[0].plain.length), blocks[1].mdStart);
      // an end at the very start of a block moves back to the one before
      expect(blocks.snapEnd(1, 0), blocks[0].mdEnd);
      // an offset in the blank line between blocks
      final gap = blocks[0].mdEnd + 1;
      expect(blocks.startOf(gap), (1, 0));
      expect(blocks.endOf(gap), (0, blocks[0].plain.length));
    });

    test('a drop-cap block split over two widgets still snaps whole words', () {
      // the cap shows “F”; the paragraph beside it starts at “rom”
      final b = blocks[1];
      expect(plain(1, b.wordAt(1)), 'From');
      expect(b.snapStart(1), 0);
      // a stored highlight starting at the cap overlaps the slice after it
      final r = b.plainRangeOf(b.mdStart, b.mdOffsetOf(4))!;
      expect((r.$1 < 1 ? 1 : r.$1, r.$2), (1, 4));
    });

    test('verse: line breaks are spaces to selection', () {
      final v = parseMarkdown('Hope is the thing\nWith feathers', verse: true).single;
      expect(v.snapEnd(v.plain.indexOf('With')), v.plain.indexOf('\n'));
      expect(v.snapStart(v.plain.indexOf('\n')), v.plain.indexOf('With'));
    });
  });

  group('mergeHighlight', () {
    test('a new range alone is kept as it is', () {
      final m = mergeHighlight(10, 20, [(id: 1, start: 30, end: 40)]);
      expect((m.start, m.end), (10, 20));
      expect(m.remove, isEmpty);
    });

    test('overlapping and touching highlights fold into one', () {
      final m = mergeHighlight(15, 32, [
        (id: 1, start: 10, end: 20),
        (id: 2, start: 32, end: 40),
        (id: 3, start: 50, end: 60),
      ]);
      expect((m.start, m.end), (10, 40));
      expect(m.remove, unorderedEquals([1, 2]));
    });

    test('growing into one highlight can reach the next', () {
      // legacy rows may overlap each other
      final m = mergeHighlight(0, 12, [(id: 1, start: 10, end: 25), (id: 2, start: 20, end: 30)]);
      expect((m.start, m.end), (0, 30));
      expect(m.remove, unorderedEquals([1, 2]));
    });

    test('a resized highlight is replaced, so it can shrink', () {
      final m = mergeHighlight(12, 18, [(id: 1, start: 10, end: 25)], replacing: 1);
      expect((m.start, m.end), (12, 18));
      expect(m.remove, [1]);
    });
  });
}
