import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/line_icons.dart';

/// Tab shell: Tonight, Library, Journey. Also settles the day whenever the
/// app comes back to the foreground, so a night left open past midnight
/// rolls over.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(repositoryProvider).ensureToday(todayOf(ref.read), subscriber: ref.read(isSubscriberProvider));
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: _TabBar(
        index: widget.shell.currentIndex,
        onTap: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [(LineIcon.moon, 'Tonight'), (LineIcon.book, 'Library'), (LineIcon.constellation, 'Journey')];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.inkRaised.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: Tokens.hairline, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: _tabs[i].$2,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LineIconView(
                            _tabs[i].$1,
                            size: 26,
                            color: i == index ? Tokens.amber : Tokens.parchmentDim,
                            filled: i == index,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _tabs[i].$2,
                            style: TextStyle(fontSize: 14, color: i == index ? Tokens.amber : Tokens.parchmentDim),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
