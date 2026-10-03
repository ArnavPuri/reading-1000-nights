import 'package:flutter/material.dart';

/// Design tokens from the PRD design system ("ink-navy, candle amber and
/// parchment serif"). Hex values to be confirmed against the final mockup
/// export.
abstract final class Tokens {
  static const ink = Color(0xFF12151F);
  static const inkRaised = Color(0xFF1B1F2B); // about 6% lighter than ink
  static const amber = Color(0xFFE8B76A);
  static const parchment = Color(0xFFEFE6D6);
  static final parchmentDim = parchment.withValues(alpha: 0.6);
  static final parchmentFaint = parchment.withValues(alpha: 0.35);
  static final hairline = parchment.withValues(alpha: 0.12);
  static final highlight = amber.withValues(alpha: 0.18);

  static const cardRadius = 20.0;
  static const gutter = 20.0;

  static const serif = 'Newsreader';
  static const display = 'NewsreaderDisplay';
}

abstract final class TextStyles {
  /// "NIGHT 12 OF 1000", "SHORT STORY": small caps, letter-spaced ~15%.
  static TextStyle label({Color? color, double size = 12}) => TextStyle(
    fontFamily: Tokens.serif,
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: size * 0.18,
    color: color ?? Tokens.parchment,
    height: 1.2,
  );

  static const screenTitle = TextStyle(
    fontFamily: Tokens.display,
    fontSize: 44,
    fontWeight: FontWeight.w300,
    color: Tokens.parchment,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const cardTitle = TextStyle(fontFamily: Tokens.serif, fontSize: 25, color: Tokens.parchment, height: 1.2);

  static final byline = TextStyle(
    fontFamily: Tokens.serif,
    fontSize: 16,
    color: Tokens.parchment.withValues(alpha: 0.82),
    height: 1.3,
  );

  static final meta = TextStyle(fontFamily: Tokens.serif, fontSize: 15, color: Tokens.parchmentDim);
}

/// Reader themes: Night, Sepia, Paper.
enum ReaderTheme {
  night('Night', Tokens.ink, Tokens.parchment, Tokens.amber),
  sepia('Sepia', Color(0xFFF3EAD7), Color(0xFF4A3B2C), Color(0xFFA5672A)),
  paper('Paper', Color(0xFFFAF8F3), Color(0xFF22201C), Color(0xFF9C6B1E));

  const ReaderTheme(this.label, this.background, this.text, this.accent);
  final String label;
  final Color background;
  final Color text;
  final Color accent;

  Color get highlight => accent.withValues(alpha: this == night ? 0.18 : 0.22);

  static ReaderTheme byName(String name) =>
      ReaderTheme.values.firstWhere((t) => t.name == name, orElse: () => ReaderTheme.night);
}

/// Reader type size: 5 steps (default step 2 = 19 pt, per the PRD).
const readerFontSizes = [16.0, 17.5, 19.0, 21.0, 23.5];

/// Reader line spacing: 3 steps (default step 1 = 1.6).
const readerLineHeights = [1.45, 1.6, 1.8];

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: Tokens.serif,
    scaffoldBackgroundColor: Tokens.ink,
    colorScheme: const ColorScheme.dark(
      surface: Tokens.ink,
      primary: Tokens.amber,
      onPrimary: Tokens.ink,
      secondary: Tokens.amber,
      onSurface: Tokens.parchment,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: Tokens.serif,
      bodyColor: Tokens.parchment,
      displayColor: Tokens.parchment,
    ),
    dividerColor: Tokens.hairline,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Tokens.inkRaised,
      modalBackgroundColor: Tokens.inkRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: _FadeTransitionsBuilder(),
        TargetPlatform.android: _FadeTransitionsBuilder(),
        TargetPlatform.linux: _FadeTransitionsBuilder(),
        TargetPlatform.macOS: _FadeTransitionsBuilder(),
      },
    ),
  );
}

/// "Cross-fades between screens. Nothing bounces."
class _FadeTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }
}
