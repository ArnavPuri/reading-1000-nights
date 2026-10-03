import 'local_date.dart';

class StreakState {
  const StreakState({this.current = 0, this.longest = 0, this.lastReadDate, this.freezesLeft = 0, this.freezesResetOn});

  final int current;
  final int longest;
  final LocalDate? lastReadDate;
  final int freezesLeft;
  final LocalDate? freezesResetOn;

  StreakState copyWith({
    int? current,
    int? longest,
    LocalDate? lastReadDate,
    int? freezesLeft,
    LocalDate? freezesResetOn,
  }) => StreakState(
    current: current ?? this.current,
    longest: longest ?? this.longest,
    lastReadDate: lastReadDate ?? this.lastReadDate,
    freezesLeft: freezesLeft ?? this.freezesLeft,
    freezesResetOn: freezesResetOn ?? this.freezesResetOn,
  );

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.longest == longest &&
      other.lastReadDate == lastReadDate &&
      other.freezesLeft == freezesLeft &&
      other.freezesResetOn == freezesResetOn;

  @override
  int get hashCode => Object.hash(current, longest, lastReadDate, freezesLeft, freezesResetOn);

  @override
  String toString() =>
      'StreakState(current: $current, longest: $longest, last: $lastReadDate, '
      'freezes: $freezesLeft, reset: $freezesResetOn)';
}

class StreakUpdate {
  const StreakUpdate(this.state, {this.broken = false, this.freezesUsed = 0});
  final StreakState state;

  /// True when this update reset a non-zero streak (the `streak_broken` event).
  final bool broken;
  final int freezesUsed;
}

/// Streak rules from the PRD:
///
/// * A day counts when at least one piece is finished that calendar day.
/// * The streak resets to zero on a missed day unless a freeze is available.
/// * Subscribers get two freezes a month, applied automatically. Free users
///   get none.
class StreakRules {
  const StreakRules._();

  static const freezesPerMonth = 2;

  /// Called when the app opens (or the day changes): refills freezes on a
  /// new month, spends freezes on missed days, or breaks the streak.
  static StreakUpdate onOpen(StreakState s, LocalDate today, {required bool subscriber}) {
    s = _refill(s, today, subscriber: subscriber);
    final last = s.lastReadDate;
    if (last == null || s.current == 0) return StreakUpdate(s);
    final missed = today.daysSince(last) - 1;
    if (missed <= 0) return StreakUpdate(s);
    if (missed <= s.freezesLeft) {
      // Each frozen day counts as kept; the streak itself does not grow.
      return StreakUpdate(
        s.copyWith(freezesLeft: s.freezesLeft - missed, lastReadDate: today.addDays(-1)),
        freezesUsed: missed,
      );
    }
    return StreakUpdate(
      StreakState(
        current: 0,
        longest: s.longest,
        lastReadDate: s.lastReadDate,
        freezesLeft: s.freezesLeft,
        freezesResetOn: s.freezesResetOn,
      ),
      broken: true,
    );
  }

  /// Called when a piece is finished on [today].
  static StreakUpdate onPieceFinished(StreakState s, LocalDate today, {required bool subscriber}) {
    final opened = onOpen(s, today, subscriber: subscriber);
    s = opened.state;
    final last = s.lastReadDate;
    if (last != null && today <= last) {
      // Already counted today (or the clock went backwards).
      return StreakUpdate(s, broken: opened.broken, freezesUsed: opened.freezesUsed);
    }
    final kept = last != null && today.daysSince(last) == 1 && s.current > 0;
    final current = kept ? s.current + 1 : 1;
    return StreakUpdate(
      s.copyWith(current: current, longest: current > s.longest ? current : s.longest, lastReadDate: today),
      broken: opened.broken,
      freezesUsed: opened.freezesUsed,
    );
  }

  static StreakState _refill(StreakState s, LocalDate today, {required bool subscriber}) {
    final reset = s.freezesResetOn;
    if (reset != null && today < reset) return s;
    return s.copyWith(freezesLeft: subscriber ? freezesPerMonth : 0, freezesResetOn: today.firstOfNextMonth);
  }
}
