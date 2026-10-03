/// The small Markdown subset content packs use (see the pack format doc):
///
/// * blocks separated by a blank line;
/// * in verse, a single newline is a line break;
/// * `*text*` is italic.
///
/// Highlights are stored as offsets into `text_md`, so every block keeps a
/// map from its plain (rendered) characters back to Markdown offsets.
class MdBlock {
  MdBlock._(this.plain, this._italic, this._mdOffsets, this.verse);

  /// Rendered text, without Markdown markers.
  final String plain;
  final List<bool> _italic;

  /// For each plain char, its offset in text_md; one extra entry for the end.
  final List<int> _mdOffsets;
  final bool verse;

  int get mdStart => _mdOffsets.first;
  int get mdEnd => _mdOffsets.last;

  bool italicAt(int i) => _italic[i];
  int mdOffsetOf(int plainIndex) => _mdOffsets[plainIndex];

  /// Plain index of the first char at or after [mdOffset].
  int plainIndexOf(int mdOffset) {
    for (var i = 0; i < _mdOffsets.length; i++) {
      if (_mdOffsets[i] >= mdOffset) return i;
    }
    return plain.length;
  }

  /// Converts a text_md range to a plain range in this block, or null if it
  /// does not overlap.
  (int, int)? plainRangeOf(int mdStartOffset, int mdEndOffset) {
    if (mdEndOffset <= mdStart || mdStartOffset >= mdEnd) return null;
    final a = plainIndexOf(mdStartOffset);
    final b = plainIndexOf(mdEndOffset);
    return a < b ? (a, b) : null;
  }

  /// The sentence around [index]: from just after the previous terminator
  /// (or block start) through the next terminator and any closing quotes.
  (int, int) sentenceAt(int index) {
    final s = plain;
    if (s.isEmpty) return (0, 0);
    index = index.clamp(0, s.length - 1);
    bool isEnd(int i) => '.!?'.contains(s[i]);
    bool isCloser(int i) => '\u201d\u2019"\')'.contains(s[i]);
    bool isSpace(int i) => s[i] == ' ' || s[i] == '\n';

    // A sentence ends at a terminator, plus closing quotes, before a space.
    int? boundaryAfter(int i) {
      if (!isEnd(i)) return null;
      var j = i + 1;
      while (j < s.length && isCloser(j)) {
        j++;
      }
      return j >= s.length || isSpace(j) ? j : null;
    }

    var start = 0;
    for (var i = index - 1; i >= 0; i--) {
      final b = boundaryAfter(i);
      if (b != null && b <= index) {
        start = b;
        break;
      }
    }
    while (start < s.length && isSpace(start)) {
      start++;
    }

    var end = s.length;
    for (var i = index; i < s.length; i++) {
      final b = boundaryAfter(i);
      if (b != null) {
        end = b;
        break;
      }
    }
    return (start, end);
  }
}

List<MdBlock> parseMarkdown(String md, {required bool verse}) {
  final blocks = <MdBlock>[];
  var pos = 0;
  while (pos < md.length) {
    while (pos < md.length && md[pos] == '\n') {
      pos++;
    }
    if (pos >= md.length) break;
    var end = md.indexOf('\n\n', pos);
    if (end < 0) end = md.length;
    var blockEnd = end;
    while (blockEnd > pos && md[blockEnd - 1] == '\n') {
      blockEnd--;
    }

    final plain = StringBuffer();
    final italic = <bool>[];
    final offsets = <int>[];
    var inItalic = false;
    for (var i = pos; i < blockEnd; i++) {
      final c = md[i];
      if (c == '*') {
        inItalic = !inItalic;
        continue;
      }
      plain.write(c == '\n' && !verse ? ' ' : c);
      italic.add(inItalic);
      offsets.add(i);
    }
    offsets.add(blockEnd);
    blocks.add(MdBlock._(plain.toString(), italic, offsets, verse));
    pos = end;
  }
  return blocks;
}
