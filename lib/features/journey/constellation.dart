import 'dart:math' as math;
import 'dart:ui';

/// Layout of the 1000-night constellation map, in unit coordinates
/// (0..1 on both axes; the painter scales to the canvas).
///
/// Nights 1-7 form the first constellation as a hand-placed figure. Later
/// nights run along a smooth path through the milestone anchors, so each
/// milestone (7, 30, 100, 365, 1000) completes a named constellation.
class ConstellationLayout {
  ConstellationLayout._(this._points);

  factory ConstellationLayout.standard() {
    final pts = <Offset>[..._firstWeek];
    for (var m = 0; m < _anchors.length - 1; m++) {
      final (fromDay, a) = _anchors[m];
      final (toDay, b) = _anchors[m + 1];
      final c1 = _controls[m].$1, c2 = _controls[m].$2;
      final n = toDay - fromDay;
      final rnd = math.Random(toDay);
      for (var i = 1; i <= n; i++) {
        final t = i / n;
        final p = _bezier(a, c1, c2, b, t);
        // a little scatter so the path reads as stars, not a line
        final j = i == n ? Offset.zero : Offset(rnd.nextDouble() - .5, rnd.nextDouble() - .5) * 0.018;
        pts.add(p + j);
      }
    }
    return ConstellationLayout._(pts);
  }

  final List<Offset> _points;

  /// Position of night [day] (1-based).
  Offset pointFor(int day) => _points[(day - 1).clamp(0, _points.length - 1)];

  int get length => _points.length;

  static const milestones = [7, 30, 100, 365, 1000];

  static const names = {
    7: 'The Candle',
    30: 'The Lantern',
    100: 'The Nightingale',
    365: 'The Ship',
    1000: 'The Thousand',
  };

  // Nights 1..7: a small figure in the upper left, like the approved mockup.
  static const _firstWeek = [
    Offset(0.17, 0.10),
    Offset(0.17, 0.20),
    Offset(0.10, 0.28),
    Offset(0.09, 0.34),
    Offset(0.15, 0.39),
    Offset(0.23, 0.41),
    Offset(0.27, 0.48),
  ];

  static const _anchors = [
    (7, Offset(0.27, 0.48)),
    (30, Offset(0.50, 0.17)),
    (100, Offset(0.86, 0.38)),
    (365, Offset(0.55, 0.64)),
    (1000, Offset(0.90, 0.88)),
  ];

  static const _controls = [
    (Offset(0.30, 0.25), Offset(0.38, 0.12)),
    (Offset(0.66, 0.20), Offset(0.84, 0.24)),
    (Offset(0.88, 0.52), Offset(0.60, 0.48)),
    (Offset(0.50, 0.80), Offset(0.80, 0.80)),
  ];

  static Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
  }
}
