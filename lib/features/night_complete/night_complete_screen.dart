import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/candle.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/reading_repository.dart';
import '../../domain/local_date.dart';
import '../share/share_card.dart';
import '../share/share_sheet.dart';

/// Lit candle, "Night N complete", one line from tonight's reading, and the
/// week as seven dots. No confetti or sound: it should feel like closing a
/// book.
class NightCompleteScreen extends ConsumerWidget {
  const NightCompleteScreen({super.key, required this.dayNumber});

  final int dayNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(nightProvider(dayNumber)).value;
    final week = ref.watch(weekProvider).value ?? List.filled(7, false);
    final today = todayOf(ref.read);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Candle(height: 120, flicker: true),
              const SizedBox(height: 40),
              Text(
                'Night $dayNumber complete',
                textAlign: TextAlign.center,
                style: TextStyles.screenTitle.copyWith(fontSize: 38),
              ),
              const SizedBox(height: 28),
              if (night != null) _Quote(night: night),
              const Spacer(flex: 2),
              _WeekDots(week: week, today: today),
              const Spacer(flex: 2),
              if (night != null)
                TextButton.icon(
                  onPressed: () => showSharePreview(context, ref, NightShare.of(night)),
                  style: TextButton.styleFrom(foregroundColor: Tokens.parchmentDim),
                  icon: LineIconView(LineIcon.share, size: 18, color: Tokens.parchmentDim),
                  label: const Text('Share', style: TextStyle(fontSize: 17)),
                ),
              TextButton(
                onPressed: () => context.go(Routes.tonight),
                style: TextButton.styleFrom(foregroundColor: Tokens.parchmentDim),
                child: const Text('Close the book', style: TextStyle(fontSize: 17)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.night});
  final NightView night;

  @override
  Widget build(BuildContext context) {
    final withQuote = night.pieces.where((p) => p.work.pullQuote != null).firstOrNull;
    if (withQuote == null) return const SizedBox();
    final w = withQuote.work;
    return Column(
      children: [
        Text(
          '“${w.pullQuote}”',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, height: 1.45, color: Tokens.parchment),
        ),
        const SizedBox(height: 14),
        Text(w.author.toUpperCase(), style: TextStyles.label(color: Tokens.amber, size: 11)),
      ],
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.week, required this.today});

  final List<bool> week;
  final LocalDate today;

  static const _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final start = today.addDays(-6);
    return Semantics(
      label: '${week.where((d) => d).length} of the last 7 days read',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 7; i++)
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: week[i] ? Tokens.amber : Colors.transparent,
                    border: Border.all(color: week[i] ? Tokens.amber : Tokens.parchmentFaint, width: 1.2),
                    boxShadow: week[i] ? [BoxShadow(color: Tokens.amber.withValues(alpha: 0.4), blurRadius: 8)] : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _initials[DateTime.utc(start.addDays(i).year, start.addDays(i).month, start.addDays(i).day).weekday -
                      1],
                  style: TextStyle(fontSize: 13, color: i == 6 ? Tokens.parchment : Tokens.parchmentDim),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
