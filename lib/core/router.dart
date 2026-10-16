import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/debug_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/library/library_screen.dart';
import '../features/night_complete/night_complete_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/tonight/tonight_screen.dart';
import 'providers.dart';

abstract final class Routes {
  static const tonight = '/tonight';
  static const library = '/library';
  static const journey = '/journey';
  static const debug = '/debug';
  static const onboarding = '/onboarding';
  static String read(int day, String workId) => '/read/$day/$workId';
  static String nightComplete(int day) => '/night-complete/$day';
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  ),
);

/// First run goes to onboarding until `settings.onboarding_done`; once it is
/// set, onboarding hands over to Tonight. The app calls `refresh()` when the
/// flag changes.
String? _onboardingRedirect(BuildContext context, GoRouterState state) {
  final done = ProviderScope.containerOf(context, listen: false).read(settingsProvider).value?.onboardingDone;
  final onOnboarding = state.matchedLocation == Routes.onboarding;
  if (done == false && !onOnboarding) return Routes.onboarding;
  if (done == true && onOnboarding) return Routes.tonight;
  return null;
}

GoRouter buildRouter({String initialLocation = Routes.tonight}) => GoRouter(
  initialLocation: initialLocation,
  redirect: _onboardingRedirect,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.tonight, pageBuilder: (c, s) => _fade(s, const TonightScreen()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.library, pageBuilder: (c, s) => _fade(s, const LibraryScreen()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.journey, pageBuilder: (c, s) => _fade(s, const JourneyScreen()))],
        ),
      ],
    ),
    // The reader sits outside the shell: the tab bar hides while reading.
    GoRoute(
      path: '/read/:day/:workId',
      pageBuilder: (c, s) =>
          _fade(s, ReaderScreen(dayNumber: int.parse(s.pathParameters['day']!), workId: s.pathParameters['workId']!)),
    ),
    GoRoute(
      path: '/night-complete/:day',
      pageBuilder: (c, s) => _fade(s, NightCompleteScreen(dayNumber: int.parse(s.pathParameters['day']!))),
    ),
    GoRoute(path: Routes.debug, pageBuilder: (c, s) => _fade(s, const DebugScreen())),
    GoRoute(path: Routes.onboarding, pageBuilder: (c, s) => _fade(s, const OnboardingScreen())),
  ],
);
