import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/reminders.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/data/reading_repository.dart';
import 'package:thousand_nights/domain/local_date.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../app_harness.dart';
import '../helpers.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('placing planned times in a time zone', () {
    test('21:30 stays 21:30 across the autumn change, so that night is 25 hours long', () {
      final ny = tz.getLocation('America/New_York');
      final before = zonedInstant(DateTime(2026, 10, 31, 21, 30), ny);
      final after = zonedInstant(DateTime(2026, 11, 1, 21, 30), ny);
      expect((before.hour, before.minute), (21, 30));
      expect((after.hour, after.minute), (21, 30));
      expect(before.timeZoneOffset, const Duration(hours: -4));
      expect(after.timeZoneOffset, const Duration(hours: -5));
      expect(after.toUtc().difference(before.toUtc()), const Duration(hours: 25));
    });

    test('a time skipped by the spring change moves forward by the gap', () {
      final ny = tz.getLocation('America/New_York');
      final at = zonedInstant(DateTime(2026, 3, 8, 2, 30), ny);
      expect((at.day, at.hour, at.minute), (8, 3, 30));
    });

    test('the same plan fires at local time wherever the user is', () {
      final plan = DateTime(2026, 10, 16, 21, 30);
      final london = zonedInstant(plan, tz.getLocation('Europe/London'));
      final tokyo = zonedInstant(plan, tz.getLocation('Asia/Tokyo'));
      expect((london.hour, tokyo.hour), (21, 21));
      expect(london.toUtc().difference(tokyo.toUtc()), const Duration(hours: 8));
    });
  });

  group('ReminderSync', () {
    late AppDatabase db;
    late ReadingRepository repo;
    late FakeReminderScheduler scheduler;
    late ReminderSync sync;
    final today = LocalDate(2026, 10, 3);
    var now = DateTime(2026, 10, 3, 18);

    setUp(() async {
      db = await seededDb();
      repo = ReadingRepository(db);
      scheduler = FakeReminderScheduler()..granted = true;
      sync = ReminderSync(db: db, repo: repo, scheduler: scheduler, clock: () => now);
      now = DateTime(2026, 10, 3, 18);
      await repo.debugJumpTo(3, today);
      await db.update(db.settings).write(const SettingsCompanion(reminderTime: Value('21:30')));
    });

    tearDown(() => db.close());

    test('schedules tonight’s night and the streak at risk, and drops it once a piece is read', () async {
      await sync.resume();
      final plan = scheduler.scheduled;
      expect(plan.first.title, 'Night 3 is waiting');
      expect(plan.first.body, 'Tonight: Araby, Where the Mind Is Without Fear, Walking Tours.');
      expect(plan.where((r) => r.title == 'Keep your 2-night streak').single.at, DateTime(2026, 10, 3, 22));

      final poem = (await repo.night(3))!.pieces[1].work;
      await repo.finishPiece(poem.id, 3, now: now, today: today);
      await sync.sync();
      final after = scheduler.scheduled;
      expect(after.where((r) => r.at == DateTime(2026, 10, 3, 22)), isEmpty);
      expect(after.where((r) => r.title.startsWith('Keep your 3-night')).single.at, DateTime(2026, 10, 4, 22));
      expect(after[1].title, 'Night 4 is waiting');
    });

    test('reschedules only when the plan or the time zone changes', () async {
      await sync.resume();
      await sync.sync();
      await sync.sync();
      expect(scheduler.plans, hasLength(1));

      // the user flies to Tokyo: same wall-clock plan, new zone
      scheduler.zone = 'Asia/Tokyo';
      await sync.resume();
      expect(scheduler.zoneReads, 2);
      expect(scheduler.plans, hasLength(2));
      expect(scheduler.plans[1], scheduler.plans[0]);
    });

    test('schedules nothing without permission, and nothing when reminders are off', () async {
      scheduler.granted = false;
      await sync.resume();
      expect(scheduler.scheduled, isEmpty);

      scheduler.granted = true;
      await db
          .update(db.settings)
          .write(const SettingsCompanion(reminderTime: Value(null), streakReminder: Value(false)));
      await sync.sync();
      expect(scheduler.scheduled, isEmpty);
    });
  });
}
