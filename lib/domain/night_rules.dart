import 'local_date.dart';

/// What the app knows about the user's latest unlocked night.
class LatestNight {
  const LatestNight({
    required this.dayNumber,
    required this.unlockedOn,
    required this.completedOn,
    required this.piecesDone,
  });

  final int dayNumber;
  final LocalDate unlockedOn;
  final LocalDate? completedOn;
  final int piecesDone;
}

/// Night unlock rules from the PRD:
///
/// * Night N is the user's Nth night, not a calendar date, so users never
///   fall behind.
/// * The next night unlocks at local midnight, and only if the current night
///   has at least one piece read.
/// * At most one new night unlocks per calendar day, however long the user
///   was away.
class NightRules {
  const NightRules._();

  static const totalNights = 1000;

  /// Returns the day number that should be unlocked on [today], or null if
  /// the current night stays.
  static int? nightToUnlock(LatestNight? latest, LocalDate today) {
    if (latest == null) return 1;
    if (latest.dayNumber >= totalNights) return null;
    final done = latest.completedOn;
    if (latest.piecesDone < 1 || done == null) return null;
    // Read today: tomorrow's night waits for midnight. A clock moved
    // backwards (travel west) also lands here and unlocks nothing.
    if (today <= done) return null;
    return latest.dayNumber + 1;
  }
}
