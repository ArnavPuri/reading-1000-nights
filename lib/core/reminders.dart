import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';
import '../data/reading_repository.dart';
import '../domain/local_date.dart';
import '../domain/night_rules.dart';
import '../domain/reminder_plan.dart';
import 'analytics.dart';
import 'providers.dart';

/// Places a planned wall-clock time in [location]. A time that does not
/// exist that day (skipped by a daylight-saving change) moves forward by the
/// size of the gap, as the timezone package normalises it.
tz.TZDateTime zonedInstant(DateTime wallClock, tz.Location location) =>
    tz.TZDateTime(location, wallClock.year, wallClock.month, wallClock.day, wallClock.hour, wallClock.minute);

/// Local notifications, behind an interface so tests can stub the plugin.
abstract class ReminderScheduler {
  /// Re-reads the device's time zone (it changes when the user travels) and
  /// returns its name.
  Future<String> refreshTimeZone();

  Future<bool> hasPermission();

  /// Shows the iOS prompt the first time. After that iOS answers with the
  /// user's earlier choice without asking again.
  Future<bool> requestPermission();

  /// Opens this app's notification settings in the iOS Settings app.
  Future<void> openSystemSettings();

  /// Replaces every pending reminder with [plan].
  Future<void> replaceAll(List<PlannedReminder> plan);
}

/// `flutter_local_notifications`, scheduling one-shot notifications in the
/// device's time zone.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  var _zone = 'UTC';

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    await _readZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Permission is asked in context (onboarding, the reminders sheet),
        // never at launch. A reminder that arrives while the app is open
        // goes quietly to Notification Center.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: false,
          defaultPresentBanner: false,
          defaultPresentSound: false,
          defaultPresentBadge: false,
          defaultPresentList: true,
        ),
      ),
    );
  }();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> _readZone() async {
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
      _zone = name;
    } catch (e) {
      // An unknown zone name keeps the last one (UTC at first).
      debugPrint('[reminders] time zone: $e');
    }
  }

  @override
  Future<String> refreshTimeZone() async {
    await _init();
    await _readZone();
    return _zone;
  }

  @override
  Future<bool> hasPermission() async {
    await _init();
    final p = await _ios?.checkPermissions();
    return p?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> openSystemSettings() async {
    await _init();
    await _ios?.openAppNotificationSettings();
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    await _init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final r in plan) {
      final at = zonedInstant(r.at, tz.local);
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: at,
        notificationDetails: const NotificationDetails(iOS: DarwinNotificationDetails(threadIdentifier: 'reminders')),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

/// Keeps the scheduled reminders in step with the app. Lives at the app's
/// root: it replans whenever reading state or the reminder settings change,
/// and on every resume, re-reading the time zone first.
class ReminderSync {
  ReminderSync({required this.db, required this.repo, required this.scheduler, required this.clock});

  final AppDatabase db;
  final ReadingRepository repo;
  final ReminderScheduler scheduler;
  final DateTime Function() clock;

  var _zone = '';
  String? _scheduled;
  var _running = false;
  var _dirty = false;
  var _disposed = false;

  /// Completes when the replan in flight (if any) is done.
  Future<void> _idle = Future.value();

  /// Re-reads the time zone, then replans.
  Future<void> resume() async {
    try {
      _zone = await scheduler.refreshTimeZone();
    } catch (e) {
      debugPrint('[reminders] $e');
    }
    await sync();
  }

  /// Replans and, if the plan changed, reschedules. Calls made while one is
  /// running are folded into one more pass.
  Future<void> sync() {
    if (_disposed) return Future.value();
    if (_running) {
      _dirty = true;
      return _idle;
    }
    _running = true;
    return _idle = () async {
      try {
        do {
          _dirty = false;
          await _syncOnce();
        } while (_dirty && !_disposed);
      } catch (e) {
        if (!_disposed) debugPrint('[reminders] $e');
      } finally {
        _running = false;
      }
    }();
  }

  Future<void> _syncOnce() async {
    final settings = await db.getSettings();
    final plan = await scheduler.hasPermission() ? await _plan(settings) : const <PlannedReminder>[];
    if (_disposed) return;
    final key = '$_zone|${plan.join(';')}';
    if (key == _scheduled) return;
    await scheduler.replaceAll(plan);
    _scheduled = key;
  }

  Future<List<PlannedReminder>> _plan(SettingsRow settings) async {
    final view = await repo.tonight();
    final streak = await db.getStreak();
    // The debug day offset moves the app's "today"; shift its dates back to
    // the real calendar the notifications fire on.
    LocalDate? real(String? d) => d == null ? null : LocalDate.parse(d).addDays(-settings.debugDayOffset);
    final night = view.tonight;
    return ReminderPlanner.plan(
      now: clock(),
      dailyAt: ReminderTime.tryParse(settings.reminderTime),
      streakReminder: settings.streakReminder,
      streak: streak.current,
      lastReadDate: real(streak.lastReadDate),
      tonight: night == null
          ? null
          : TonightInfo(
              night: LatestNight(
                dayNumber: night.dayNumber,
                unlockedOn: real(night.night.unlockedOn)!,
                completedOn: real(night.night.completedOn),
                piecesDone: night.night.piecesDone,
              ),
              pieces: [for (final p in night.pieces) PieceTitle(p.work.title, done: p.done)],
              tomorrow: view.tomorrow == null ? null : [for (final w in view.tomorrow!) w.title],
            ),
    );
  }

  void dispose() => _disposed = true;
}

final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(
    db: ref.watch(databaseProvider),
    repo: ref.watch(repositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    clock: ref.watch(clockProvider),
  );
  final changes = sync.repo.changes.listen((_) => sync.sync());
  ref.listen(settingsProvider, (prev, next) {
    final a = prev?.value, b = next.value;
    if (b == null) return;
    if (a == null ||
        a.reminderTime != b.reminderTime ||
        a.streakReminder != b.streakReminder ||
        a.debugDayOffset != b.debugDayOffset) {
      sync.sync();
    }
  });
  final lifecycle = AppLifecycleListener(onResume: sync.resume);
  ref.onDispose(() {
    sync.dispose();
    changes.cancel();
    lifecycle.dispose();
  });
  sync.resume();
  return sync;
});

/// Turns reminders on from onboarding or the reminders sheet: asks for
/// permission (iOS shows its prompt only the first time), stores the
/// choice and schedules. [daily] sets the daily reminder time; [streak]
/// the 10 pm streak reminder. Returns false, changing nothing, when
/// notifications are not allowed.
Future<bool> turnOnReminders(T Function<T>(ProviderListenable<T>) read, {ReminderTime? daily, bool? streak}) async {
  final granted = await read(reminderSchedulerProvider).requestPermission();
  if (!granted) return false;
  final db = read(databaseProvider);
  final before = await db.getSettings();
  await db
      .update(db.settings)
      .write(
        SettingsCompanion(
          reminderTime: daily == null ? const Value.absent() : Value('$daily'),
          streakReminder: streak == null ? const Value.absent() : Value(streak),
        ),
      );
  if (daily != null && before.reminderTime == null) {
    final night = (await read(repositoryProvider).tonight()).tonight?.dayNumber;
    read(analyticsProvider).track(AnalyticsEvent.reminderEnabled, dayNumber: night, props: {'time': '$daily'});
  }
  await read(reminderSyncProvider).sync();
  return true;
}
