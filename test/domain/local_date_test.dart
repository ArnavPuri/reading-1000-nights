import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/domain/local_date.dart';

void main() {
  test('parses and prints YYYY-MM-DD', () {
    expect(LocalDate.parse('2026-03-09').toString(), '2026-03-09');
  });

  test('day arithmetic ignores daylight saving shifts', () {
    // US DST starts 2026-03-08, EU DST ends 2026-10-25.
    expect(const LocalDate(2026, 3, 8).daysSince(const LocalDate(2026, 3, 7)), 1);
    expect(const LocalDate(2026, 3, 7).addDays(1), const LocalDate(2026, 3, 8));
    expect(const LocalDate(2026, 10, 26).daysSince(const LocalDate(2026, 10, 25)), 1);
  });

  test('crosses month and year ends', () {
    expect(const LocalDate(2026, 12, 31).addDays(1), const LocalDate(2027, 1, 1));
    expect(const LocalDate(2028, 2, 28).addDays(1), const LocalDate(2028, 2, 29));
    expect(const LocalDate(2026, 12, 15).firstOfNextMonth, const LocalDate(2027, 1, 1));
  });

  test('a local DateTime just before and after midnight are different days', () {
    final before = LocalDate.fromDateTime(DateTime(2026, 10, 3, 23, 59, 59));
    final after = LocalDate.fromDateTime(DateTime(2026, 10, 4, 0, 0, 1));
    expect(after.daysSince(before), 1);
  });
}
