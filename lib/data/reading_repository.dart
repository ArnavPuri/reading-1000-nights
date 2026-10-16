import 'package:drift/drift.dart';

import '../core/analytics.dart';
import '../domain/local_date.dart';
import '../domain/night_rules.dart';
import '../domain/streak_rules.dart';
import 'database.dart';

const pieceOrder = ['story', 'poem', 'essay'];

class NightPiece {
  const NightPiece({required this.work, required this.done, required this.scrollPos});
  final Work work;
  final bool done;
  final double scrollPos;
}

class NightView {
  const NightView({required this.night, required this.pieces});
  final Night night;
  final List<NightPiece> pieces;

  int get dayNumber => night.dayNumber;
  bool get allDone => pieces.every((p) => p.done);
}

class TonightView {
  const TonightView({required this.tonight, required this.streak, required this.tomorrow});

  /// Null only when the user is past the last night we have content for.
  final NightView? tonight;
  final int streak;

  /// Tomorrow's three works, if the pack has them.
  final List<Work>? tomorrow;
}

class JourneyView {
  const JourneyView({
    required this.nightsCompleted,
    required this.streak,
    required this.secondsRead,
    required this.litNights,
    required this.currentNight,
  });

  final int nightsCompleted;
  final int streak;
  final int secondsRead;
  final List<int> litNights;
  final int currentNight;
}

class FinishResult {
  const FinishResult({required this.dayNumber, required this.nightComplete});
  final int dayNumber;

  /// True when this finish completed all three pieces of the night.
  final bool nightComplete;
}

class HighlightWithWork {
  const HighlightWithWork(this.highlight, this.work);
  final Highlight highlight;
  final Work work;
}

class FavoriteWithWork {
  const FavoriteWithWork(this.favorite, this.work, this.dayNumber);
  final Favorite favorite;
  final Work work;

  /// The night the work belongs to, for opening it in the reader.
  final int dayNumber;
}

/// All reads and writes of reading state. Pure rules live in lib/domain;
/// this class loads state, applies them and stores the result.
class ReadingRepository {
  ReadingRepository(this.db, {Analytics? analytics}) : analytics = analytics ?? Analytics.noop;

  final AppDatabase db;
  final Analytics analytics;

  // ------------------------------------------------------------------------
  // Day rollover
  // ------------------------------------------------------------------------

  /// Unlocks tonight's night and settles the streak for [today]. Safe to call
  /// on every launch and resume.
  Future<void> ensureToday(LocalDate today, {bool subscriber = false}) async {
    await db.transaction(() async {
      final latest = await _latestNight();
      final next = NightRules.nightToUnlock(
        latest == null
            ? null
            : LatestNight(
                dayNumber: latest.dayNumber,
                unlockedOn: LocalDate.parse(latest.unlockedOn),
                completedOn: latest.completedOn == null ? null : LocalDate.parse(latest.completedOn!),
                piecesDone: latest.piecesDone,
              ),
        today,
      );
      if (next != null && await _hasContent(next)) {
        await db
            .into(db.nights)
            .insert(
              NightsCompanion.insert(dayNumber: Value(next), unlockedOn: today.toString()),
              mode: InsertMode.insertOrIgnore,
            );
      }

      final update = StreakRules.onOpen(await _streakState(), today, subscriber: subscriber);
      await _writeStreak(update.state);
      if (update.broken) {
        analytics.track(AnalyticsEvent.streakBroken, dayNumber: latest?.dayNumber);
      }
    });
  }

  // ------------------------------------------------------------------------
  // Reads
  // ------------------------------------------------------------------------

  /// Fires whenever any reading-state table changes.
  Stream<void> get changes => db
      .tableUpdates(
        TableUpdateQuery.onAllTables([db.nights, db.progress, db.streak, db.highlights, db.favorites, db.days]),
      )
      .map((_) {});

  Future<TonightView> tonight() async {
    final latest = await _latestNight();
    final streak = await db.getStreak();
    if (latest == null) return TonightView(tonight: null, streak: streak.current, tomorrow: null);
    final view = await night(latest.dayNumber);
    final tomorrowDay = await _day(latest.dayNumber + 1);
    return TonightView(
      tonight: view,
      streak: streak.current,
      tomorrow: tomorrowDay == null ? null : await _worksFor(tomorrowDay),
    );
  }

