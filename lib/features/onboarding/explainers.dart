import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/candle.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/database.dart';
import '../journey/constellation.dart';
import '../tonight/reading_card.dart';
import 'stage.dart';

/// Small caps label and display title at the top of an onboarding page.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.label, required this.title, this.detail});

  final String label;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Reveal(
        at: ms(0),
        child: Text(label, style: TextStyles.label(color: Tokens.amber, size: 11.5)),
      ),
      const SizedBox(height: 14),
      Reveal(
        at: ms(120),
        child: Text(title, style: TextStyles.screenTitle.copyWith(fontSize: 36)),
      ),
      if (detail != null) ...[
        const SizedBox(height: 12),
        Reveal(
          at: ms(240),
          child: Text(detail!, style: TextStyles.byline.copyWith(fontSize: 17, height: 1.4)),
        ),
      ],
    ],
  );
}

// ---------------------------------------------------------------------------
// How a night works: the real card, annotated
// ---------------------------------------------------------------------------

/// Night 1's story on a real [ReadingCard], with four callouts that arrive
/// one after another: the type label, the read time, the engraving, and the
/// done check (the card dims and the amber check draws itself in).
class CardExplainer extends ConsumerWidget {
  const CardExplainer({super.key});

  static const length = Duration(milliseconds: 6400);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = ref.watch(nightProvider(1)).value?.pieces.first.work;
    return Stage(
      length: length,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(label: 'HOW A NIGHT WORKS', title: 'Three cards a night'),
            const Spacer(),
            if (work != null) _AnnotatedCard(work: work),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// One callout: when it starts, which side its caption sits on, and where
/// its leader meets the card.
class _Callout {
  const _Callout(this.at, this.caption, {required this.x, this.top, this.bottom, this.above = true});

  final Duration at;
  final String caption;

  /// Leader x, from the card's left edge (negative: from its right edge).
  final double x;

  /// Anchor y from the card's top or bottom edge.
  final double? top;
  final double? bottom;

  /// Caption row above the card (else below).
  final bool above;
}

class _AnnotatedCard extends StatelessWidget {
  const _AnnotatedCard({required this.work});

  final Work work;

  static const _row = 30.0;
  static const _gap = 16.0;
  static const _cardHeight = 200.0;

  // in the order they appear; rows are filled top to bottom
  static const _type = _Callout(
    Duration(milliseconds: 1400),
    'Story, poem, essay: about 20 minutes a night',
    x: 12,
    top: 30,
  );
  static const _time = _Callout(
    Duration(milliseconds: 2500),
    'How long this one takes',
    x: 12,
    bottom: 31,
    above: false,
  );
  static const _art = _Callout(
    Duration(milliseconds: 3600),
    'An engraving for every piece',
    x: -78,
    bottom: 56,
    above: false,
  );
  static const _done = _Callout(Duration(milliseconds: 4700), 'Finished pieces dim, with a check', x: -29, top: 16);

  @override
  Widget build(BuildContext context) {
    final dim = Stage.interval(context, _done.at, span: ms(1000));
    final check = Stage.interval(context, _done.at + ms(350), span: ms(900));
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        double x(_Callout k) => k.x >= 0 ? k.x : w + k.x;
        return Column(
          children: [
            _CaptionRow(callout: _type, x: x(_type), width: w),
            _CaptionRow(callout: _done, x: x(_done), width: w, alignRight: true),
            const SizedBox(height: _gap),
            Reveal(
              at: ms(350),
              child: SizedBox(
                height: _cardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: dim,
                      builder: (context, child) => Opacity(opacity: 1 - 0.45 * dim.value, child: child),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ReadingCard(work: work, done: false, onTap: () {}, minHeight: _cardHeight),
                          ),
                          Positioned(top: 16, right: 16, child: _DrawnCheck(progress: check)),
                        ],
                      ),
                    ),
                    // leaders from the caption rows to the card
                    for (final (k, row) in [(_type, 0), (_done, 1), (_time, 0), (_art, 1)])
                      _Leader(callout: k, x: x(k), reach: _gap + _row * (k.above ? 2 - row : row + 1) - _row / 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _gap),
            _CaptionRow(callout: _time, x: x(_time), width: w),
            _CaptionRow(callout: _art, x: x(_art), width: w, alignRight: true),
          ],
        );
      },
    );
  }
}

