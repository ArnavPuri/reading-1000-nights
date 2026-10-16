import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/database.dart';
import 'md_text.dart';

/// One paragraph widget on screen: block [block], plain chars [from, to).
/// The drop-cap block is shown as two of these.
class ReaderSlice {
  ReaderSlice(this.block, this.from, this.to, this.key);

  int block;
  int from;
  int to;
  final GlobalKey key;

  RenderParagraph? get paragraph {
    final ro = key.currentContext?.findRenderObject();
    return ro is RenderParagraph && ro.attached && ro.hasSize ? ro : null;
  }
}

/// The reader's own text selection, iOS style: long-press a word, drag the
/// handles, word by word, across paragraphs.
///
/// Flutter's SelectionArea was the first choice. It reports offsets per
/// paragraph, but it cannot select a range from code (tapping a highlight
/// selects it), and its handles move by character with no haptics. So the
/// reader keeps the range itself, as text_md offsets, and maps fingers to
/// text with [RenderParagraph] directly.
class ReaderSelection extends ChangeNotifier {
  ReaderSelection({required this.scroll, required this.viewportKey});

  final ScrollController scroll;

  /// The scroll view: its box is what is on screen.
  final GlobalKey viewportKey;

  List<MdBlock> blocks = const [];

  /// Stored highlights of the work, kept current by the reader.
  List<Highlight> highlights = const [];

  final _slices = <ReaderSlice>[];

  (int, int)? _range;
  int? _highlightId;
  bool _changed = false;

  /// text_md offsets of the selection, or null when nothing is selected.
  (int, int)? get range => _range;

  /// The stored highlight this selection began from, if any. Dragging its
  /// handles resizes it.
  int? get highlightId => _highlightId;

  /// True while a stored highlight is selected as it is stored.
  bool get isStoredHighlight => _highlightId != null && !_changed;

  // ------------------------------------------------------------------------
  // Paragraphs
  // ------------------------------------------------------------------------

  ReaderSlice attach(int block, int from, int to, GlobalKey key) {
    final s = ReaderSlice(block, from, to, key);
    _slices.add(s);
    return s;
  }

  void detach(ReaderSlice s) => _slices.remove(s);

  // ------------------------------------------------------------------------
  // State
  // ------------------------------------------------------------------------

  void select(int start, int end, {int? highlightId}) {
    _range = (start, end);
    _highlightId = highlightId;
    _changed = false;
    notifyListeners();
  }

  void clear() {
    _stopDrag();
    if (_range == null) return;
    _range = null;
    _highlightId = null;
    notifyListeners();
  }

