import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The three tab-bar line icons: moon, open book, constellation.
enum LineIcon { moon, book, constellation, clock, check, back, close, bookmark, share, settings }

class LineIconView extends StatelessWidget {
  const LineIconView(this.icon, {super.key, this.size = 26, required this.color, this.filled = false});

  final LineIcon icon;
  final double size;
  final Color color;

  /// Active tab icons are drawn solid (the moon) or brighter.
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LineIconPainter(icon, color, filled)),
  );
}

class _LineIconPainter extends CustomPainter {
  _LineIconPainter(this.icon, this.color, this.filled);

  final LineIcon icon;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s / 20)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (icon) {
      case LineIcon.moon:
        final outer = Path()..addOval(Rect.fromCircle(center: Offset(s * .47, s * .53), radius: s * .38));
        final inner = Path()..addOval(Rect.fromCircle(center: Offset(s * .7, s * .36), radius: s * .32));
        final crescent = Path.combine(PathOperation.difference, outer, inner);
        canvas.drawPath(crescent, filled ? fill : stroke);
      case LineIcon.book:
        final l = Path()
          ..moveTo(s * .5, s * .28)
          ..quadraticBezierTo(s * .32, s * .18, s * .08, s * .22)
          ..lineTo(s * .08, s * .78)
          ..quadraticBezierTo(s * .32, s * .74, s * .5, s * .84)
          ..quadraticBezierTo(s * .68, s * .74, s * .92, s * .78)
          ..lineTo(s * .92, s * .22)
          ..quadraticBezierTo(s * .68, s * .18, s * .5, s * .28)
          ..lineTo(s * .5, s * .84);
        canvas.drawPath(l, stroke);
      case LineIcon.constellation:
        final pts = [
          Offset(s * .18, s * .82),
          Offset(s * .42, s * .56),
          Offset(s * .58, s * .62),
          Offset(s * .84, s * .18),
        ];
        canvas.drawPath(Path()..addPolygon(pts, false), stroke..strokeWidth = s / 28);
        for (final p in pts) {
          canvas.drawCircle(p, s * .075, fill);
        }
      case LineIcon.clock:
        canvas.drawCircle(Offset(s / 2, s / 2), s * .42, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(s * .5, s * .26)
            ..lineTo(s * .5, s * .52)
            ..lineTo(s * .66, s * .62),
          stroke,
        );
      case LineIcon.check:
        canvas.drawPath(
          Path()
            ..moveTo(s * .2, s * .52)
            ..lineTo(s * .42, s * .74)
            ..lineTo(s * .82, s * .28),
          stroke..strokeWidth = s / 9,
        );
      case LineIcon.back:
        canvas.drawPath(
          Path()
            ..moveTo(s * .64, s * .14)
            ..lineTo(s * .3, s * .5)
            ..lineTo(s * .64, s * .86),
          stroke..strokeWidth = s / 14,
        );
      case LineIcon.close:
        stroke.strokeWidth = s / 14;
        canvas.drawLine(Offset(s * .22, s * .22), Offset(s * .78, s * .78), stroke);
        canvas.drawLine(Offset(s * .78, s * .22), Offset(s * .22, s * .78), stroke);
      case LineIcon.bookmark:
        // A ribbon bookmark. Filled when the piece is a favourite.
        final ribbon = Path()
          ..moveTo(s * .26, s * .12)
          ..lineTo(s * .74, s * .12)
          ..lineTo(s * .74, s * .88)
          ..lineTo(s * .5, s * .68)
          ..lineTo(s * .26, s * .88)
          ..close();
        canvas.drawPath(ribbon, filled ? fill : (stroke..strokeWidth = s / 14));
      case LineIcon.share:
        // An open box with an arrow rising out of it.
        stroke.strokeWidth = s / 14;
        canvas.drawPath(
          Path()
            ..moveTo(s * .34, s * .4)
            ..lineTo(s * .2, s * .4)
            ..lineTo(s * .2, s * .88)
            ..lineTo(s * .8, s * .88)
            ..lineTo(s * .8, s * .4)
            ..lineTo(s * .66, s * .4),
          stroke,
        );
        canvas.drawLine(Offset(s * .5, s * .1), Offset(s * .5, s * .62), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(s * .34, s * .26)
            ..lineTo(s * .5, s * .1)
            ..lineTo(s * .66, s * .26),
          stroke,
        );
      case LineIcon.settings:
        // A gear: eight square-shouldered teeth around a hub.
        stroke.strokeWidth = s / 16;
        const teeth = 8;
        final c = Offset(s / 2, s / 2);
        final outer = s * .43, inner = s * .33;
        const step = 2 * math.pi / teeth;
        Offset at(double r, double a) => c + Offset(math.cos(a), math.sin(a)) * r;
        final gear = Path();
        for (var i = 0; i < teeth; i++) {
          final a = i * step - math.pi / 2;
          final p0 = at(inner, a - step * .3), p1 = at(outer, a - step * .17);
          final p2 = at(outer, a + step * .17), p3 = at(inner, a + step * .3);
          i == 0 ? gear.moveTo(p0.dx, p0.dy) : gear.lineTo(p0.dx, p0.dy);
          gear
            ..lineTo(p1.dx, p1.dy)
            ..arcToPoint(p2, radius: Radius.circular(outer))
            ..lineTo(p3.dx, p3.dy);
          final next = at(inner, a + step - step * .3);
          gear.arcToPoint(next, radius: Radius.circular(inner));
        }
        canvas.drawPath(gear..close(), stroke);
        canvas.drawCircle(c, s * .13, stroke);
    }
  }

  @override
  bool shouldRepaint(_LineIconPainter old) => old.icon != icon || old.color != color || old.filled != filled;
}
