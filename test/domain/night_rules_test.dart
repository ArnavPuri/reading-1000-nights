import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/domain/local_date.dart';
import 'package:thousand_nights/domain/night_rules.dart';

void main() {
  const oct3 = LocalDate(2026, 10, 3);

  LatestNight night(int n, {LocalDate? completedOn, int pieces = 0}) =>
      LatestNight(dayNumber: n, unlockedOn: oct3, completedOn: completedOn, piecesDone: pieces);

  test('a new user starts on night 1', () {
    expect(NightRules.nightToUnlock(null, oct3), 1);
  });

  test('nothing unlocks while tonight has no piece read', () {
    expect(NightRules.nightToUnlock(night(1), oct3.addDays(1)), isNull);
    expect(NightRules.nightToUnlock(night(1), oct3.addDays(30)), isNull);
  });

  test('reading tonight unlocks the next night at local midnight, not before', () {
    final read = night(1, completedOn: oct3, pieces: 1);
    expect(NightRules.nightToUnlock(read, oct3), isNull);
    expect(NightRules.nightToUnlock(read, oct3.addDays(1)), 2);
  });

  test('users never fall behind: a long gap unlocks only one night', () {
    final read = night(4, completedOn: oct3, pieces: 3);
    expect(NightRules.nightToUnlock(read, oct3.addDays(12)), 5);
  });

  test('clock moved backwards (time zone change west) unlocks nothing', () {
    final read = night(2, completedOn: oct3, pieces: 1);
    expect(NightRules.nightToUnlock(read, oct3.addDays(-1)), isNull);
  });

  test('stops at night 1000', () {
    final read = night(1000, completedOn: oct3, pieces: 3);
    expect(NightRules.nightToUnlock(read, oct3.addDays(1)), isNull);
  });
}
