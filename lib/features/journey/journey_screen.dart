import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/reading_repository.dart';
import '../reminders/reminders_sheet.dart';
import '../share/share_sheet.dart';
import '../tonight/reading_card.dart';
import 'constellation.dart';

String formatReadTime(int seconds) {
  final minutes = seconds ~/ 60;
  final h = minutes ~/ 60, m = minutes % 60;
  return h == 0 ? '${m}m' : '${h}h ${m}m';
}

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(journeyProvider).value;
    return SafeArea(
      bottom: false,
      child: journey == null
          ? const SizedBox()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Tokens.gutter, 36, Tokens.gutter - 12, 0),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Your journey', style: TextStyles.screenTitle)),
                      Semantics(
                        button: true,
                        label: 'Reminders',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => showRemindersSheet(context),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox.square(
                            dimension: 44,
                            child: Center(child: LineIconView(LineIcon.settings, size: 22, color: Tokens.parchmentDim)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _Stats(
                  journey: journey,
                  onShare: switch (latestMilestone(journey.nightsCompleted)) {
                    final m? => () => shareMilestone(context, ref, journey, m),
                    null => null,
                  },
                ),
                Expanded(
                  child: _ConstellationMap(
                    journey: journey,
                    onMilestone: (m) => shareMilestone(context, ref, journey, m),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.journey, this.onShare});
  final JourneyView journey;

  /// Shares the latest milestone reached; null hides the button.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: Tokens.display,
                    fontSize: 42,
                    height: 1.05,
                    color: Tokens.parchment,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyles.label(color: Tokens.parchment.withValues(alpha: 0.85), size: 11)),
          ],
        ),
      ),
    );
    Widget rule() => Container(width: 1, height: 52, color: Tokens.hairline);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          stat('${journey.nightsCompleted}', 'NIGHTS'),
          rule(),
          stat('${journey.streak}', 'DAY STREAK'),
          rule(),
          stat(formatReadTime(journey.secondsRead), 'READ'),
          if (onShare != null)
            Semantics(
              button: true,
              label: 'Share milestone',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onShare,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 40,
                  height: 52,
                  child: Center(child: LineIconView(LineIcon.share, size: 20, color: Tokens.parchmentDim)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConstellationMap extends StatefulWidget {
  const _ConstellationMap({required this.journey, required this.onMilestone});
  final JourneyView journey;

  /// Tapping a reached milestone's label shares its card.
  final ValueChanged<int> onMilestone;

  @override
  State<_ConstellationMap> createState() => _ConstellationMapState();
}

class _ConstellationMapState extends State<_ConstellationMap> with SingleTickerProviderStateMixin {
  static final _layout = ConstellationLayout.standard();
  late final AnimationController _light = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward();

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  void _onTap(TapUpDetails d, Size size) {
    int? best;
    var bestDist = 30.0;
    for (final day in widget.journey.litNights) {
      final p = _MapPainter.toCanvas(_layout.pointFor(day), size);
      final dist = (p - d.localPosition).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = day;
      }
    }
    // a tap right on a star opens its night; a tap on a reached
    // milestone's label shares that milestone
    if (best == null || bestDist > 12) {
      for (final m in ConstellationLayout.milestones) {
        if (widget.journey.nightsCompleted < m) continue;
        final p = _MapPainter.toCanvas(_layout.pointFor(m), size);
        if (_MapPainter.labelRects(m, p).any((r) => r.inflate(6).contains(d.localPosition))) {
          widget.onMilestone(m);
          return;
        }
      }
    }
    if (best != null) showNightSheet(context, best);
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.journey.litNights;
    return Semantics(
      label:
          'Constellation map. ${lit.length} nights lit. '
          '${_nextMilestone(lit.length)}',
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            onTapUp: (d) => _onTap(d, size),
            child: AnimatedBuilder(
              animation: _light,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _MapPainter(
                  layout: _layout,
                  lit: lit.toSet(),
                  current: widget.journey.currentNight,
                  newest: lit.isEmpty ? null : lit.reduce(math.max),
                  light: Curves.easeOut.transform(_light.value),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _nextMilestone(int done) {
    for (final m in ConstellationLayout.milestones) {
      if (done < m) return '${m - done} nights to ${ConstellationLayout.names[m]}.';
    }
    return 'Every constellation complete.';
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.layout,
    required this.lit,
    required this.current,
    required this.newest,
    required this.light,
  });

  final ConstellationLayout layout;
  final Set<int> lit;
  final int current;
  final int? newest;
  final double light;

  static const _pad = EdgeInsets.fromLTRB(20, 34, 26, 120);

  static Offset toCanvas(Offset unit, Size size) =>
      Offset(_pad.left + unit.dx * (size.width - _pad.horizontal), _pad.top + unit.dy * (size.height - _pad.vertical));

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas, size);

    // the dotted path of nights still to come
    final faint = Paint()..color = Tokens.parchment.withValues(alpha: 0.32);
    for (var d = 8; d <= layout.length; d++) {
      if (lit.contains(d)) continue;
      // thin out the far path so it reads as dots, not a smear
      if (d > 30 && d % 2 != 0) continue;
      if (d > 100 && d % 4 != 0) continue;
      if (d > 365 && d % 8 != 0) continue;
      canvas.drawCircle(toCanvas(layout.pointFor(d), size), 1.1, faint);
    }
    // first-week figure, unlit
    for (var d = 1; d <= 7; d++) {
      if (!lit.contains(d)) canvas.drawCircle(toCanvas(layout.pointFor(d), size), 1.6, faint);
    }

    // links between consecutive lit nights
    final link = Paint()
      ..color = Tokens.amber.withValues(alpha: 0.75)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (final d in lit) {
      if (!lit.contains(d + 1)) continue;
      final a = toCanvas(layout.pointFor(d), size), b = toCanvas(layout.pointFor(d + 1), size);
      final t = d + 1 == newest ? light : 1.0;
      canvas.drawLine(a, Offset.lerp(a, b, t)!, link);
    }

    // lit stars
    for (final d in lit) {
      final p = toCanvas(layout.pointFor(d), size);
      final t = d == newest ? light : 1.0;
      final milestone = ConstellationLayout.milestones.contains(d);
      _star(canvas, p, (milestone ? 4.2 : 3.0) * (0.4 + 0.6 * t), t);
    }

    // tonight's night: a quiet ring
    if (current > 0 && !lit.contains(current)) {
      canvas.drawCircle(
        toCanvas(layout.pointFor(current), size),
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Tokens.amber.withValues(alpha: 0.6),
      );
    }

    // milestone labels
    for (final m in ConstellationLayout.milestones) {
      final p = toCanvas(layout.pointFor(m), size);
      final reached = lit.length >= m;
      if (m == 1000) _sparkle(canvas, p, 8, reached ? Tokens.amber : Tokens.amber.withValues(alpha: 0.7));
      _label(canvas, '$m', p + _numberOffset(m), _numberStyle(m));
      if (reached) _label(canvas, _name(m), p + _nameOffset, _nameStyle);
    }

    _landscape(canvas, size);
  }

  static Offset _numberOffset(int m) => switch (m) {
    7 => const Offset(-26, -10),
    1000 => const Offset(-14, 14),
    _ => const Offset(-8, -26),
  };

  static TextStyle _numberStyle(int m) => TextStyle(
    fontFamily: Tokens.serif,
    fontSize: 17,
    color: m == 1000 ? Tokens.amber : Tokens.parchment.withValues(alpha: 0.85),
  );

  static const _nameOffset = Offset(14, -6);
  static final _nameStyle = TextStyles.label(color: Tokens.amber, size: 9.5);
  static String _name(int m) => ConstellationLayout.names[m]!.toUpperCase();

  /// Where milestone [m]'s number and name are drawn around its star at [p].
  static List<Rect> labelRects(int m, Offset p) {
    Rect rect(String text, Offset at, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final r = at & tp.size;
      tp.dispose();
      return r;
    }

    return [rect('$m', p + _numberOffset(m), _numberStyle(m)), rect(_name(m), p + _nameOffset, _nameStyle)];
  }

  void _sky(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final dim = Paint();
    for (var i = 0; i < 220; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.85);
      dim.color = Tokens.parchment.withValues(alpha: 0.08 + rnd.nextDouble() * 0.25);
      canvas.drawCircle(p, rnd.nextDouble() * 0.9 + 0.3, dim);
    }
    // a faint milky way
    final band = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.45, size.width, size.height * 0.05)
      ..lineTo(size.width, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.62, size.width * 0.4, size.height)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..color = Tokens.parchment.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  void _star(Canvas canvas, Offset p, double r, double t) {
    canvas.drawCircle(
      p,
      r * 3,
      Paint()
        ..color = Tokens.amber.withValues(alpha: 0.28 * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
    );
    canvas.drawCircle(p, r, Paint()..color = Color.lerp(Tokens.amber, const Color(0xFFFFF0D0), 0.25)!);
  }

  void _sparkle(Canvas canvas, Offset p, double r, Color c) {
    final paint = Paint()
      ..color = c
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 4;
      final len = i.isEven ? r : r * 0.55;
      canvas.drawLine(p - Offset(math.cos(a), math.sin(a)) * len, p + Offset(math.cos(a), math.sin(a)) * len, paint);
    }
    canvas.drawCircle(p, 2.2, Paint()..color = c);
  }

  void _label(Canvas canvas, String text, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  void _landscape(Canvas canvas, Size size) {
    final h = size.height, w = size.width;
    Path ridge(double base, double amp, double f, double phase) {
      final p = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + 8; x += 8) {
        p.lineTo(x, base - amp * (0.6 * math.sin(x / w * f + phase) + 0.4 * math.sin(x / w * f * 2.7 + phase * 2)));
      }
      return p
        ..lineTo(w, h)
        ..close();
    }

    canvas.drawPath(ridge(h - 100, 26, 5, 1), Paint()..color = const Color(0xFF1C2130));
    canvas.drawPath(ridge(h - 62, 18, 7, 3), Paint()..color = const Color(0xFF151925));
    // cypress trees and a few village lights
    final tree = Paint()..color = const Color(0xFF0E111A);
    for (final (x, th) in [(0.05, 70.0), (0.09, 54.0), (0.13, 62.0), (0.92, 66.0), (0.96, 50.0)]) {
      final bx = x * w, by = h - 30;
      canvas.drawPath(
        Path()
          ..moveTo(bx, by - th)
          ..quadraticBezierTo(bx + 9, by - th * 0.5, bx + 5, by)
          ..lineTo(bx - 5, by)
          ..quadraticBezierTo(bx - 9, by - th * 0.5, bx, by - th)
          ..close(),
        tree,
      );
    }
    canvas.drawRect(Rect.fromLTWH(0, h - 34, w, 34), Paint()..color = const Color(0xFF0F121B));
    final lights = Paint()..color = Tokens.amber.withValues(alpha: 0.75);
    final rnd = math.Random(3);
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(Offset(w * (0.42 + rnd.nextDouble() * 0.2), h - 40 - rnd.nextDouble() * 14), 1.1, lights);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.light != light || old.lit.length != lit.length || old.current != current;
}

/// Tapping a lit star (or a Library row) opens that night's three readings.
Future<void> showNightSheet(BuildContext context, int day) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final night = ref.watch(nightProvider(day)).value;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NIGHT $day', style: TextStyles.label(color: Tokens.amber, size: 12)),
                const SizedBox(height: 10),
                if (night != null)
                  for (final p in night.pieces)
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.push(Routes.read(day, p.work.id));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeLabel(p.work.type),
                                    style: TextStyles.label(color: Tokens.parchmentDim, size: 10),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(p.work.title, style: const TextStyle(fontSize: 20, color: Tokens.parchment)),
                                  Text(p.work.author, style: TextStyles.meta),
                                ],
                              ),
                            ),
                            Text(
                              p.done ? 'Read' : '${p.work.estMinutes} min',
                              style: TextStyle(color: p.done ? Tokens.amber : Tokens.parchmentDim),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