  Future<NightView?> night(int dayNumber) async {
    final n = await (db.select(db.nights)..where((t) => t.dayNumber.equals(dayNumber))).getSingleOrNull();
    final day = await _day(dayNumber);
    if (n == null || day == null) return null;
    final works = await _worksFor(day);
    final progress = await (db.select(db.progress)..where((p) => p.dayNumber.equals(dayNumber))).get();
    return NightView(
      night: n,
      pieces: [
        for (final w in works)
          () {
            final p = progress.where((p) => p.workId == w.id).firstOrNull;
            return NightPiece(work: w, done: p?.completedAt != null, scrollPos: p?.scrollPos ?? 0);
          }(),
      ],
    );
  }

  Future<Work> work(String id) => (db.select(db.works)..where((w) => w.id.equals(id))).getSingle();

  Future<ProgressRow?> progressFor(String workId, int dayNumber) =>
      (db.select(db.progress)..where((p) => p.workId.equals(workId) & p.dayNumber.equals(dayNumber))).getSingleOrNull();

  Future<JourneyView> journey() async {
    final nights = await (db.select(db.nights)..orderBy([(n) => OrderingTerm.asc(n.dayNumber)])).get();
    final streak = await db.getStreak();
    final seconds = db.progress.secondsRead.sum();
    final total = await (db.selectOnly(db.progress)..addColumns([seconds])).map((r) => r.read(seconds)).getSingle();
    final lit = [
      for (final n in nights)
        if (n.completedOn != null) n.dayNumber,
    ];
    return JourneyView(
      nightsCompleted: lit.length,
      streak: streak.current,
      secondsRead: total ?? 0,
      litNights: lit,
      currentNight: nights.isEmpty ? 0 : nights.last.dayNumber,
    );
  }

  /// Unlocked nights, newest first.
  Future<List<NightView>> library() async {
    final nights = await (db.select(db.nights)..orderBy([(n) => OrderingTerm.desc(n.dayNumber)])).get();
    return [for (final n in nights) ?await night(n.dayNumber)];
  }

  /// Seven booleans, oldest first, ending today: was anything finished that day?
  Future<List<bool>> week(LocalDate today) async {
    final from = today.addDays(-6);
    final rows = await (db.select(db.progress)..where((p) => p.completedAt.isNotNull())).get();
    final readDays = {for (final r in rows) LocalDate.fromDateTime(r.completedAt!)};
    final streak = await db.getStreak();
    if (streak.lastReadDate != null) readDays.add(LocalDate.parse(streak.lastReadDate!));
    return [for (var i = 0; i < 7; i++) readDays.contains(from.addDays(i))];
  }

  Future<List<Highlight>> highlightsFor(String workId) =>
      (db.select(db.highlights)..where((h) => h.workId.equals(workId))).get();

  Future<List<HighlightWithWork>> allHighlights() async {
    final q = db.select(db.highlights).join([innerJoin(db.works, db.works.id.equalsExp(db.highlights.workId))])
      ..orderBy([OrderingTerm.desc(db.highlights.createdAt)]);
    return [for (final r in await q.get()) HighlightWithWork(r.readTable(db.highlights), r.readTable(db.works))];
  }

  Future<bool> isFavorite(String workId) async =>
      await (db.select(db.favorites)..where((f) => f.workId.equals(workId))).getSingleOrNull() != null;

  /// Favourites, newest first, with the night each work belongs to.
  Future<List<FavoriteWithWork>> favorites() async {
    final q = db.select(db.favorites).join([innerJoin(db.works, db.works.id.equalsExp(db.favorites.workId))])
      ..orderBy([OrderingTerm.desc(db.favorites.createdAt)]);
    final rows = await q.get();
    final days = await _dayNumbersOf([for (final r in rows) r.readTable(db.favorites).workId]);
    return [
      for (final r in rows)
        if (days[r.readTable(db.favorites).workId] case final day?)
          FavoriteWithWork(r.readTable(db.favorites), r.readTable(db.works), day),
    ];
  }

  // ------------------------------------------------------------------------
  // Writes
  // ------------------------------------------------------------------------

