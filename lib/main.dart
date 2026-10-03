import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/bootstrap.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = openAppDatabase();
  await importBundledPacks(db, rootBundle);

  final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  await container.read(settingsProvider.future);
  await container.read(repositoryProvider).ensureToday(todayOf(container.read));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ThousandNightsApp(router: buildRouter()),
    ),
  );
}

class ThousandNightsApp extends StatelessWidget {
  const ThousandNightsApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '1000 Nights',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