/// A caption with its amber marker, on one row above or below the card.
class _CaptionRow extends StatelessWidget {
  const _CaptionRow({required this.callout, required this.x, required this.width, this.alignRight = false});

  final _Callout callout;
  final double x;
  final double width;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final t = Stage.interval(context, callout.at + ms(380), span: ms(800));
    final text = Text(
      callout.caption,
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: const TextStyle(fontSize: 15.5, color: Tokens.parchment, height: 1.2),
    );
    return SizedBox(
      height: _AnnotatedCard._row,
      child: AnimatedBuilder(
        animation: t,
        builder: (context, child) => Opacity(opacity: t.value, child: child),
        child: Stack(
          children: [
            Positioned(left: x - 3.5, top: _AnnotatedCard._row / 2 - 3.5, child: const _Dot()),
            if (alignRight)
              Positioned(
                right: width - x + 14,
                top: 0,
                bottom: 0,
                child: Center(child: text),
              )
            else
              Positioned(
                left: x + 14,
                top: 0,
                bottom: 0,
                child: Center(child: text),
              ),
          ],
        ),
      ),
    );
  }
}

/// The hairline from a caption's marker to its anchor on the card, drawn
/// from the caption toward the card, ending in an amber dot.
class _Leader extends StatelessWidget {
  const _Leader({required this.callout, required this.x, required this.reach});

  final _Callout callout;
  final double x;

  /// From the card's edge out to the caption row's centre.
  final double reach;

  @override
  Widget build(BuildContext context) {
    final t = Stage.interval(context, callout.at, span: ms(700));
    final inset = callout.top ?? callout.bottom!;
    final length = reach + inset;
    final isCheck = identical(callout, _AnnotatedCard._done);
    return Positioned(
      left: x - 3.5,
      width: 7,
      top: callout.above ? -reach : null,
      bottom: callout.above ? null : -reach,
      height: length,
      child: AnimatedBuilder(
        animation: t,
        builder: (context, _) => CustomPaint(
          painter: _LeaderPainter(progress: t.value, fromTop: callout.above, dot: !isCheck),
        ),
      ),
    );
  }
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter({required this.progress, required this.fromTop, required this.dot});

  final double progress;
  final bool fromTop;
  final bool dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final x = size.width / 2;
    final start = fromTop ? 0.0 : size.height;
    final end = fromTop ? size.height : 0.0;
    final y = start + (end - start) * progress;
    canvas.drawLine(
      Offset(x, start),
      Offset(x, y),
      Paint()
        ..color = Tokens.amber.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );
    if (dot && progress > 0.85) {
      final a = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, end), 5.5, Paint()..color = Tokens.ink.withValues(alpha: 0.7 * a));
      canvas.drawCircle(Offset(x, end), 3.5, Paint()..color = Tokens.amber.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => old.progress != progress;
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Tokens.amber),
  );
}

/// The card's done check, with its stroke drawn in.
class _DrawnCheck extends StatelessWidget {
  const _DrawnCheck({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) => Opacity(
      opacity: progress.value.clamp(0.0, 1.0),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Tokens.ink.withValues(alpha: 0.7),
          border: Border.all(color: Tokens.amber, width: 1.2),
        ),
        padding: const EdgeInsets.all(5),
        child: CustomPaint(painter: _CheckPainter(progress.value)),
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * .2, s * .52)
      ..lineTo(s * .42, s * .74)
      ..lineTo(s * .82, s * .28);
    final paint = Paint()
      ..color = Tokens.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = s / 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// In the reader
// ---------------------------------------------------------------------------

/// The reader's features, one line each, under a small page of night 1's
/// story with a highlight, the ribbon and the bookmark.
class ReaderExplainer extends StatelessWidget {
  const ReaderExplainer({super.key});

  static const length = Duration(milliseconds: 3600);