  Future<void> startPiece(String workId, int dayNumber, DateTime now) async {
    final inserted = await db
        .into(db.progress)
        .insert(
          ProgressCompanion.insert(workId: workId, dayNumber: dayNumber, startedAt: now),
          mode: InsertMode.insertOrIgnore,
        );
    if (inserted > 0) analytics.track(AnalyticsEvent.pieceStarted, dayNumber: dayNumber);
  }

  Future<void> saveReading(String workId, int dayNumber, {required double scrollPos, int addSeconds = 0}) {
    return db.customUpdate(
      'UPDATE progress SET scroll_pos = ?, seconds_read = seconds_read + ? '
      'WHERE work_id = ? AND day_number = ?',
      variables: [
        Variable.withReal(scrollPos.clamp(0, 1)),
        Variable.withInt(addSeconds),
        Variable.withString(workId),
        Variable.withInt(dayNumber),
      ],
      updates: {db.progress},
    );
  }

  Future<FinishResult> finishPiece(
    String workId,
    int dayNumber, {
    required DateTime now,
    required LocalDate today,
    int addSeconds = 0,
    bool subscriber = false,
  }) async {
    return db.transaction(() async {
      await startPiece(workId, dayNumber, now);
      final before = await progressFor(workId, dayNumber);
      await (db.update(db.progress)..where((p) => p.workId.equals(workId) & p.dayNumber.equals(dayNumber))).write(
        ProgressCompanion(
          scrollPos: const Value(1),
          completedAt: Value(before?.completedAt ?? now),
          secondsRead: Value((before?.secondsRead ?? 0) + addSeconds),
        ),
      );
      if (before?.completedAt != null) {
        return FinishResult(dayNumber: dayNumber, nightComplete: false);
      }
      analytics.track(AnalyticsEvent.pieceCompleted, dayNumber: dayNumber);

      final done = await (db.select(
        db.progress,
      )..where((p) => p.dayNumber.equals(dayNumber) & p.completedAt.isNotNull())).get();
      final n = await (db.select(db.nights)..where((t) => t.dayNumber.equals(dayNumber))).getSingleOrNull();
      if (n != null) {
        await (db.update(db.nights)..where((t) => t.dayNumber.equals(dayNumber))).write(
          NightsCompanion(piecesDone: Value(done.length), completedOn: Value(n.completedOn ?? today.toString())),
        );
      }

      final update = StreakRules.onPieceFinished(await _streakState(), today, subscriber: subscriber);
      await _writeStreak(update.state);
      if (update.broken) analytics.track(AnalyticsEvent.streakBroken, dayNumber: dayNumber);

      final complete = done.length >= 3;
      if (complete) analytics.track(AnalyticsEvent.nightCompleted, dayNumber: dayNumber);
      return FinishResult(dayNumber: dayNumber, nightComplete: complete);
    });
  }

