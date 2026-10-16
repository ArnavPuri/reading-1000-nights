import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/domain/local_date.dart';
import 'package:thousand_nights/domain/night_rules.dart';
import 'package:thousand_nights/domain/reminder_plan.dart';

final _today = LocalDate(2026, 10, 3);
final _yesterday = _today.addDays(-1);
final _evening = DateTime(2026, 10, 3, 18);
const _bedtime = ReminderTime(21, 30);

const _night12 = ['The Gift of the Magi', 'Hope', 'On Reading and Books'];
const _night13 = ['Araby', 'The Chariot', 'Walking'];

/// Night 12, unlocked today, with the pieces in [done] finished today.
TonightInfo _tonight({Set<int> done = const {}, List<String>? tomorrow = _night13}) => TonightInfo(
  night: LatestNight(
    dayNumber: 12,
    unlockedOn: _today,
    completedOn: done.isEmpty ? null : _today,
    piecesDone: done.length,
  ),
  pieces: [for (var i = 0; i < 3; i++) PieceTitle(_night12[i], done: done.contains(i))],
  tomorrow: tomorrow,
);

List<PlannedReminder> _plan({
  DateTime? now,
  ReminderTime? dailyAt = _bedtime,
  bool streakReminder = true,
  int streak = 6,
  LocalDate? lastReadDate,
  TonightInfo? tonight,
  bool unknownTonight = false,
}) => ReminderPlanner.plan(
  now: now ?? _evening,
  dailyAt: dailyAt,
  streakReminder: streakReminder,
  streak: streak,
  lastReadDate: lastReadDate ?? _yesterday,
  tonight: unknownTonight ? null : tonight ?? _tonight(),
);

Iterable<PlannedReminder> _daily(List<PlannedReminder> plan) => plan.where((r) => r.id < ReminderPlanner.streakBaseId);
Iterable<PlannedReminder> _streak(List<PlannedReminder> plan) =>
    plan.where((r) => r.id >= ReminderPlanner.streakBaseId);

void main() {
  test('a week of daily reminders, each naming the night and its titles', () {
    final daily = _daily(_plan()).toList();
    expect(daily, hasLength(7));
    expect([for (final r in daily) r.id], [100, 101, 102, 103, 104, 105, 106]);
    expect(daily.first.at, DateTime(2026, 10, 3, 21, 30));
    expect(daily.last.at, DateTime(2026, 10, 9, 21, 30));
    // Nothing read tonight: night 12 stays until a piece of it is read.
    for (final r in daily) {
      expect(r.title, 'Night 12 is waiting');
      expect(r.body, 'Tonight: The Gift of the Magi, Hope, On Reading and Books.');
    }
  });

  test('once a piece is read, today lists what is left and later days name the next night', () {
    final plan = _plan(
      tonight: _tonight(done: {1}),
      lastReadDate: _today,
      streak: 7,
    );
    final daily = _daily(plan).toList();
    expect(daily.first.title, 'Night 12 is waiting');
    expect(daily.first.body, 'Tonight: The Gift of the Magi, On Reading and Books.');
    for (final r in daily.skip(1)) {
      expect(r.title, 'Night 13 is waiting');
      expect(r.body, 'Tonight: Araby, The Chariot, Walking.');
    }
  });

  test('no daily reminder tonight once all three pieces are read', () {
    final daily = _daily(
      _plan(
        tonight: _tonight(done: {0, 1, 2}),
        lastReadDate: _today,
      ),
    ).toList();
    expect(daily.first.at, DateTime(2026, 10, 4, 21, 30));
    expect(daily.first.title, 'Night 13 is waiting');
    expect(daily, hasLength(6));
  });

  test('a time already past today starts tomorrow', () {
    final daily = _daily(_plan(now: DateTime(2026, 10, 3, 21, 30))).toList();
    expect(daily.first.at, DateTime(2026, 10, 4, 21, 30));
    expect(daily, hasLength(6));
  });

  test('streak at risk: 10 pm tonight while nothing is read and the streak is alive', () {
    final streak = _streak(_plan()).single;
    expect(streak.id, ReminderPlanner.streakBaseId);
    expect(streak.at, DateTime(2026, 10, 3, 22));
    expect(streak.title, 'Keep your 6-night streak');
    expect(streak.body, 'A poem takes a minute. The candle is still lit.');
  });

  test('streak at risk is skipped tonight once a piece is read, and moves to tomorrow', () {
    final streak = _streak(
      _plan(
        tonight: _tonight(done: {0}),
        lastReadDate: _today,
        streak: 7,
      ),
    ).single;
    expect(streak.id, ReminderPlanner.streakBaseId + 1);
    expect(streak.at, DateTime(2026, 10, 4, 22));
    expect(streak.title, 'Keep your 7-night streak');
  });

  test('no streak at risk without a streak, after 10 pm, or when the streak has already broken', () {
    expect(_streak(_plan(streak: 0)), isEmpty);
    expect(_streak(_plan(now: DateTime(2026, 10, 3, 22, 5))), isEmpty);
    // The stored streak is stale until the app settles the day: two days
    // since the last read means it is already gone.
    expect(_streak(_plan(lastReadDate: _today.addDays(-2))), isEmpty);
  });

  test('reminders off', () {
    expect(_plan(dailyAt: null, streakReminder: false), isEmpty);
    expect(_plan(dailyAt: null).single.id, ReminderPlanner.streakBaseId);
    expect(_streak(_plan(streakReminder: false)), isEmpty);
    expect(_daily(_plan(streakReminder: false)), hasLength(7));
  });

  test('generic copy when tonight is not known', () {
    final daily = _daily(_plan(unknownTonight: true)).toList();
    expect(daily, hasLength(7));
    expect(daily.first.title, 'Tonight’s reading');
    expect(daily.first.body, 'Tonight’s story, poem and essay are ready.');
  });

  test('no reminders for a next night that has no content yet', () {
    final daily = _daily(
      _plan(
        tonight: _tonight(done: {0}, tomorrow: null),
        lastReadDate: _today,
      ),
    ).toList();
    expect(daily.single.at, DateTime(2026, 10, 3, 21, 30));
    expect(daily.single.body, 'Tonight: Hope, On Reading and Books.');
  });

  test('plans in local wall-clock time, so the time of day holds across a daylight saving change', () {
    // US clocks go back on 1 November 2026.
    final daily = _daily(_plan(now: DateTime(2026, 10, 29, 9))).toList();
    expect({for (final r in daily) (r.at.hour, r.at.minute)}, {(21, 30)});
    expect([for (final r in daily) r.at.day], [29, 30, 31, 1, 2, 3, 4]);
  });

  test('reminder times parse from settings and read as 12-hour times', () {
    expect(ReminderTime.tryParse('21:30'), const ReminderTime(21, 30));
    expect(ReminderTime.tryParse('8:05'), const ReminderTime(8, 5));
    expect(ReminderTime.tryParse(null), isNull);
    expect(ReminderTime.tryParse('25:00'), isNull);
    expect(ReminderTime.tryParse('nine'), isNull);
    expect(const ReminderTime(21, 30).label, '9:30 pm');
    expect(const ReminderTime(8, 0).label, '8:00 am');
    expect(const ReminderTime(0, 15).label, '12:15 am');
    expect(const ReminderTime(12, 0).label, '12:00 pm');
    expect('${const ReminderTime(8, 0)}', '08:00');
  });
}
