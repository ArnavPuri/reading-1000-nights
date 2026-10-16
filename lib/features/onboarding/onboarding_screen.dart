import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/reminders.dart';
import '../../core/theme.dart';
import '../../core/widgets/candle.dart';
import '../../data/database.dart';
import '../../domain/reminder_plan.dart';
import '../reminders/reminder_controls.dart';
import '../reminders/reminders_sheet.dart';
import '../tonight/reading_card.dart';
import 'explainers.dart';
import 'stage.dart';

/// First run (PRD onboarding, minus the trial offer): the positioning line,
/// how a night works on a real card, the reader, the candle and stars, when
/// you read, reminders asked in context, then night one.
///
/// Pages cross-fade; swipe or the button moves on. The router sends the
/// user here while `settings.onboarding_done` is false and on to Tonight
/// once it is set.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Page { welcome, card, reader, journey, time, notify, begin }

/// Reading-time presets: they set the wheel, which can then be fine-tuned.
const _presets = [
  ('Morning', ReminderTime(8, 0)),
  ('Evening', ReminderTime(19, 0)),
  ('Before bed', defaultReminderTime),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _page = _Page.welcome;
  var _time = defaultReminderTime;
  var _busy = false;

  bool get _explainer => _page == _Page.card || _page == _Page.reader || _page == _Page.journey;

  void _go(_Page p) => setState(() => _page = p);

  void _next() {
    // Swiping past the reminders page is "Not now"; the last page needs
    // its button.
    if (_page.index < _Page.values.length - 1) _go(_Page.values[_page.index + 1]);
  }

  void _back() {
    if (_page.index > 0) _go(_Page.values[_page.index - 1]);
  }

  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    await turnOnReminders(ref.read, daily: _time, streak: true);
    if (!mounted) return;
    setState(() => _busy = false);
    // TODO(paywall): the PRD's skippable 7-day trial offer goes here, between
    // reminders and "Begin night one" (phase 3).
    _go(_Page.begin);
  }

  Future<void> _notNow() async {
    final db = ref.read(databaseProvider);
    await db.update(db.settings).write(const SettingsCompanion(reminderTime: Value(null)));
    // TODO(paywall): the trial offer goes here too.
    _go(_Page.begin);
  }

  Future<void> _begin() async {
    if (_busy) return;
    _busy = true;
    final db = ref.read(databaseProvider);
    final s = await db.getSettings();
    final day = (await ref.read(repositoryProvider).tonight()).tonight?.dayNumber;
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvent.onboardingCompleted, dayNumber: day, props: {'reminder_time': s.reminderTime ?? 'off'});
    // The router's redirect takes it from here to Tonight.
    await db.update(db.settings).write(const SettingsCompanion(onboardingDone: Value(true)));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Tokens.ink,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) _next();
          if (v > 250) _back();
        },
        child: Stack(
          children: [
            // the welcome engraving bleeds under the status bar
            _fade(
              _page == _Page.welcome ? const _WelcomeArt(key: ValueKey('art')) : const SizedBox.expand(),
              expand: true,
            ),
            Padding(
              padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _explainer ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !_explainer,
                          child: TextButton(
                            onPressed: () => _go(_Page.time),
                            style: TextButton.styleFrom(
                              foregroundColor: Tokens.parchmentDim,
                              padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                              minimumSize: const Size(64, 44),
                              textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 16.5),
                            ),
                            child: const Text('Skip'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _fade(KeyedSubtree(key: ValueKey(_page), child: _content()), expand: true),
                  ),
                  const SizedBox(height: 18),
                  _Dots(count: _Page.values.length, active: _page.index),
                  const SizedBox(height: 22),
                  _fade(KeyedSubtree(key: ValueKey(_page), child: _actions())),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Cross-fades between screens. Nothing bounces." With [expand] the
  /// pages fill the space they are given.
  Widget _fade(Widget child, {bool expand = false}) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 650),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: expand
        ? (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current])
        : AnimatedSwitcher.defaultLayoutBuilder,
    child: child,
  );

  Widget _content() => switch (_page) {
    _Page.welcome => const _Welcome(),
    _Page.card => const CardExplainer(),
    _Page.reader => const ReaderExplainer(),
    _Page.journey => const JourneyExplainer(),
    _Page.time => _TimePage(time: _time, onChanged: (t) => setState(() => _time = t)),
    _Page.notify => _NotifyPage(time: _time),
    _Page.begin => const _BeginPage(),
  };

  Widget _actions() {
    final (label, onTap) = switch (_page) {
      _Page.welcome => ('Begin', _next),
      _Page.card || _Page.reader || _Page.journey || _Page.time => ('Continue', _next),
      _Page.notify => ('Allow', _allow),
      _Page.begin => ('Begin night one', _begin),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        children: [
          _PrimaryButton(label: label, onTap: onTap),
          SizedBox(
            height: 48,
            child: _page == _Page.notify
                ? TextButton(
                    onPressed: _busy ? null : _notNow,
                    style: TextButton.styleFrom(
                      foregroundColor: Tokens.parchmentDim,
                      minimumSize: const Size(120, 44),
                      textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 17),
                    ),
                    child: const Text('Not now'),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Tokens.amber,
        foregroundColor: Tokens.ink,
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 18, letterSpacing: 0.5),
      ),
      child: Text(label),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Page ${active + 1} of $count',
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: i == active ? 7 : 5,
            height: i == active ? 7 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == active ? Tokens.amber : Tokens.parchmentFaint,
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Welcome
// ---------------------------------------------------------------------------

/// The candle engraving, drifting slowly into place under a dark fade.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Stage(
      length: const Duration(milliseconds: 3200),
      child: Builder(
        builder: (context) {
          final t = Stage.interval(context, Duration.zero, span: const Duration(milliseconds: 3200));
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h * 0.62,
                child: AnimatedBuilder(
                  animation: t,
                  builder: (context, child) => Opacity(
                    opacity: t.value,
                    child: Transform.scale(scale: 1.08 - 0.08 * t.value, child: child),
                  ),
                  child: Image.asset(
                    'assets/packs/pack-001/images/candle.webp',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.42, 0),
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h * 0.62 + 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.22, 0.6, 1],
                      colors: [Color(0xCC12151F), Color(0x0012151F), Color(0x4D12151F), Tokens.ink],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => Stage(
    length: const Duration(milliseconds: 3400),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Reveal(
            at: ms(900),
            child: Text('1000 NIGHTS', style: TextStyles.label(color: Tokens.amber, size: 12)),
          ),
          const SizedBox(height: 18),
          Reveal(
            at: ms(1200),
            rise: 18,
            duration: ms(1200),
            child: const Text('A thousand nights.', style: TextStyles.screenTitle),
          ),
          const SizedBox(height: 10),
          Reveal(
            at: ms(1700),
            rise: 18,
            duration: ms(1200),
            child: Text(
              'One story, one poem,\none essay.',
              style: TextStyles.screenTitle.copyWith(fontSize: 30, color: Tokens.parchment.withValues(alpha: 0.78)),
            ),
          ),
          const SizedBox(height: 22),
          Reveal(
            at: ms(2300),
            child: Text(
              'A night of reading takes about twenty minutes. There are a thousand of them.',
              style: TextStyles.byline.copyWith(fontSize: 17, height: 1.45, color: Tokens.parchmentDim),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// When do you read?
// ---------------------------------------------------------------------------

class _TimePage extends StatelessWidget {
  const _TimePage({required this.time, required this.onChanged});

  final ReminderTime time;
  final ValueChanged<ReminderTime> onChanged;

  @override
  Widget build(BuildContext context) => Stage(
    length: const Duration(milliseconds: 2000),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            label: 'YOUR READING TIME',
            title: 'When do you read?',
            detail: 'We’ll send one quiet reminder a day, at your time.',
          ),
          const Spacer(),
          Reveal(
            at: ms(450),
            child: Row(
              children: [
                for (final (label, t) in _presets) ...[
                  Expanded(
                    child: _PresetChip(label: label, time: t, selected: t == time, onTap: () => onChanged(t)),
                  ),
                  if (label != _presets.last.$1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 34),
          Reveal(
            at: ms(700),
            child: Text('EXACT TIME', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
          ),
          const SizedBox(height: 8),
          Reveal(
            at: ms(800),
            child: ReminderTimePicker(value: time, onChanged: onChanged, height: 176),
          ),
          const Spacer(flex: 2),
        ],
      ),
    ),
  );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.time, required this.selected, required this.onTap});

  final String label;
  final ReminderTime time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label, ${time.label}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 74,
        decoration: BoxDecoration(
          color: Tokens.inkRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Tokens.amber : Tokens.hairline, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 17, color: Tokens.parchment)),
            const SizedBox(height: 5),
            Text(time.label, style: TextStyle(fontSize: 14, color: selected ? Tokens.amber : Tokens.parchmentDim)),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Notifications, asked in context
// ---------------------------------------------------------------------------

class _NotifyPage extends ConsumerWidget {
  const _NotifyPage({required this.time});

  final ReminderTime time;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(tonightProvider).value?.tonight;
    final titles = night == null ? null : [for (final p in night.pieces) p.work.title];
    return Stage(
      length: const Duration(milliseconds: 2400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              label: 'REMINDERS',
              title: 'We’ll remind you at ${time.label}.',
              detail: 'One a day, and one at 10 pm if your streak is at risk. Change them any time from Journey.',
            ),
            const Spacer(),
            Reveal(
              at: ms(700),
              rise: 22,
              duration: ms(1200),
              child: _NotificationPreview(
                title: 'Night ${night?.dayNumber ?? 1} is waiting',
                body: titles == null ? 'Tonight’s story, poem and essay are ready.' : 'Tonight: ${titles.join(', ')}.',
                time: time,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// What the reminder will look like on the lock screen.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.title, required this.body, required this.time});

  final String title;
  final String body;
  final ReminderTime time;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 18, 16),
    decoration: BoxDecoration(
      color: Tokens.inkRaised,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Tokens.hairline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Tokens.ink,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Tokens.hairline),
          ),
          child: const Center(child: Candle(height: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('1000 NIGHTS', style: TextStyles.label(color: Tokens.parchmentDim, size: 10)),
                  ),
                  Text(time.label, style: TextStyle(fontSize: 13, color: Tokens.parchmentDim)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Tokens.parchment),
              ),
              const SizedBox(height: 3),
              Text(body, style: TextStyles.byline.copyWith(fontSize: 15.5, height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Begin night one
// ---------------------------------------------------------------------------

/// Tonight's three pieces under a candle that lights as the page arrives.
class _BeginPage extends ConsumerWidget {
  const _BeginPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = ref.watch(tonightProvider).value?.tonight;
    final day = night?.dayNumber ?? 1;
    return Stage(
      length: const Duration(milliseconds: 3000),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Builder(
              builder: (context) {
                final lit = Stage.interval(context, ms(500), span: ms(1400));
                return SizedBox(
                  height: 96,
                  child: Stack(
                    children: [
                      const Candle(height: 96, lit: false),
                      FadeTransition(opacity: lit, child: const Candle(height: 96, flicker: true)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Reveal(
              at: ms(900),
              child: Text('NIGHT $day OF 1000', style: TextStyles.label(color: Tokens.amber, size: 12)),
            ),
            const SizedBox(height: 14),
            Reveal(
              at: ms(1050),
              child: Text(
                day == 1 ? 'Night one is ready.' : 'Night $day is ready.',
                style: TextStyles.screenTitle.copyWith(fontSize: 38),
              ),
            ),
            const SizedBox(height: 26),
            if (night != null)
              for (var i = 0; i < night.pieces.length; i++)
                Reveal(
                  at: ms(1400 + i * 250),
                  child: _PieceLine(work: night.pieces[i].work),
                ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _PieceLine extends StatelessWidget {
  const _PieceLine({required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Tokens.hairline)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(typeLabel(work.type), style: TextStyles.label(color: Tokens.parchmentDim, size: 10)),
              const SizedBox(height: 6),
              Text(
                work.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, color: Tokens.parchment),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('${work.estMinutes} min', style: TextStyles.meta),
      ],
    ),
  );
}