  Future<int> addHighlight(String workId, int start, int end, String text) {
    return db
        .into(db.highlights)
        .insert(
          HighlightsCompanion.insert(
            workId: workId,
            startOffset: start,
            endOffset: end,
            body: text,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> removeHighlight(int id) => (db.delete(db.highlights)..where((h) => h.id.equals(id))).go();

  /// Removes [removeIds] and stores one highlight in their place, in one
  /// transaction: how the reader merges overlapping highlights.
  Future<int> replaceHighlights(String workId, List<int> removeIds, int start, int end, String text) {
    return db.transaction(() async {
      await (db.delete(db.highlights)..where((h) => h.id.isIn(removeIds))).go();
      return addHighlight(workId, start, end, text);
    });
  }

  /// Adds or removes [workId] from the favourites. Returns the new state.
  Future<bool> toggleFavorite(String workId, {required DateTime now}) async {
    final added = await db.transaction(() async {
      final removed = await (db.delete(db.favorites)..where((f) => f.workId.equals(workId))).go();
      if (removed > 0) return false;
      await db.into(db.favorites).insert(FavoritesCompanion.insert(workId: workId, createdAt: now));
      return true;
    });
    final day = (await _dayNumbersOf([workId]))[workId];
    analytics.track(added ? AnalyticsEvent.favoriteAdded : AnalyticsEvent.favoriteRemoved, dayNumber: day);
    return added;
  }

  // ------------------------------------------------------------------------
  // Debug
  // ------------------------------------------------------------------------

  /// Rewrites history so that nights 1..n-1 were each read on consecutive
  /// days ending yesterday, and night n is unlocked today.
  Future<void> debugJumpTo(int n, LocalDate today) async {
    final maxDay = await (db.selectOnly(
      db.days,
    )..addColumns([db.days.dayNumber.max()])).map((r) => r.read(db.days.dayNumber.max())).getSingle();
    n = n.clamp(1, maxDay ?? 1);
    await db.resetUserState();
    final offset = (await db.getSettings()).debugDayOffset;
    await db.transaction(() async {
      for (var d = 1; d < n; d++) {
        final date = today.addDays(d - n);
        final day = (await _day(d))!;
        await db
            .into(db.nights)
            .insert(
              NightsCompanion.insert(
                dayNumber: Value(d),
                unlockedOn: date.toString(),
                completedOn: Value(date.toString()),
                piecesDone: const Value(3),
              ),
            );
        for (final id in [day.storyId, day.poemId, day.essayId]) {
          final w = await work(id);
          final at = DateTime(date.year, date.month, date.day, 21, 30);
          await db
              .into(db.progress)
              .insert(
                ProgressCompanion.insert(
                  workId: id,
                  dayNumber: d,
                  startedAt: at,
                  completedAt: Value(at),
                  scrollPos: const Value(1),
                  secondsRead: Value(w.estMinutes * 60),
                ),
              );
        }
      }
      await db.into(db.nights).insert(NightsCompanion.insert(dayNumber: Value(n), unlockedOn: today.toString()));
      await _writeStreak(
        StreakState(
          current: n - 1,
          longest: n - 1,
          lastReadDate: n > 1 ? today.addDays(-1) : null,
          freezesResetOn: today.firstOfNextMonth,
        ),
      );
      await db.update(db.settings).write(SettingsCompanion(debugDayOffset: Value(offset)));
    });
  }

  // ------------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------------

  Future<Night?> _latestNight() =>
      (db.select(db.nights)
            ..orderBy([(n) => OrderingTerm.desc(n.dayNumber)])
            ..limit(1))
          .getSingleOrNull();

  Future<Day?> _day(int n) => (db.select(db.days)..where((d) => d.dayNumber.equals(n))).getSingleOrNull();

  Future<bool> _hasContent(int n) async => await _day(n) != null;

  /// The night each of [workIds] belongs to. Works not on any night are left out.
  Future<Map<String, int>> _dayNumbersOf(List<String> workIds) async {
    if (workIds.isEmpty) return const {};
    final days =
        await (db.select(db.days)
              ..where((d) => d.storyId.isIn(workIds) | d.poemId.isIn(workIds) | d.essayId.isIn(workIds))
              ..orderBy([(d) => OrderingTerm.desc(d.dayNumber)]))
            .get();
    // Newest night first, so later rows win: a work on two nights maps to the earlier one.
    return {
      for (final d in days)
        for (final id in [d.storyId, d.poemId, d.essayId]) id: d.dayNumber,
    };
  }

  Future<List<Work>> _worksFor(Day day) async {
    final ids = [day.storyId, day.poemId, day.essayId];
    final works = await (db.select(db.works)..where((w) => w.id.isIn(ids))).get();
    return [for (final id in ids) works.firstWhere((w) => w.id == id)];
  }

  Future<StreakState> _streakState() async {
    final s = await db.getStreak();
    return StreakState(
      current: s.current,
      longest: s.longest,
      lastReadDate: s.lastReadDate == null ? null : LocalDate.parse(s.lastReadDate!),
      freezesLeft: s.freezesLeft,
      freezesResetOn: s.freezesResetOn == null ? null : LocalDate.parse(s.freezesResetOn!),
    );
  }

  Future<void> _writeStreak(StreakState s) => db
      .update(db.streak)
      .write(
        StreakCompanion(
          current: Value(s.current),
          longest: Value(s.longest),
          lastReadDate: Value(s.lastReadDate?.toString()),
          freezesLeft: Value(s.freezesLeft),
          freezesResetOn: Value(s.freezesResetOn?.toString()),
        ),
      );
}
