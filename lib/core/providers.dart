import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../data/database.dart';
import '../data/reading_repository.dart';
import '../domain/local_date.dart';
import 'analytics.dart';

/// Overridden in main() and in tests with an opened database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider'));

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());

final repositoryProvider = Provider<ReadingRepository>(
  (ref) => ReadingRepository(ref.watch(databaseProvider), analytics: ref.watch(analyticsProvider)),
);

/// Wall clock. Overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Subscription entitlement. RevenueCat lands in phase 3; until then nobody
/// is a subscriber.
final isSubscriberProvider = Provider<bool>((ref) => false);

final settingsProvider = StreamProvider<SettingsRow>(
  (ref) => ref.watch(databaseProvider).select(ref.watch(databaseProvider).settings).watchSingle(),
);

/// Today's local date, shifted by the debug day offset. Pass any `read`:
/// `todayOf(ref.read)` from a Ref, WidgetRef or ProviderContainer.
LocalDate todayOf(T Function<T>(ProviderListenable<T>) read) {
  final offset = read(settingsProvider).value?.debugDayOffset ?? 0;
  return LocalDate.fromDateTime(read(clockProvider)()).addDays(offset);
}

/// Re-runs [load] whenever reading state changes.
Stream<T> _watch<T>(Ref ref, Future<T> Function(ReadingRepository repo) load) {
  final repo = ref.watch(repositoryProvider);
  final controller = StreamController<T>();
  Future<void> emit() async {
    try {
      controller.add(await load(repo));
    } catch (e, s) {
      controller.addError(e, s);
    }
  }

  emit();
  final sub = repo.changes.listen((_) => emit());
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
}

final tonightProvider = StreamProvider<TonightView>((ref) => _watch(ref, (r) => r.tonight()));

final journeyProvider = StreamProvider<JourneyView>((ref) => _watch(ref, (r) => r.journey()));

final libraryProvider = StreamProvider<List<NightView>>((ref) => _watch(ref, (r) => r.library()));

final highlightsProvider = StreamProvider<List<HighlightWithWork>>((ref) => _watch(ref, (r) => r.allHighlights()));

final nightProvider = StreamProvider.family<NightView?, int>((ref, day) => _watch(ref, (r) => r.night(day)));

final workHighlightsProvider = StreamProvider.family<List<Highlight>, String>(
  (ref, id) => _watch(ref, (r) => r.highlightsFor(id)),
);

final favoritesProvider = StreamProvider<List<FavoriteWithWork>>((ref) => _watch(ref, (r) => r.favorites()));

final isFavoriteProvider = StreamProvider.family<bool, String>((ref, id) => _watch(ref, (r) => r.isFavorite(id)));

final weekProvider = StreamProvider<List<bool>>((ref) => _watch(ref, (r) => r.week(todayOf(ref.read))));