  /// Moves the selection, with a selection click when it changes.
  void _update(int start, int end) {
    if (_range == (start, end)) return;
    _range = (start, end);
    _changed = true;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  Highlight? _highlightAt(int md) {
    for (final h in highlights) {
      if (h.startOffset <= md && md < h.endOffset) return h;
    }
    return null;
  }

  // ------------------------------------------------------------------------
  // Geometry
  // ------------------------------------------------------------------------

  /// The text under [global]: the caret position nearest to it and the char
  /// it is on, if any. With [nearest], the closest paragraph when the point
  /// is between paragraphs.
  ({int block, int caret, int? char})? hitTest(Offset global, {bool nearest = false}) {
    ReaderSlice? best;
    RenderParagraph? bestP;
    var bestD = double.infinity;
    for (final s in _slices) {
      final p = s.paragraph;
      if (p == null || s.to <= s.from) continue;
      final y = p.globalToLocal(global).dy;
      final d = y < 0 ? -y : (y > p.size.height ? y - p.size.height : 0.0);
      if (d < bestD) {
        bestD = d;
        best = s;
        bestP = p;
      }
    }
    if (best == null || bestP == null || (!nearest && bestD > 0)) return null;
    final local = bestP.globalToLocal(global);
    final clamped = Offset(local.dx.clamp(0, bestP.size.width), local.dy.clamp(0, bestP.size.height - 0.5));
    final caret = bestP.getPositionForOffset(clamped).offset.clamp(0, best.to - best.from);
    int? char;
    for (final c in [caret, caret - 1]) {
      if (c < 0 || c >= best.to - best.from) continue;
      final boxes = bestP.getBoxesForSelection(
        TextSelection(baseOffset: c, extentOffset: c + 1),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      if (boxes.any((b) => b.toRect().contains(local))) {
        char = best.from + c;
        break;
      }
    }
    return (block: best.block, caret: best.from + caret, char: char);
  }

  /// The line box at one edge of the selection, as a zero-width rect in
  /// global coordinates: where a handle stands.
  Rect? edgeRect({required bool end}) {
    final r = _range;
    if (r == null || blocks.isEmpty) return null;
    final (b, i) = end ? blocks.endOf(r.$2) : blocks.startOf(r.$1);
    final ofBlock = [
      for (final s in _slices)
        if (s.block == b && s.to > s.from) s,
    ]..sort((x, y) => x.from.compareTo(y.from));
    if (ofBlock.isEmpty) return null;
    ReaderSlice? slice;
    var at = i;
    if (end) {
      for (final s in ofBlock.reversed) {
        if (s.from < i && i <= s.to) {
          slice = s;
          break;
        }
      }
      if (slice == null) {
        // In text that is not drawn (the drop cap's opening quote): the
        // nearest drawn char before it.
        slice = ofBlock.lastWhere((s) => s.to < i, orElse: () => ofBlock.first);
        at = i < slice.from ? slice.from + 1 : slice.to;
      }
    } else {
      for (final s in ofBlock) {
        if (s.from <= i && i < s.to) {
          slice = s;
          break;
        }
      }
      if (slice == null) {
        slice = ofBlock.firstWhere((s) => s.from > i, orElse: () => ofBlock.last);
        at = i > slice.to ? slice.to - 1 : slice.from;
      }
    }
    final p = slice.paragraph;
    if (p == null) return null;
    final local = at - slice.from;
    final boxes = p.getBoxesForSelection(
      end
          ? TextSelection(baseOffset: local - 1, extentOffset: local)
          : TextSelection(baseOffset: local, extentOffset: local + 1),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    if (boxes.isEmpty) return null;
    final box = end ? boxes.last : boxes.first;
    final x = end ? box.right : box.left;
    return MatrixUtils.transformRect(p.getTransformTo(null), Rect.fromLTRB(x, box.top, x, box.bottom));
  }

  /// The selected part of [slice], as boxes in its paragraph.
  List<TextBox> boxesIn(ReaderSlice slice) {
    final r = _range;
    if (r == null || slice.block >= blocks.length) return const [];
    final plain = blocks[slice.block].plainRangeOf(r.$1, r.$2);
    if (plain == null) return const [];
    final a = plain.$1 < slice.from ? slice.from : plain.$1;
    final b = plain.$2 > slice.to ? slice.to : plain.$2;
    final p = slice.paragraph;
    if (a >= b || p == null) return const [];
    return p.getBoxesForSelection(
      TextSelection(baseOffset: a - slice.from, extentOffset: b - slice.from),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
  }

  /// What is on screen, in global coordinates.
  Rect? get viewport {
    final box = viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Clears the selection once it has scrolled out of sight.
  void dismissIfOffscreen() {
    if (_range == null || dragging) return;
    final a = edgeRect(end: false), b = edgeRect(end: true), v = viewport;
    if (a == null || b == null || v == null) return;
    if (b.bottom < v.top || a.top > v.bottom) clear();
  }

  // ------------------------------------------------------------------------
  // Gestures
  // ------------------------------------------------------------------------

  /// A tap: selects the highlight under the finger, or clears the selection.
  void tap(Offset global) {
    final hit = hitTest(global);
    final char = hit?.char;
    final h = hit == null || char == null ? null : _highlightAt(blocks[hit.block].mdOffsetOf(char));
    if (h == null) {
      clear();
      return;
    }
    HapticFeedback.selectionClick();
    select(h.startOffset, h.endOffset, highlightId: h.id);
  }

  (int, int)? _anchor;

  /// Long-press: selects the word under the finger, or the highlight it is in.
  /// Returns false when there is no text there.
  bool longPressStart(Offset global) {
    final hit = hitTest(global);
    if (hit == null) return false;
    final block = blocks[hit.block];
    final char = (hit.char ?? hit.caret).clamp(0, block.plain.length - 1);
    HapticFeedback.selectionClick();
    final h = _highlightAt(block.mdOffsetOf(char));
    if (h != null) {
      _anchor = null;
      select(h.startOffset, h.endOffset, highlightId: h.id);
      return true;
    }
    final word = blocks.wordRange(hit.block, char);
    if (word.$2 <= word.$1) return false;
    _anchor = word;
    select(word.$1, word.$2);
    _startDrag(end: true, point: global);
    return true;
  }

  /// Sliding after a long-press grows the selection word by word.
  void longPressMove(Offset global) {
    final anchor = _anchor;
    if (anchor == null || _range == null) return;
    _dragPoint = global;
    _dragTo(global);
    _autoScroll();
    notifyListeners();
  }

  void longPressEnd() {
    _anchor = null;
    _stopDrag();
  }

  // Handles ------------------------------------------------------------------

  bool _dragEnd = true;
  Offset? _dragPoint;
  Timer? _scrollTimer;

  bool get dragging => _dragPoint != null;

  /// Where the finger is while dragging, for the magnifier, and which edge
  /// it moves.
  Offset? get dragPoint => _dragPoint;
  bool get draggingEnd => _dragEnd;

  void _startDrag({required bool end, required Offset point}) {
    _dragEnd = end;
    _dragPoint = point;
    notifyListeners();
  }

  void _stopDrag() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (_dragPoint == null) return;
    _dragPoint = null;
    notifyListeners();
  }

  void handleDragStart({required bool end}) {
    final edge = edgeRect(end: end);
    if (edge == null) return;
    _anchor = null;
    _startDrag(end: end, point: edge.center);
  }

  /// The drag point starts at the middle of the edge's line and moves with
  /// the finger, so the text under the finger is not covered by the handle.
  void handleDragUpdate(Offset delta) {
    final p = _dragPoint;
    if (p == null) return;
    _dragPoint = p + delta;
    _dragTo(_dragPoint!);
    _autoScroll();
    notifyListeners();
  }

  void handleDragEnd() => _stopDrag();

  void _dragTo(Offset global) {
    final r = _range;
    final hit = hitTest(global, nearest: true);
    if (r == null || hit == null) return;
    final anchor = _anchor;
    if (anchor != null) {
      final word = blocks.wordRange(hit.block, (hit.char ?? hit.caret).clamp(0, blocks[hit.block].plain.length - 1));
      _dragEnd = word.$1 >= anchor.$1;
      _update(word.$1 < anchor.$1 ? word.$1 : anchor.$1, word.$2 > anchor.$2 ? word.$2 : anchor.$2);
      return;
    }
    if (_dragEnd) {
      var end = blocks.snapEnd(hit.block, hit.caret);
      if (end <= r.$1) {
        // the handles do not cross: keep at least the first word
        final (b, i) = blocks.startOf(r.$1);
        end = blocks.wordRange(b, i).$2;
      }
      if (end > r.$1) _update(r.$1, end);
    } else {
      var start = blocks.snapStart(hit.block, hit.caret);
      if (start >= r.$2) {
        final (b, i) = blocks.endOf(r.$2);
        start = blocks.wordRange(b, i - 1).$1;
      }
      if (start < r.$2) _update(start, r.$2);
    }
  }

  /// Scrolls while the finger rests near the top or bottom of the screen.
  void _autoScroll() {
    if (_scrollStep() == 0) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
      return;
    }
    _scrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final step = _scrollStep();
      if (step == 0 || !scroll.hasClients) return;
      final pos = scroll.position;
      final to = (pos.pixels + step).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (to == pos.pixels) return;
      scroll.jumpTo(to);
      // the text moved under the finger
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dragPoint != null) _dragTo(_dragPoint!);
      });
    });
  }

  double _scrollStep() {
    final v = viewport, p = _dragPoint;
    if (v == null || p == null) return 0;
    const zone = 44.0;
    return p.dy < v.top + zone ? -10 : (p.dy > v.bottom - zone ? 10 : 0);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }
}

