/// A calendar date in the user's local time zone, with no time of day.
///
/// Day arithmetic goes through UTC so daylight-saving shifts never make a
/// "day" 23 or 25 hours long.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime t) => LocalDate(t.year, t.month, t.day);

  /// Parses 'YYYY-MM-DD'.
  factory LocalDate.parse(String s) {
    final p = s.split('-').map(int.parse).toList();
    return LocalDate(p[0], p[1], p[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int n) => LocalDate.fromDateTime(_utc.add(Duration(days: n)));

  /// Whole days from [other] to this date (positive when this is later).
  int daysSince(LocalDate other) => _utc.difference(other._utc).inDays;

  LocalDate get firstOfNextMonth => month == 12 ? LocalDate(year + 1, 1, 1) : LocalDate(year, month + 1, 1);

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  bool operator <(LocalDate o) => compareTo(o) < 0;
  bool operator <=(LocalDate o) => compareTo(o) <= 0;
  bool operator >(LocalDate o) => compareTo(o) > 0;
  bool operator >=(LocalDate o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
