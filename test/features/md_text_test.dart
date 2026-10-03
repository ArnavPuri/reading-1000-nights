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
}
