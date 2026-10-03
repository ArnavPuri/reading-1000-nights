import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/candle.dart';
import '../../core/widgets/hairline_progress.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/reading_repository.dart';
import '../../domain/night_rules.dart';
import 'reading_card.dart';

class TonightScreen extends ConsumerWidget {
  const TonightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tonight = ref.watch(tonightProvider);
    return SafeArea(
      bottom: false,
      child: switch (tonight) {
        AsyncData(:final value) => _Tonight(view: value),
        AsyncError(:final error) => Center(child: Text('Could not load tonight: $error')),
        _ => const SizedBox(),
      },
    );
  }
}

class _Tonight extends StatelessWidget {
  const _Tonight({required this.view});

  final TonightView view;

  @override
  Widget build(BuildContext context) {
    final night = view.tonight;
    final day = night?.dayNumber ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 28, Tokens.gutter, 32),
      children: [
        _Header(day: day, streak: view.streak),
        const SizedBox(height: 40),
        if (night == null)
          const _EndOfContent()
        else ...[
          if (night.allDone)
            _NightDone(day: day, tomorrow: view.tomorrow)
          else
            const Text('Tonight’s reading', style: TextStyles.screenTitle),
          const SizedBox(height: 22),
          for (final p in night.pieces) ...[
            ReadingCard(work: p.work, done: p.done, onTap: () => context.push(Routes.read(day, p.work.id))),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.day, required this.streak});

  final int day;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: GestureDetector(
            // Debug menu: long-press the night counter (debug builds only).
            onLongPress: kDebugMode ? () => context.push(Routes.debug) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NIGHT $day OF ${NightRules.totalNights}', style: TextStyles.label(size: 13)),
                const SizedBox(height: 12),
                FractionallySizedBox(widthFactor: 0.82, child: HairlineProgress(value: day / NightRules.totalNights)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        CandleStreakBadge(count: streak),
      ],
    );
  }
}

class _NightDone extends StatelessWidget {
  const _NightDone({required this.day, required this.tomorrow});

  final int day;
  final List<Work>? tomorrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Night $day complete', style: TextStyles.screenTitle),
        const SizedBox(height: 10),
        Text('The next night unlocks at midnight.', style: TextStyles.byline),
        if (tomorrow != null) ...[
          const SizedBox(height: 28),
          Text('TOMORROW', style: TextStyles.label(color: Tokens.amber, size: 11.5)),
          const SizedBox(height: 12),
          for (final w in tomorrow!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: w.title,
                      style: const TextStyle(fontSize: 19, color: Tokens.parchment),
                    ),
                    TextSpan(text: '  ${w.author}', style: TextStyles.meta),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 18),
        Divider(color: Tokens.hairline, height: 1),
      ],
    );
  }
}

class _EndOfContent extends StatelessWidget {
  const _EndOfContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More nights are on their way', style: TextStyles.screenTitle),
        const SizedBox(height: 14),
        Text(
          'You have read every night we have so far. New nights download as they are ready.',
          style: TextStyles.byline,
        ),
      ],
    );
  }
}
