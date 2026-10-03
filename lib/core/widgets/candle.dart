import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A candle with an optional flame. With [flicker] the flame breathes
/// slowly; motion stays sparse and nothing bounces.
class Candle extends StatefulWidget {
  const Candle({super.key, this.height = 28, this.lit = true, this.flicker = false});

  final double height;
  final bool lit;
  final bool flicker;

  @override
  State<Candle> createState() => _CandleState();
}

class _CandleState extends State<Candle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    if (widget.flicker && widget.lit) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.height * 0.55,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _CandlePainter(lit: widget.lit, phase: widget.flicker ? _c.value : 0),
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.lit, required this.phase});

  final bool lit;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = phase * 2 * math.pi;
    final sway = lit ? math.sin(t) * 0.04 + math.sin(t * 3) * 0.015 : 0.0;
    final grow = lit ? 1 + math.sin(t * 2) * 0.05 : 1.0;

    final bodyTop = h * 0.42;
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.28, bodyTop, w * 0.72, h), Radius.circular(w * 0.06));
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: lit
            ? [const Color(0xFFF3DDB0), const Color(0xFFC99A55)]
            : [Tokens.parchment.withValues(alpha: 0.35), Tokens.parchment.withValues(alpha: 0.18)],
      ).createShader(body.outerRect);
    canvas.drawRRect(body, bodyPaint);

    // wick
    canvas.drawLine(
      Offset(w / 2, bodyTop),
      Offset(w / 2, bodyTop - h * 0.06),
      Paint()
        ..color = lit ? const Color(0xFF3A2A18) : Tokens.parchmentDim
        ..strokeWidth = math.max(1, w * 0.05),
    );
    if (!lit) return;

    final glow = Paint()
      ..color = Tokens.amber.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.18);
    canvas.drawCircle(Offset(w / 2, bodyTop - h * 0.16), h * 0.2 * grow, glow);

    final tip = Offset(w / 2 + w * sway * 4, bodyTop - h * 0.4 * grow);
    final base = Offset(w / 2, bodyTop - h * 0.05);
    final fw = w * 0.2;
    final flame = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(base.dx + fw * 1.4, tip.dy + h * 0.16, base.dx + fw, base.dy, base.dx, base.dy)
      ..cubicTo(base.dx - fw, base.dy, base.dx - fw * 1.4, tip.dy + h * 0.16, tip.dx, tip.dy);
    canvas.drawPath(flame, Paint()..color = Tokens.amber);
    final core = Path()
      ..addOval(Rect.fromCenter(center: Offset(w / 2, base.dy - h * 0.07), width: fw * 0.9, height: h * 0.11));
    canvas.drawPath(core, Paint()..color = const Color(0xFFFFF1D2));
  }

  @override
  bool shouldRepaint(_CandlePainter old) => old.lit != lit || old.phase != phase;
}

/// Candle plus streak count, top right of Tonight.
class CandleStreakBadge extends StatelessWidget {
  const CandleStreakBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count day streak',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Candle(height: 34, lit: count > 0, flicker: count > 0),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontSize: 22, color: Tokens.amber, height: 1)),
        ],
      ),
    );
  }
}