/// Paints the selected part of one paragraph, behind its text.
class SelectionPainter extends CustomPainter {
  SelectionPainter(this.selection, this.slice, this.color) : super(repaint: selection);

  final ReaderSelection selection;
  final ReaderSlice slice;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final b in selection.boxesIn(slice)) {
      canvas.drawRect(b.toRect(), paint);
    }
  }

  @override
  bool shouldRepaint(SelectionPainter old) => old.slice != slice || old.color != color;
}

/// One menu action.
typedef SelectionAction = ({String label, VoidCallback onTap});

/// Handles, magnifier and menu, over the reader's text. Lives in the
/// scrolling content so it moves with the text, and positions itself from
/// the paragraphs' layout.
class ReaderSelectionOverlay extends StatelessWidget {
  const ReaderSelectionOverlay({
    super.key,
    required this.selection,
    required this.color,
    required this.textInsets,
    required this.actions,
  });

  final ReaderSelection selection;
  final Color color;

  /// The padding around the text column, to centre the menu over it.
  final EdgeInsets textInsets;

  /// The menu for the current selection.
  final List<SelectionAction> Function() actions;

  static const _knob = 11.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([selection, selection.scroll]),
      builder: (context, _) {
        final box = context.findRenderObject();
        final a = selection.edgeRect(end: false), b = selection.edgeRect(end: true);
        if (selection.range == null || a == null || b == null || box is! RenderBox || !box.hasSize) {
          return const SizedBox.expand();
        }
        Rect local(Rect r) => MatrixUtils.transformRect(box.getTransformTo(null)..invert(), r);
        final start = local(a), end = local(b);
        final v = selection.viewport;
        final visible = v == null ? Offset.zero & box.size : local(v);
        final oneLine = (start.top - end.top).abs() < 1;
        final centerX = oneLine
            ? (start.left + end.right) / 2
            : (textInsets.left + box.size.width - textInsets.right) / 2;
        final drag = selection.dragPoint;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _handle(start, end: false),
            _handle(end, end: true),
            if (drag == null)
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _MenuLayout(
                    centerX: centerX,
                    above: start.top - _knob - 8,
                    below: end.bottom + _knob + 8,
                    visibleTop: visible.top + 8,
                    visibleBottom: visible.bottom - 8,
                  ),
                  child: _SelectionMenu(actions: actions()),
                ),
              )
            else
              _magnifier(box.globalToLocal(drag), selection.draggingEnd ? end : start, box.size.width),
          ],
        );
      },
    );
  }

  Widget _handle(Rect edge, {required bool end}) {
    const w = 44.0, pad = _knob + 12;
    return Positioned(
      key: ValueKey(end ? 'reader-selection-end-handle' : 'reader-selection-start-handle'),
      left: edge.left - w / 2,
      top: edge.top - pad,
      width: w,
      height: edge.height + pad * 2,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _EagerPanRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
            _EagerPanRecognizer.new,
            (r) => r
              ..onStart = ((_) => selection.handleDragStart(end: end))
              ..onUpdate = ((d) => selection.handleDragUpdate(d.delta))
              ..onEnd = ((_) => selection.handleDragEnd())
              ..onCancel = selection.handleDragEnd,
          ),
        },
        child: CustomPaint(
          painter: _HandlePainter(color: color, end: end, pad: pad, knob: _knob),
        ),
      ),
    );
  }

  /// A loupe above the line being dragged, as on iOS.
  Widget _magnifier(Offset finger, Rect line, double width) {
    const size = Size(96, 44);
    final x = finger.dx.clamp(size.width / 2, width - size.width / 2);
    final center = Offset(x, line.top - _knob - 10 - size.height / 2);
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      child: IgnorePointer(
        child: RawMagnifier(
          size: size,
          magnificationScale: 1.25,
          focalPointOffset: Offset(finger.dx - x, line.center.dy - center.dy),
          decoration: MagnifierDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Tokens.hairline),
            ),
            shadows: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 4))],
          ),
        ),
      ),
    );
  }
}

