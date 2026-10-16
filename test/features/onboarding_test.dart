import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/analytics.dart';
import 'package:thousand_nights/core/providers.dart';
import 'package:thousand_nights/core/router.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/domain/reminder_plan.dart';

import '../app_harness.dart';
import '../helpers.dart';

class _RecordingAnalytics extends Analytics {
  final events = <(AnalyticsEvent, int?, Map<String, Object?>)>[];

  @override
  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}}) =>
      events.add((event, dayNumber, props));
}

/// A Semantics-labelled control, without turning semantics on.
Finder _labelled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await settle(tester);
}

Future<SettingsRow> _settings(WidgetTester tester, AppDatabase db) async => (await tester.runAsync(db.getSettings))!;

void main() {
  testWidgets('a fresh install lands on onboarding', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    await pumpApp(tester, db, onboardingDone: false);

    expect(find.text('A thousand nights.'), findsOneWidget);
    expect(find.text('One story, one poem,\none essay.'), findsOneWidget);
    expect(find.text('Tonight’s reading'), findsNothing);

    await tearDownApp(tester, db);
  });

  testWidgets('walking through onboarding: Before bed, Allow, Begin night one', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    final reminders = FakeReminderScheduler();
    final analytics = _RecordingAnalytics();
    await pumpApp(
      tester,
      db,
      onboardingDone: false,
      reminders: reminders,
      overrides: [analyticsProvider.overrideWithValue(analytics)],
    );

    await _tap(tester, find.text('Begin'));
    // how a night works, on night 1's story
    expect(find.text('Three cards a night'), findsOneWidget);
    expect(find.text('The Nightingale and the Rose'), findsOneWidget);
    expect(find.text('Finished pieces dim, with a check'), findsOneWidget);
    await _tap(tester, find.text('Continue'));
    expect(find.text('Long-press a line to highlight it.'), findsOneWidget);
    // swipe on to the candle and stars
    await tester.fling(find.text('Read at your pace'), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('A star for every night'), findsOneWidget);
    await _tap(tester, find.text('Continue'));

    expect(find.text('When do you read?'), findsOneWidget);
    await _tap(tester, find.text('Morning'));
    expect(find.text('8:00 am'), findsOneWidget);
    await _tap(tester, find.text('Before bed'));
    await _tap(tester, find.text('Continue'));

    expect(find.text('We’ll remind you at 9:30 pm.'), findsOneWidget);
    expect(find.text('Night 1 is waiting'), findsOneWidget);
    expect(reminders.permissionRequests, 0);
    await _tap(tester, find.text('Allow'));

    expect(reminders.permissionRequests, 1);
    var s = await _settings(tester, db);
    expect(s.reminderTime, '21:30');
    expect(s.onboardingDone, isFalse);
    // 21:30 tonight has just passed (the test clock reads 21:30): from tomorrow
    final first = reminders.scheduled.first;
    expect(first.at, DateTime(2026, 10, 4, 21, 30));
    expect(first.title, 'Night 1 is waiting');
    expect(first.body, 'Tonight: The Nightingale and the Rose, A Dream Within a Dream, El Dorado.');
    expect(analytics.events.where((e) => e.$1 == AnalyticsEvent.reminderEnabled).single.$3, {'time': '21:30'});

    expect(find.text('Night one is ready.'), findsOneWidget);
    await _tap(tester, find.text('Begin night one'));

    s = await _settings(tester, db);
    expect(s.onboardingDone, isTrue);
    final done = analytics.events.where((e) => e.$1 == AnalyticsEvent.onboardingCompleted).single;
    expect(done.$2, 1);
    expect(done.$3, {'reminder_time': '21:30'});
    expect(find.text('Tonight’s reading'), findsOneWidget);
    expect(find.text('NIGHT 1 OF 1000'), findsOneWidget);

    await tearDownApp(tester, db);
  });

  testWidgets('Skip goes to the reading time, and Not now leaves reminders off', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    final reminders = FakeReminderScheduler();
    await pumpApp(tester, db, onboardingDone: false, reminders: reminders);

    await _tap(tester, find.text('Begin'));
    await _tap(tester, find.text('Skip'));
    expect(find.text('When do you read?'), findsOneWidget);
    await _tap(tester, find.text('Continue'));
    await _tap(tester, find.text('Not now'));
    expect(reminders.permissionRequests, 0);
    await _tap(tester, find.text('Begin night one'));

    final s = await _settings(tester, db);
    expect((s.onboardingDone, s.reminderTime), (true, null));
    expect(reminders.scheduled, isEmpty);
    expect(find.text('Tonight’s reading'), findsOneWidget);

    await tearDownApp(tester, db);
  });

  testWidgets('the reminders sheet turns reminders on and off and changes the time', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    await tester.runAsync(() async {
      await repoFor(db).debugJumpTo(3, testToday);
      await db.update(db.settings).write(const SettingsCompanion(reminderTime: Value('21:30')));
    });
    final reminders = FakeReminderScheduler()..granted = true;
    final analytics = _RecordingAnalytics();
    await pumpApp(
      tester,
      db,
      location: Routes.journey,
      reminders: reminders,
      overrides: [analyticsProvider.overrideWithValue(analytics)],
    );
    // the streak of 2 is at risk tonight; the 21:30 reminder has just passed
    expect(reminders.scheduled.map((r) => r.id), containsAll([ReminderPlanner.streakBaseId, 101]));

    await _tap(tester, _labelled('Reminders'));
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('One a day, at 9:30 pm.'), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    // streak reminder off
    await _tap(tester, _labelled('Streak reminder at 10 pm'));
    expect((await _settings(tester, db)).streakReminder, isFalse);
    expect(reminders.scheduled.where((r) => r.id >= ReminderPlanner.streakBaseId), isEmpty);

    // a new time: the hour wheel up one notch, to 10 pm
    await tester.drag(find.text('9').last, const Offset(0, -40));
    await settle(tester);
    expect((await _settings(tester, db)).reminderTime, '22:30');
    expect(find.text('One a day, at 10:30 pm.'), findsOneWidget);
    expect(reminders.scheduled.first.at, DateTime(2026, 10, 3, 22, 30));

    // daily off, then on again at the same time
    await _tap(tester, _labelled('Daily reminder'));
    expect((await _settings(tester, db)).reminderTime, isNull);
    expect(reminders.scheduled, isEmpty);
    expect(find.byType(CupertinoDatePicker), findsNothing);
    await _tap(tester, _labelled('Daily reminder'));
    expect((await _settings(tester, db)).reminderTime, '22:30');
    expect(reminders.scheduled, isNotEmpty);
    expect(analytics.events.where((e) => e.$1 == AnalyticsEvent.reminderEnabled).single.$2, 3);

    await tearDownApp(tester, db);
  });

  testWidgets('when iOS says no, the sheet explains how to turn notifications on', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(loadAppFonts);
    final db = (await tester.runAsync(seededDb))!;
    await tester.runAsync(() => repoFor(db).ensureToday(testToday));
    final reminders = FakeReminderScheduler(allow: false);
    await pumpApp(tester, db, location: Routes.journey, reminders: reminders);

    await _tap(tester, _labelled('Reminders'));
    await _tap(tester, _labelled('Daily reminder'));
    expect(reminders.permissionRequests, 1);
    expect((await _settings(tester, db)).reminderTime, isNull);
    expect(find.textContaining('Notifications are off for 1000 Nights'), findsOneWidget);
    await _tap(tester, find.text('Open Settings'));
    expect(reminders.settingsOpened, 1);

    await tearDownApp(tester, db);
  });
}
