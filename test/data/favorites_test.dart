import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/analytics.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/data/reading_repository.dart';
import 'package:thousand_nights/domain/local_date.dart';

import '../helpers.dart';

class _RecordingAnalytics extends Analytics {
  final events = <(AnalyticsEvent, int?)>[];

  @override
  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}}) =>
      events.add((event, dayNumber));
}

void main() {
  const day1 = LocalDate(2026, 10, 3);
  final now = DateTime(2026, 10, 3, 21, 30);

  late AppDatabase db;
  late ReadingRepository repo;
  late _RecordingAnalytics analytics;

  setUp(() async {
    db = await seededDb();
    analytics = _RecordingAnalytics();
    repo = ReadingRepository(db, analytics: analytics);
    await repo.debugJumpTo(3, day1);
  });
  tearDown(() => db.close());

  Future<Work> pieceOf(int night, int i) async => (await repo.night(night))!.pieces[i].work;

  test('toggling a favourite turns it on, then off, and tracks both', () async {
    final poem = await pieceOf(2, 1);
    expect(await repo.isFavorite(poem.id), isFalse);

    expect(await repo.toggleFavorite(poem.id, now: now), isTrue);
    expect(await repo.isFavorite(poem.id), isTrue);
    expect((await repo.favorites()).single.work.id, poem.id);

    expect(await repo.toggleFavorite(poem.id, now: now), isFalse);
    expect(await repo.isFavorite(poem.id), isFalse);
    expect(await repo.favorites(), isEmpty);

    expect(analytics.events, [(AnalyticsEvent.favoriteAdded, 2), (AnalyticsEvent.favoriteRemoved, 2)]);
  });

  test('favourites are listed newest first with their night', () async {
    final story1 = await pieceOf(1, 0);
    final essay3 = await pieceOf(3, 2);
    final poem2 = await pieceOf(2, 1);
    await repo.toggleFavorite(story1.id, now: now);
    await repo.toggleFavorite(essay3.id, now: now.add(const Duration(minutes: 1)));
    await repo.toggleFavorite(poem2.id, now: now.add(const Duration(minutes: 2)));

    final favs = await repo.favorites();
    expect([for (final f in favs) f.work.id], [poem2.id, essay3.id, story1.id]);
    expect([for (final f in favs) f.dayNumber], [2, 3, 1]);
  });

  test('reset clears favourites', () async {
    await repo.toggleFavorite((await pieceOf(1, 0)).id, now: now);
    await db.resetUserState();
    expect(await repo.favorites(), isEmpty);
  });

  test('changes fires when a favourite is toggled', () async {
    final story = await pieceOf(1, 0);
    final fired = expectLater(repo.changes, emits(anything));
    await repo.toggleFavorite(story.id, now: now);
    await fired;
  });
}
