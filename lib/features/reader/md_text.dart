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

  static final _letter = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);

  static bool _isSpace(String c) => c == ' ' || c == '\n';

  /// Letters and digits, plus an apostrophe or hyphen between two of them.
  bool _isWordChar(int i) {
    final c = plain[i];
    if (_letter.hasMatch(c)) return true;
    if (!"'’-".contains(c) || i == 0 || i == plain.length - 1) return false;
    return _letter.hasMatch(plain[i - 1]) && _letter.hasMatch(plain[i + 1]);
  }

  /// The word at [index], the unit a selection grows by: a run of word chars,
  /// or a single punctuation mark. On a space, the word before it (or after
  /// it at the start of the block).
  (int, int) wordAt(int index) {
    final s = plain;
    if (s.isEmpty) return (0, 0);
    var i = index.clamp(0, s.length - 1);
    if (_isSpace(s[i])) {
      var j = i;
      while (j > 0 && _isSpace(s[j])) {
        j--;
      }
      while (j < s.length - 1 && _isSpace(s[j])) {
        j++;
      }
      if (_isSpace(s[j])) return (i, i);
      i = j;
    }
    if (!_isWordChar(i)) return (i, i + 1);
    var a = i, b = i + 1;
    while (a > 0 && _isWordChar(a - 1)) {
      a--;
    }
    while (b < s.length && _isWordChar(b)) {
      b++;
    }
    return (a, b);
  }

  /// A selection start at caret [i], snapped: past any spaces, then back to
  /// the start of the word the caret is inside.
  int snapStart(int i) {
    final s = plain;
    i = i.clamp(0, s.length);
    while (i < s.length && _isSpace(s[i])) {
      i++;
    }
    if (i < s.length) {
      final (a, _) = wordAt(i);
      if (a < i) i = a;
    }
    return i;
  }

  /// A selection end at caret [i], snapped: back over any spaces, then on to
  /// the end of the word the caret is inside.
  int snapEnd(int i) {
    final s = plain;
    i = i.clamp(0, s.length);
    while (i > 0 && _isSpace(s[i - 1])) {
      i--;
    }
    if (i > 0) {
      final (_, b) = wordAt(i - 1);
      if (b > i) i = b;
    }
    return i;
  }
}

/// A work's blocks, for ranges that cross them. A position is a block index
/// and a plain index in it; a range is a pair of text_md offsets.
extension MdBlocks on List<MdBlock> {
  /// The text_md offset where a selection starting at caret [i] of block [b]
  /// begins. A start at the very end of a block moves to the next one.
  int snapStart(int b, int i) {
    final p = this[b].snapStart(i);
    if (p >= this[b].plain.length && b + 1 < length) return this[b + 1].mdOffsetOf(this[b + 1].snapStart(0));
    return this[b].mdOffsetOf(p);
  }

  /// The text_md offset where a selection ending at caret [i] of block [b]
  /// ends. An end at the very start of a block moves back to the one before.
  int snapEnd(int b, int i) {
    final p = this[b].snapEnd(i);
    if (p == 0 && b > 0) return this[b - 1].mdOffsetOf(this[b - 1].snapEnd(this[b - 1].plain.length));
    return this[b].mdOffsetOf(p);
  }

  /// The word at plain [i] of block [b], as a text_md range.
  (int, int) wordRange(int b, int i) {
    final (s, e) = this[b].wordAt(i);
    return (this[b].mdOffsetOf(s), this[b].mdOffsetOf(e));
  }

  /// The position a range starting at [md] starts from. An offset between
  /// blocks belongs to the next block.
  (int, int) startOf(int md) {
    for (var b = 0; b < length; b++) {
      if (md < this[b].mdEnd) return (b, this[b].plainIndexOf(md));
    }
    return (length - 1, last.plain.length);
  }

  /// The position a range ending at [md] ends at. An offset between blocks
  /// belongs to the block before.
  (int, int) endOf(int md) {
    for (var b = length - 1; b >= 0; b--) {
      if (md > this[b].mdStart) return (b, this[b].plainIndexOf(md));
    }
    return (0, 0);
  }

  /// The plain text of a range, paragraphs separated by a blank line.
  String textOf(int mdStart, int mdEnd) => [
    for (final b in this)
      if (b.plainRangeOf(mdStart, mdEnd) case (final s, final e)) b.plain.substring(s, e),
  ].join('\n\n');
}

/// A stored highlight's range, for [mergeHighlight].
typedef StoredRange = ({int id, int start, int end});

/// Folds a new highlight [start, end) together with every stored one it
/// overlaps or touches, so they are kept as one. [replacing] is a stored
/// highlight being resized: it goes, but does not widen the result.
({int start, int end, List<int> remove}) mergeHighlight(
  int start,
  int end,
  Iterable<StoredRange> stored, {
  int? replacing,
}) {
  final rest = stored.where((h) => h.id != replacing).toList();
  final remove = <int>[if (replacing != null && rest.length < stored.length) replacing];
  // Growing into one highlight can reach the next, so repeat until stable.
  for (var grew = true; grew;) {
    grew = false;
    for (final h in [...rest]) {
      if (h.start <= end && h.end >= start) {
        if (h.start < start) start = h.start;
        if (h.end > end) end = h.end;
        remove.add(h.id);
        rest.remove(h);
        grew = true;
      }
    }
  }
  return (start: start, end: end, remove: remove);
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
