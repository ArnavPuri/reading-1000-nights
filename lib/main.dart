import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/bootstrap.dart';
import 'core/providers.dart';
import 'core/reminders.dart';
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

class ThousandNightsApp extends ConsumerWidget {
  const ThousandNightsApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps reminders scheduled for as long as the app runs.
    ref.watch(reminderSyncProvider);
    // Onboarding starts or ends: let the router's redirect move the user.
    ref.listen(settingsProvider.select((s) => s.value?.onboardingDone), (_, _) => router.refresh());
    return MaterialApp.router(
      title: '1000 Nights',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