  @override
  Widget build(BuildContext context) {
    final features = <(Widget, String)>[
      (LineIconView(LineIcon.book, size: 20, color: Tokens.amber), 'Tap a card to read it.'),
      (const _RibbonGlyph(), 'The amber ribbon shows how far you are.'),
      (const _HighlightGlyph(), 'Long-press a line to highlight it.'),
      (LineIconView(LineIcon.bookmark, size: 19, color: Tokens.amber), 'The ribbon bookmark saves a piece.'),
      (const Candle(height: 22), '“Finish” lights tonight’s candle.'),
    ];
    return Stage(
      length: length,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(label: 'IN THE READER', title: 'Read at your pace'),
            const Spacer(),
            Reveal(at: ms(300), child: const _MiniReader()),
            const SizedBox(height: 30),
            for (var i = 0; i < features.length; i++)
              Reveal(
                at: ms(900 + i * 380),
                child: SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Center(child: features[i].$1)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          features[i].$2,
                          style: const TextStyle(fontSize: 17, color: Tokens.parchment, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _RibbonGlyph extends StatelessWidget {
  const _RibbonGlyph();

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 8, height: 24, child: CustomPaint(painter: _RibbonPainter(0.55)));
}

class _HighlightGlyph extends StatelessWidget {
  const _HighlightGlyph();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 14,
    decoration: BoxDecoration(color: Tokens.amber.withValues(alpha: 0.32), borderRadius: BorderRadius.circular(3)),
  );
}

/// The reader's ribbon: a faint line, filled in amber to [value].
class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final y = size.height * value;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Tokens.amber.withValues(alpha: 0.28)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, y),
      Paint()
        ..color = Tokens.amber
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = Tokens.amber);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.value != value;
}

/// A few lines of the reader, small: the bookmark and "Aa" up top, the
/// title in small caps, a highlighted sentence and the ribbon.
class _MiniReader extends StatelessWidget {
  const _MiniReader();

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontFamily: Tokens.serif, fontSize: 15.5, height: 1.55, color: Tokens.parchment);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 18),
      decoration: BoxDecoration(
        color: Tokens.ink,
        borderRadius: BorderRadius.circular(Tokens.cardRadius),
        border: Border.all(color: Tokens.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    LineIconView(LineIcon.back, size: 16, color: Tokens.parchmentDim),
                    const Spacer(),
                    const LineIconView(LineIcon.bookmark, size: 17, color: Tokens.amber, filled: true),
                    const SizedBox(width: 16),
                    Text('Aa', style: TextStyle(fontSize: 17, color: Tokens.parchmentDim)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('THE NIGHTINGALE AND THE ROSE', style: TextStyles.label(color: Tokens.parchmentDim, size: 9.5)),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: body,
                    children: [
                      const TextSpan(text: '‘No red rose in all my garden!’ he cried, and his beautiful eyes filled '),
                      const TextSpan(text: 'with tears. '),
                      TextSpan(
                        text: '‘Ah, on what little things does happiness depend!’',
                        style: TextStyle(backgroundColor: Tokens.highlight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 8,
            height: 132,
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: CustomPaint(painter: _RibbonPainter(0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Your candle and constellation
// ---------------------------------------------------------------------------

/// The streak candle counting up as the first week's stars light, one per
/// night, then the milestones along the way.
class JourneyExplainer extends StatelessWidget {
  const JourneyExplainer({super.key});

  static const length = Duration(milliseconds: 5200);
  static const _lighting = Duration(milliseconds: 800);
  static const _lit = Duration(milliseconds: 3200);

  @override
  Widget build(BuildContext context) {
    return Stage(
      length: length,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(label: 'YOUR CANDLE AND STARS', title: 'A star for every night'),
            const Spacer(),
            Reveal(
              at: ms(400),
              child: SizedBox(
                height: 200,
                child: Builder(
                  builder: (context) {
                    final t = Stage.interval(context, _lighting, span: _lit);
                    return AnimatedBuilder(
                      animation: t,
                      builder: (context, _) {
                        final lit = (t.value * 7).clamp(0.0, 7.0);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Candle(height: 76, flicker: true),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${lit.ceil().clamp(1, 7)}',
                                      style: const TextStyle(
                                        fontFamily: Tokens.display,
                                        fontSize: 44,
                                        height: 1,
                                        color: Tokens.amber,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text('DAY STREAK', style: TextStyles.label(color: Tokens.parchmentDim, size: 10)),
                              ],
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: CustomPaint(painter: _FirstWeekPainter(lit), size: Size.infinite),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            Reveal(at: ms(1000), child: const _Line('The candle counts the nights in a row.')),
            Reveal(at: ms(1300), child: const _Line('Each night you read lights a star on Journey.')),
            const SizedBox(height: 22),
            Reveal(at: ms(3600), child: const _Milestones()),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 17, color: Tokens.parchment, height: 1.35)),
  );
}

/// 7 · 30 · 100 · 365 · 1000 on a dotted hairline.
class _Milestones extends StatelessWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('MILESTONES', style: TextStyles.label(color: Tokens.amber, size: 10.5)),
      const SizedBox(height: 12),
      SizedBox(
        height: 46,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              right: 8,
              top: 7,
              child: CustomPaint(size: const Size.fromHeight(1), painter: _DottedLinePainter()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final m in ConstellationLayout.milestones)
                  Column(
                    children: [
                      Container(
                        width: m == 7 ? 9 : 6,
                        height: m == 7 ? 9 : 6,
                        margin: EdgeInsets.only(top: m == 7 ? 3 : 4.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: m == 7 ? Tokens.amber : Tokens.parchmentFaint,
                        ),
                      ),
                      SizedBox(height: m == 7 ? 8 : 9.5),
                      Text(
                        '$m',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1,
                          color: m == 7 ? Tokens.amber : Tokens.parchment.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text('Each one completes a named constellation.', style: TextStyles.meta),
    ],
  );
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Tokens.parchment.withValues(alpha: 0.3);
    for (var x = 0.0; x <= size.width; x += 6) {
      canvas.drawCircle(Offset(x, 0), 0.9, p);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => false;
}

/// The first week's figure from Journey, scaled to fit, with [lit] stars
/// (fractional: the newest one is still brightening).
class _FirstWeekPainter extends CustomPainter {
  _FirstWeekPainter(this.lit);

  final double lit;

  static final _layout = ConstellationLayout.standard();

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (var d = 1; d <= 7; d++) _layout.pointFor(d)];
    final minX = pts.map((p) => p.dx).reduce(math.min), maxX = pts.map((p) => p.dx).reduce(math.max);
    final minY = pts.map((p) => p.dy).reduce(math.min), maxY = pts.map((p) => p.dy).reduce(math.max);
    // room on the right for the constellation's name beside night 7
    const pad = 20.0, name = 96.0;
    final w = size.width - pad * 2 - name, h = size.height - pad * 2;
    final scale = math.min(w / (maxX - minX), h / (maxY - minY));
    final ox = pad + (w - (maxX - minX) * scale) / 2, oy = pad + (h - (maxY - minY) * scale) / 2;
    Offset at(Offset u) => Offset(ox + (u.dx - minX) * scale, oy + (u.dy - minY) * scale);

    // a little sky
    final rnd = math.Random(11);
    final sky = Paint();
    for (var i = 0; i < 40; i++) {
      sky.color = Tokens.parchment.withValues(alpha: 0.06 + rnd.nextDouble() * 0.2);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.4 + rnd.nextDouble() * 0.7,
        sky,
      );
    }

    final faint = Paint()..color = Tokens.parchment.withValues(alpha: 0.32);
    final link = Paint()
      ..color = Tokens.amber.withValues(alpha: 0.75)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final p = at(pts[i]);
      final t = (lit - i).clamp(0.0, 1.0);
      if (i > 0 && t > 0) canvas.drawLine(at(pts[i - 1]), Offset.lerp(at(pts[i - 1]), p, t)!, link);
      if (t == 0) {
        canvas.drawCircle(p, 1.8, faint);
        continue;
      }
      final r = (i == 6 ? 4.2 : 3.0) * (0.4 + 0.6 * t);
      canvas.drawCircle(
        p,
        r * 3,
        Paint()
          ..color = Tokens.amber.withValues(alpha: 0.28 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
      );
      canvas.drawCircle(p, r, Paint()..color = Color.lerp(Tokens.amber, const Color(0xFFFFF0D0), 0.25)!);
    }

    // the first constellation's name once the week is lit
    final named = (lit - 6.4).clamp(0.0, 0.6) / 0.6;
    if (named > 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: ConstellationLayout.names[7]!.toUpperCase(),
          style: TextStyles.label(color: Tokens.amber.withValues(alpha: named), size: 9.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(pts[6]);
      tp.paint(canvas, Offset(p.dx + 14, p.dy - tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_FirstWeekPainter old) => old.lit != lit;
}
