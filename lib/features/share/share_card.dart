import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/candle.dart';
import '../../data/database.dart';
import '../../data/reading_repository.dart';
import '../journey/constellation.dart';

/// The name and line printed on every card. The final app name is still
/// undecided, so this is the one place to change it.
abstract final class ShareBrand {
  static const name = '1000 Nights';
  static const tagline = 'One story, one poem, one essay.';

  /// For file names: "1000-nights".
  static final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

/// What a card shows. One subclass per variant.
sealed class ShareCardData {
  const ShareCardData({required this.dayNumber});

  /// The night the card is about; sent with the analytics events.
  final int dayNumber;

  /// Analytics `kind` and file-name part.
  String get kind;

  /// Asset to decode before the card is captured, if any.
  String? get imagePath => null;

  /// The short text that travels with the image.
  String get shareText;

  String get fileName => '${ShareBrand.slug}-$kind-$dayNumber.png';
}

/// A highlighted sentence over the work's engraving.
final class HighlightShare extends ShareCardData {
  const HighlightShare({
    required super.dayNumber,
    required this.quote,
    required this.title,
    required this.author,
    this.imagePath,
  });

  HighlightShare.of(String quote, Work work, {required int dayNumber})
    : this(dayNumber: dayNumber, quote: quote, title: work.title, author: work.author, imagePath: work.imagePath);

  final String quote;
  final String title;
  final String author;
  @override
  final String? imagePath;

  @override
  String get kind => 'highlight';

  @override
  String get shareText => 'From “$title” by $author. ${ShareBrand.name}: ${ShareBrand.tagline.toLowerCase()}';
}

/// "Night 12 complete", tonight's pull quote and the three titles.
final class NightShare extends ShareCardData {
  const NightShare({required super.dayNumber, required this.titles, this.quote, this.quoteAuthor});

  factory NightShare.of(NightView night) {
    // the same choice as Night complete's quote
    final w = night.pieces.where((p) => p.work.pullQuote != null).firstOrNull?.work;
    return NightShare(
      dayNumber: night.dayNumber,
      titles: [for (final p in night.pieces) p.work.title],
      quote: w?.pullQuote,
      quoteAuthor: w?.author,
    );
  }

  final List<String> titles;
  final String? quote;
  final String? quoteAuthor;

  @override
  String get kind => 'night';

  @override
  String get shareText => 'Night $dayNumber of 1000, read. ${ShareBrand.name}: ${ShareBrand.tagline.toLowerCase()}';
}

/// A completed constellation on Journey.
final class MilestoneShare extends ShareCardData {
  const MilestoneShare({
    required this.milestone,
    required this.nightsCompleted,
    required this.streak,
    required this.longestStreak,
  }) : super(dayNumber: milestone);

  /// One of [ConstellationLayout.milestones].
  final int milestone;
  final int nightsCompleted;
  final int streak;
  final int longestStreak;

  String get name => ConstellationLayout.names[milestone] ?? '';

  @override
  String get kind => 'milestone';

  @override
  String get shareText => 'Night $milestone: $name. ${ShareBrand.name}: ${ShareBrand.tagline.toLowerCase()}';
}

/// The image people share: 360 x 450 logical (4:5), exported at 3x as
/// 1080 x 1350. It ignores the system text scale, since it is a picture.
class ShareCard extends StatelessWidget {
  const ShareCard(this.data, {super.key});

  final ShareCardData data;

  static const size = Size(360, 450);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Tokens.ink),
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: Tokens.serif, color: Tokens.parchment),
            textAlign: TextAlign.center,
            child: switch (data) {
              final HighlightShare d => _HighlightCard(d),
              final NightShare d => _NightCard(d),
              final MilestoneShare d => _MilestoneCard(d),
            },
          ),
        ),
      ),
    );
  }
}

const _side = 36.0;

/// Wordmark and tagline, at the foot of every card.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ShareBrand.name.toUpperCase(), style: TextStyles.label(color: Tokens.amber, size: 10)),
        const SizedBox(height: 6),
        Text(
          ShareBrand.tagline,
          style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Tokens.parchmentDim, height: 1.2),
        ),
      ],
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Container(width: 28, height: 1, color: Tokens.amber.withValues(alpha: 0.8));
}

// --------------------------------------------------------------------------
// Highlight
// --------------------------------------------------------------------------

class _HighlightCard extends StatelessWidget {
  const _HighlightCard(this.data);
  final HighlightShare data;