/// Wins the gesture arena on touch-down, so a handle drag never scrolls.
class _EagerPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// iOS handle: a thin bar the height of the line, with a round knob above
/// the start or below the end.
class _HandlePainter extends CustomPainter {
  _HandlePainter({required this.color, required this.end, required this.pad, required this.knob});

  final Color color;
  final bool end;
  final double pad;
  final double knob;

  @override
  void paint(Canvas canvas, Size size) {
    // the bar stands just outside the selection, clear of its first and last glyphs
    final x = size.width / 2 + (end ? 1 : -1);
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTRB(x - 1, pad, x + 1, size.height - pad), paint);
    final y = end ? size.height - pad + knob / 2 - 1 : pad - knob / 2 + 1;
    canvas.drawCircle(Offset(x, y), knob / 2, paint);
  }

  @override
  bool shouldRepaint(_HandlePainter old) => old.color != color || old.end != end;
}

/// Above the selection if there is room on screen, else below it, else at
/// the top of the screen.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({
    required this.centerX,
    required this.above,
    required this.below,
    required this.visibleTop,
    required this.visibleBottom,
  });

  final double centerX;
  final double above;
  final double below;
  final double visibleTop;
  final double visibleBottom;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (centerX - child.width / 2).clamp(8.0, (size.width - child.width - 8).clamp(8.0, double.infinity));
    final double y;
    if (above - child.height >= visibleTop) {
      y = above - child.height;
    } else if (below + child.height <= visibleBottom) {
      y = below;
    } else {
      y = visibleTop;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.centerX != centerX ||
      old.above != above ||
      old.below != below ||
      old.visibleTop != visibleTop ||
      old.visibleBottom != visibleBottom;
}

/// The edit menu: ink-raised, hairline border, parchment labels, the first
/// action in amber.
class _SelectionMenu extends StatelessWidget {
  const _SelectionMenu({required this.actions});

  final List<SelectionAction> actions;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // a long-press on the menu should not start a selection underneath
      onLongPress: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.inkRaised,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Tokens.hairline),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) VerticalDivider(width: 1, thickness: 1, color: Tokens.hairline),
                  Semantics(
                    button: true,
                    label: actions[i].label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: actions[i].onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
                        child: Text(
                          actions[i].label,
                          style: TextStyle(
                            fontFamily: Tokens.serif,
                            fontSize: 15.5,
                            height: 1.2,
                            color: i == 0 ? Tokens.amber : Tokens.parchment,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
