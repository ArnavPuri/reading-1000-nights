import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/core/providers.dart';
import 'package:thousand_nights/core/router.dart';
import 'package:thousand_nights/data/database.dart';
import 'package:thousand_nights/data/reading_repository.dart';
import 'package:thousand_nights/domain/local_date.dart';
import 'package:thousand_nights/main.dart';

const testNow = _Now();

class _Now {
  const _Now();
  DateTime call() => DateTime(2026, 10, 3, 21, 30);
}

final testToday = LocalDate.fromDateTime(testNow());

/// iPhone 15 Pro: 393 x 852 pt at 3x, with the notch and home indicator.
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
  tester.view.viewPadding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
}

var _fontsLoaded = false;

/// Loads the bundled Newsreader fonts so text renders as it does on device.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  Future<ByteData> f(String name) async => ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());
  final serif = FontLoader('Newsreader')
    ..addFont(f('Newsreader-Regular.ttf'))
    ..addFont(f('Newsreader-Medium.ttf'))
    ..addFont(f('Newsreader-Italic.ttf'));
  final display = FontLoader('NewsreaderDisplay')
    ..addFont(f('NewsreaderDisplay-Light.ttf'))
    ..addFont(f('NewsreaderDisplay-Regular.ttf'));
  await serif.load();
  await display.load();
}

/// Pumps the real app over [db]. Call `repo.ensureToday` (or a debug jump)
/// first to set up state. [overrides] are added to the app's.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  String location = Routes.tonight,
  Key? boundaryKey,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(testNow.call), ...overrides],
      child: RepaintBoundary(
        key: boundaryKey,
        child: ThousandNightsApp(router: buildRouter(initialLocation: location)),
      ),
    ),
  );
  await settle(tester);
}

/// Lets streams, image decoding and fades finish. Never pumpAndSettle: the
/// candle flickers forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Unmounts the app so drift's stream timers can finish before the test ends.
Future<void> tearDownApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(db.close);
}

ReadingRepository repoFor(AppDatabase db) => ReadingRepository(db);