  static const _imageHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final image = data.imagePath;
    return Stack(
      children: [
        if (image == null)
          Positioned.fill(
            child: CustomPaint(painter: _SkyPainter(seed: data.quote.length)),
          ),
        if (image != null) ...[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _imageHeight,
            child: Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
          ),
          // the engraving fades into the ink
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: _imageHeight + 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.3, 0.65, 1],
                  colors: [Color(0x1A12151F), Color(0x5912151F), Color(0xD912151F), Tokens.ink],
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          child: Column(
            children: [
              SizedBox(height: image != null ? 112 : 40),
              Expanded(child: _FittedQuote(stripOuterQuotes(data.quote))),
              const SizedBox(height: 22),
              const _Rule(),
              const SizedBox(height: 16),
              _Attribution(title: data.title, author: data.author),
              const SizedBox(height: 9),
              Text('NIGHT ${data.dayNumber} OF 1000', style: TextStyles.label(color: Tokens.parchmentDim, size: 9)),
              const SizedBox(height: 34),
              const _Footer(),
            ],
          ),
        ),
      ],
    );
  }
}

/// "TITLE · AUTHOR" on one line when it fits, otherwise title over author,
/// so a long title never strands half a name.
class _Attribution extends StatelessWidget {
  const _Attribution({required this.title, required this.author});
  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    final style = TextStyles.label(color: Tokens.parchment.withValues(alpha: 0.85), size: 9.5);
    final oneLine = '${title.toUpperCase()}  ·  ${author.toUpperCase()}';
    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(text: oneLine, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: c.maxWidth);
        final fits = !tp.didExceedMaxLines;
        tp.dispose();
        return Text(
          fits ? oneLine : '${title.toUpperCase()}\n${author.toUpperCase()}',
          maxLines: fits ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(height: 1.6),
        );
      },
    );
  }
}

/// A highlight is a sentence cut from the text, so it may start with an
/// opening quote whose close comes later, or sit inside a pair. The card
/// draws its own quote mark, so drop those; keep any that are part of the
/// sentence ("“No!” he cried."). A closing ’ is also an apostrophe, so it
/// only goes when an opening ‘ went.
String stripOuterQuotes(String s) {
  s = s.trim();
  var inner = s;
  var single = false;
  if (inner.startsWith(RegExp('[“"‘]'))) {
    single = inner.startsWith('‘');
    inner = inner.substring(1);
  }
  if (inner.endsWith('”') || inner.endsWith('"') || (single && inner.endsWith('’'))) {
    inner = inner.substring(0, inner.length - 1);
  }
  if (inner.contains(RegExp('[“”"‘]'))) return s;
  return inner.trim();
}

/// An amber quote mark over the sentence in Newsreader italic, as large as
/// fits: it shrinks for long quotes, then stops at eight lines with an
/// ellipsis. The pair sits centred in the space it is given.
class _FittedQuote extends StatelessWidget {
  const _FittedQuote(this.text);
  final String text;

  static const _maxSize = 25.0, _minSize = 15.0, _maxLines = 8, _height = 1.38;
  static const _markHeight = 50.0;

