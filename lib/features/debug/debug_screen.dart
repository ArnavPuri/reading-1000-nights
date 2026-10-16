import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/database.dart';

/// Debug menu (debug builds only; long-press "NIGHT N OF 1000"): move the
/// clock, jump nights and reset state.
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  Future<void> _shiftDays(WidgetRef ref, int delta) async {
    final db = ref.read(databaseProvider);
    final s = await db.getSettings();
    await db.update(db.settings).write(SettingsCompanion(debugDayOffset: Value(s.debugDayOffset + delta)));
    await ref.read(settingsProvider.future);
    await ref.read(repositoryProvider).ensureToday(todayOf(ref.read), subscriber: ref.read(isSubscriberProvider));
  }

  Future<void> _finishTonight(WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final tonight = (await repo.tonight()).tonight;
    if (tonight == null) return;
    for (final p in tonight.pieces.where((p) => !p.done)) {
      await repo.finishPiece(
        p.work.id,
        tonight.dayNumber,
        now: ref.read(clockProvider)(),
        today: todayOf(ref.read),
        addSeconds: p.work.estMinutes * 60,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final today = todayOf(ref.read);

    Widget action(String label, Future<void> Function() run) => ListTile(
      title: Text(label, style: const TextStyle(fontSize: 18)),
      onTap: () async {
        await run();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Done: $label')));
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Tokens.ink,
        title: const Text('Debug'),
        leading: BackButton(onPressed: () => context.go(Routes.tonight)),
      ),
      body: ListView(
        children: [
          ListTile(title: Text('Today is $today'), subtitle: Text('Day offset ${settings?.debugDayOffset ?? 0}')),
          action('Advance one day', () => _shiftDays(ref, 1)),
          action('Back one day', () => _shiftDays(ref, -1)),
          action('Finish all of tonight', () => _finishTonight(ref)),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('JUMP TO NIGHT', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final n in [1, 2, 3, 4, 5, 6, 7])
                  ActionChip(label: Text('$n'), onPressed: () => ref.read(repositoryProvider).debugJumpTo(n, today)),
              ],
            ),
          ),
          const Divider(),
          // The router's redirect opens onboarding as soon as the flag drops.
          action('Replay onboarding', () async {
            final db = ref.read(databaseProvider);
            await db.update(db.settings).write(const SettingsCompanion(onboardingDone: Value(false)));
          }),
          action('Reset all state', () async {
            await ref.read(databaseProvider).resetUserState();
            await ref.read(settingsProvider.future);
            await ref.read(repositoryProvider).ensureToday(todayOf(ref.read));
          }),
        ],
      ),
    );
  }
}
