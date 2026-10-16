import 'local_date.dart';
import 'night_rules.dart';

/// A time of day, 'HH:mm' in settings.
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  /// Parses 'HH:mm'; null for null or anything malformed.
  static ReminderTime? tryParse(String? s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s ?? '');
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return ReminderTime(h, min);
  }

  final int hour;
  final int minute;

  /// "9:30 pm".
  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';
  }

  @override
  bool operator ==(Object other) => other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// One piece of tonight's night, as the reminder copy needs it.
class PieceTitle {
  const PieceTitle(this.title, {this.done = false});
  final String title;
  final bool done;
}

/// What the planner knows about the user's latest unlocked night.
class TonightInfo {
  const TonightInfo({required this.night, required this.pieces, this.tomorrow});

  final LatestNight night;
  final List<PieceTitle> pieces;

  /// The next night's titles, or null when no pack has it yet.
  final List<String>? tomorrow;
}

/// One local notification to schedule.
class PlannedReminder {
  const PlannedReminder({required this.id, required this.at, required this.title, required this.body});

  final int id;

  /// Local wall-clock time: year to minute in the user's time zone, not an
  /// instant. The scheduler places it in the current zone, so 21:30 stays
  /// 21:30 across daylight saving and travel.
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder && other.id == id && other.at == at && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  String toString() => 'PlannedReminder($id, $at, $title / $body)';
}

/// Plans the next week of reminders (PRD streak rules): one a day at the
/// chosen time, and one "streak at risk" reminder at 10 pm on a day nothing
/// has been read yet.
///
/// Notification copy is fixed when it is scheduled, so each day gets its own
/// one-shot notification naming that night. The plan assumes nothing more is
/// read until the app next runs: any read reschedules, so under that
/// assumption the night each day lands on is known (night N stays until a
/// piece of it is read; then N + 1 unlocks at the next midnight and stays).
/// Generic copy is used when tonight is unknown.
class ReminderPlanner {
  const ReminderPlanner._();

  static const days = 7;
  static const dailyBaseId = 100;
  static const streakBaseId = 200;

  /// "Two hours before midnight."
  static const streakAt = ReminderTime(22, 0);

  static const genericTitle = 'Tonight’s reading';
  static const genericBody = 'Tonight’s story, poem and essay are ready.';
  static const streakBody = 'A poem takes a minute. The candle is still lit.';

  static List<PlannedReminder> plan({
    required DateTime now,
    required ReminderTime? dailyAt,
    required bool streakReminder,
    required int streak,
    required LocalDate? lastReadDate,
    required TonightInfo? tonight,
  }) {
    final today = LocalDate.fromDateTime(now);
    final out = <PlannedReminder>[];

    if (dailyAt != null) {
      for (var d = 0; d < days; d++) {
        final date = today.addDays(d);
        final at = _at(date, dailyAt);
        if (!at.isAfter(now)) continue;
        final copy = _dailyCopy(tonight, date);
        if (copy == null) continue;
        out.add(PlannedReminder(id: dailyBaseId + d, at: at, title: copy.$1, body: copy.$2));
      }
    }

    if (streakReminder) {
      // A streak is alive while the last read was today or yesterday.
      final alive = streak >= 1 && lastReadDate != null && today.daysSince(lastReadDate) <= 1;
      final readToday = lastReadDate == today;
      // Not read today: tonight is at risk. Read today: tomorrow will be,
      // until something is read then (which reschedules).
      final d = readToday ? 1 : 0;
      final at = _at(today.addDays(d), streakAt);
      if (alive && at.isAfter(now)) {
        out.add(
          PlannedReminder(id: streakBaseId + d, at: at, title: 'Keep your $streak-night streak', body: streakBody),
        );
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  static DateTime _at(LocalDate date, ReminderTime t) => DateTime(date.year, date.month, date.day, t.hour, t.minute);

  /// Title and body for the daily reminder on [date], or null for none.
  static (String, String)? _dailyCopy(TonightInfo? tonight, LocalDate date) {
    if (tonight == null) return (genericTitle, genericBody);
    final latest = tonight.night;
    final night = NightRules.nightToUnlock(latest, date) ?? latest.dayNumber;
    final List<String>? titles;
    if (night == latest.dayNumber) {
      // Only what is still unread; nothing at all once the night is done.
      titles = [
        for (final p in tonight.pieces)
          if (!p.done) p.title,
      ];
      if (titles.isEmpty) return null;
    } else {
      // The next night: none when it has no content yet, since it will not
      // unlock without it.
      titles = tonight.tomorrow;
      if (titles == null || titles.isEmpty) return null;
    }
    final list = titles.join(', ');
    return ('Night $night is waiting', 'Tonight: $list${RegExp(r'[.!?]$').hasMatch(list) ? '' : '.'}');
  }
}