  static TextStyle _style(double size) => TextStyle(
    fontFamily: Tokens.serif,
    fontStyle: FontStyle.italic,
    fontSize: size,
    height: _height,
    color: Tokens.parchment,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final room = c.maxHeight - _markHeight;
        var size = _maxSize;
        for (; size > _minSize; size -= 0.5) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: _style(size)),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLines: _maxLines,
          )..layout(maxWidth: c.maxWidth);
          final fits = !tp.didExceedMaxLines && tp.height <= room;
          tp.dispose();
          if (fits) break;
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _markHeight,
                child: Text(
                  '“',
                  style: TextStyle(fontFamily: Tokens.display, fontSize: 60, height: 1.05, color: Tokens.amber),
                ),
              ),
              Text(
                text,
                style: _style(size),
                maxLines: math.max(1, math.min(_maxLines, (room / (size * _height)).floor())),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------------------
// Night complete
// --------------------------------------------------------------------------

class _NightCard extends StatelessWidget {
  const _NightCard(this.data);
  final NightShare data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // warm light around the candle
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 0.6,
                colors: [Color(0x14E8B76A), Color(0x00E8B76A)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          child: Column(
            children: [
              const SizedBox(height: 44),
              const Candle(height: 92),
              const SizedBox(height: 22),
              Text(
                'Night ${data.dayNumber} complete',
                maxLines: 1,
                style: TextStyles.screenTitle.copyWith(fontSize: 31),
              ),
              // the quote and the three titles sit together in the space left
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.quote != null) ...[
                        Text(
                          '“${data.quote}”',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16.5, fontStyle: FontStyle.italic, height: 1.42),
                        ),
                        if (data.quoteAuthor != null) ...[
                          const SizedBox(height: 10),
                          Text(data.quoteAuthor!.toUpperCase(), style: TextStyles.label(color: Tokens.amber, size: 9)),
                        ],
                        const SizedBox(height: 30),
                      ],
                      const _Rule(),
                      const SizedBox(height: 14),
                      for (final t in data.titles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            t,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Tokens.parchment.withValues(alpha: 0.72),
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _Footer(),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// Milestone
// --------------------------------------------------------------------------

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard(this.data);
  final MilestoneShare data;

  @override
  Widget build(BuildContext context) {
    Widget stat(int value, String label) => Expanded(
      child: Column(
        children: [
          Text('$value', maxLines: 1, style: const TextStyle(fontFamily: Tokens.display, fontSize: 26, height: 1.05)),
          const SizedBox(height: 6),
          Text(label, style: TextStyles.label(color: Tokens.parchmentDim, size: 8)),
        ],
      ),
    );
    Widget rule() => Container(width: 1, height: 34, color: Tokens.hairline);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _SkyPainter(seed: data.milestone)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          child: Column(
            children: [
              const SizedBox(height: 36),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(painter: _FigurePainter(data.milestone)),
              ),
              const SizedBox(height: 22),
              Text(data.name.toUpperCase(), style: TextStyles.label(color: Tokens.amber, size: 11)),
              const SizedBox(height: 10),
              Text('Night ${data.milestone}', style: TextStyles.screenTitle.copyWith(fontSize: 40)),
              const Spacer(),
              Row(
                children: [
                  stat(data.nightsCompleted, 'NIGHTS'),
                  rule(),
                  stat(data.streak, 'DAY STREAK'),
                  rule(),
                  stat(data.longestStreak, 'LONGEST'),
                ],
              ),
              const SizedBox(height: 34),
              const _Footer(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A scatter of faint stars behind the figure.
class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final dot = Paint();
    for (var i = 0; i < 90; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.55);
      dot.color = Tokens.parchment.withValues(alpha: 0.06 + rnd.nextDouble() * 0.2);
      canvas.drawCircle(p, rnd.nextDouble() * 0.7 + 0.3, dot);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.seed != seed;
}

/// The milestone's constellation, taken from the Journey map: the first week
/// as its figure, later milestones as a handful of stars along their stretch
/// of the path, ending in the milestone star.
class _FigurePainter extends CustomPainter {
  _FigurePainter(this.milestone);
  final int milestone;

  static final _layout = ConstellationLayout.standard();

  List<Offset> _points() {
    final ms = ConstellationLayout.milestones;
    final i = ms.indexOf(milestone);
    if (i <= 0) return [for (var d = 1; d <= 7; d++) _layout.pointFor(d)];
    final from = ms[i - 1], to = milestone;
    const stars = 9;
    return [for (var k = 0; k < stars; k++) _layout.pointFor(from + ((to - from) * k / (stars - 1)).round())];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _points();
    final box = pts
        .skip(1)
        .fold(Rect.fromPoints(pts.first, pts.first), (r, p) => r.expandToInclude(Rect.fromPoints(p, p)));
    // fit into the canvas, keeping the figure's shape
    const pad = 18.0;
    final scale = math.min(
      (size.width - pad * 2) / math.max(box.width, 0.001),
      (size.height - pad * 2) / math.max(box.height, 0.001),
    );
    final offset = size.center(Offset.zero) - box.center * scale;
    final canvasPts = [for (final p in pts) p * scale + offset];

    final link = Paint()
      ..color = Tokens.amber.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < canvasPts.length - 1; k++) {
      canvas.drawLine(canvasPts[k], canvasPts[k + 1], link);
    }
    for (var k = 0; k < canvasPts.length; k++) {
      final last = k == canvasPts.length - 1;
      _star(canvas, canvasPts[k], last ? 4.2 : 2.8);
      if (last) _sparkle(canvas, canvasPts[k], 13);
    }
  }

  void _star(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(
      p,
      r * 3,
      Paint()
        ..color = Tokens.amber.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
    );
    canvas.drawCircle(p, r, Paint()..color = Color.lerp(Tokens.amber, const Color(0xFFFFF0D0), 0.25)!);
  }

  void _sparkle(Canvas canvas, Offset p, double r) {
    final paint = Paint()
      ..color = Tokens.amber.withValues(alpha: 0.85)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 4;
      final len = i.isEven ? r : r * 0.5;
      final d = Offset(math.cos(a), math.sin(a)) * len;
      canvas.drawLine(p - d, p + d, paint);
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) => old.milestone != milestone;
}
