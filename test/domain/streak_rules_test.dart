import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/domain/local_date.dart';
import 'package:thousand_nights/domain/streak_rules.dart';

void main() {
  const d0 = LocalDate(2026, 10, 3);

  StreakState read(StreakState s, LocalDate day, {bool subscriber = false}) =>
      StreakRules.onPieceFinished(s, day, subscriber: subscriber).state;

  test('first piece starts a streak of 1', () {
    final s = read(const StreakState(), d0);
    expect(s.current, 1);
    expect(s.longest, 1);
    expect(s.lastReadDate, d0);
  });

  test('a second piece the same day does not count twice', () {
    final s = read(read(const StreakState(), d0), d0);
    expect(s.current, 1);
  });

  test('consecutive days grow the streak', () {
    var s = const StreakState();
    for (var i = 0; i < 7; i++) {
      s = read(s, d0.addDays(i));
    }
    expect(s.current, 7);
    expect(s.longest, 7);
  });

  test('a missed day resets the streak for free users', () {
    var s = read(read(const StreakState(), d0), d0.addDays(1)); // 2
    final open = StreakRules.onOpen(s, d0.addDays(3), subscriber: false);
    expect(open.broken, isTrue);
    expect(open.state.current, 0);
    expect(open.state.longest, 2);
    s = read(open.state, d0.addDays(3));
    expect(s.current, 1);
    expect(s.longest, 2);
  });

  test('reading just after midnight keeps the streak', () {
    final s = read(const StreakState(), LocalDate.fromDateTime(DateTime(2026, 10, 3, 23, 50)));
    final next = read(s, LocalDate.fromDateTime(DateTime(2026, 10, 4, 0, 10)));
    expect(next.current, 2);
  });

  test('subscribers get two freezes a month, applied automatically', () {
    var s = read(const StreakState(), d0, subscriber: true);
    expect(s.freezesLeft, 2);
    // miss one day
    final open = StreakRules.onOpen(s, d0.addDays(2), subscriber: true);
    expect(open.broken, isFalse);
    expect(open.freezesUsed, 1);
    expect(open.state.freezesLeft, 1);
    s = read(open.state, d0.addDays(2), subscriber: true);
    expect(s.current, 2, reason: 'a frozen day keeps the streak but does not add to it');
  });

  test('a gap longer than the freezes left breaks the streak and keeps the freezes', () {
    final s = read(const StreakState(), d0, subscriber: true);
    final open = StreakRules.onOpen(s, d0.addDays(4), subscriber: true); // 3 missed
    expect(open.broken, isTrue);
    expect(open.state.freezesLeft, 2);
  });

  test('freezes refill on the first of the month', () {
    var s = read(const StreakState(), const LocalDate(2026, 10, 30), subscriber: true);
    s = StreakRules.onOpen(s, const LocalDate(2026, 11, 1), subscriber: true).state;
    expect(s.freezesResetOn, const LocalDate(2026, 12, 1));
    expect(s.freezesLeft, 1, reason: 'refilled to 2 on Nov 1, then one spent on Oct 31');
  });

  test('free users never get freezes', () {
    final s = read(const StreakState(), d0);
    expect(s.freezesLeft, 0);
  });

  test('a clock moved backwards (time zone change) neither breaks nor grows the streak', () {
    final s = read(read(const StreakState(), d0), d0.addDays(1));
    final back = StreakRules.onOpen(s, d0, subscriber: false);
    expect(back.broken, isFalse);
    expect(read(back.state, d0).current, 2);
  });

  test('crossing a time zone east the same evening does not skip a day', () {
    // read at 23:00 on the 3rd; after flying east it is 07:00 on the 4th
    final s = read(const StreakState(), d0);
    final open = StreakRules.onOpen(s, d0.addDays(1), subscriber: false);
    expect(open.broken, isFalse);
    expect(read(open.state, d0.addDays(1)).current, 2);
  });
}
