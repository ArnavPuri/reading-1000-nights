import 'package:flutter/material.dart';

/// One clock for a page's entrance. Children placed with [Reveal] fade in
/// and drift up on its timeline, so a page's elements arrive one after
/// another. Slow, eased out, and nothing bounces.
class Stage extends StatefulWidget {
  const Stage({super.key, required this.length, required this.child});

  /// The whole timeline; [Reveal] delays are measured along it.
  final Duration length;
  final Widget child;

  /// The share of [Stage.length] from [at] for [span], eased out, as a
  /// 0..1 animation.
  static Animation<double> interval(BuildContext context, Duration at, {Duration span = Reveal.span}) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StageScope>()!;
    final total = scope.length.inMilliseconds;
    final begin = (at.inMilliseconds / total).clamp(0.0, 1.0);
    final end = ((at + span).inMilliseconds / total).clamp(begin, 1.0);
    return scope.clock.drive(CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)));
  }

  @override
  State<Stage> createState() => _StageState();
}

class _StageState extends State<Stage> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: widget.length)..forward();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StageScope(clock: _clock, length: widget.length, child: widget.child);
}

class _StageScope extends InheritedWidget {
  const _StageScope({required this.clock, required this.length, required super.child});

  final Animation<double> clock;
  final Duration length;

  @override
  bool updateShouldNotify(_StageScope old) => old.clock != clock;
}

/// Fades [child] in and drifts it up by [rise] at [at] on the [Stage].
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.at, required this.child, this.rise = 14, this.duration = span});

  static const span = Duration(milliseconds: 900);

  final Duration at;
  final Duration duration;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Stage.interval(context, at, span: duration);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(offset: Offset(0, (1 - t.value) * rise), child: child),
      ),
      child: child,
    );
  }
}

/// Milliseconds, for short timelines.
Duration ms(int n) => Duration(milliseconds: n);
