import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/reminders.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../domain/reminder_plan.dart';
import 'reminder_controls.dart';

/// The default reminder time: "We'll remind you at 9:30 pm."
const defaultReminderTime = ReminderTime(21, 30);

/// Reminders, from the gear on Journey: the daily reminder and its time,
/// and the 10 pm streak reminder.
Future<void> showRemindersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const _RemindersSheet(),
  );
}

class _RemindersSheet extends ConsumerStatefulWidget {
  const _RemindersSheet();

  @override
  ConsumerState<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends ConsumerState<_RemindersSheet> {
  /// Null until known. Reminders stored as on still show as off without it.
  bool? _permitted;

  /// iOS said no when asked: show how to turn notifications on in Settings.
  var _denied = false;

  /// The time last shown, so turning the reminder off and on keeps it.
  ReminderTime? _time;

  @override
  void initState() {
    super.initState();
    ref.read(reminderSchedulerProvider).hasPermission().then((p) {
      if (mounted) setState(() => _permitted = p);
    });
  }

  Future<void> _write(SettingsCompanion change) {
    final db = ref.read(databaseProvider);
    return db.update(db.settings).write(change);
  }

  Future<void> _turnOn({ReminderTime? daily, bool? streak}) async {
    final ok = await turnOnReminders(ref.read, daily: daily, streak: streak);
    if (mounted) {
      setState(() {
        _permitted = ok;
        _denied = !ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider).value;
    if (s == null) return const SizedBox(height: 320);
    final stored = ReminderTime.tryParse(s.reminderTime);
    final time = _time = stored ?? _time ?? defaultReminderTime;
    final daily = stored != null && _permitted != false;
    final streak = s.streakReminder && _permitted != false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REMINDERS', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
            const SizedBox(height: 14),
            _Row(
              title: 'Daily reminder',
              detail: daily ? 'One a day, at ${time.label}.' : 'One quiet reminder a day.',
              toggle: QuietToggle(
                value: daily,
                semantics: 'Daily reminder',
                onChanged: (on) =>
                    on ? _turnOn(daily: time) : _write(const SettingsCompanion(reminderTime: Value(null))),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                child: daily
                    ? Padding(
                        key: const ValueKey('time'),
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: ReminderTimePicker(
                          value: time,
                          onChanged: (t) {
                            _time = t;
                            _write(SettingsCompanion(reminderTime: Value('$t')));
                          },
                        ),
                      )
                    : const SizedBox(key: ValueKey('none'), width: double.infinity),
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: Tokens.hairline, height: 1),
            const SizedBox(height: 14),
            _Row(
              title: 'Streak reminder at 10 pm',
              detail: 'Only on days you haven’t read yet.',
              toggle: QuietToggle(
                value: streak,
                semantics: 'Streak reminder at 10 pm',
                onChanged: (on) =>
                    on ? _turnOn(streak: true) : _write(const SettingsCompanion(streakReminder: Value(false))),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              child: _denied ? const _DeniedNote() : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.detail, required this.toggle});

  final String title;
  final String detail;
  final Widget toggle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, color: Tokens.parchment, height: 1.25)),
            const SizedBox(height: 3),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(detail, key: ValueKey(detail), style: TextStyles.meta),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      toggle,
    ],
  );
}

/// Shown when iOS has notifications turned off for the app.
class _DeniedNote extends ConsumerWidget {
  const _DeniedNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications are off for 1000 Nights. To get reminders, turn them on in Settings, '
          'under Notifications.',
          style: TextStyles.byline.copyWith(fontSize: 15.5, height: 1.45, color: Tokens.parchmentDim),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => ref.read(reminderSchedulerProvider).openSystemSettings(),
          style: TextButton.styleFrom(
            foregroundColor: Tokens.amber,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            alignment: Alignment.centerLeft,
            textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 16.5),
          ),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
