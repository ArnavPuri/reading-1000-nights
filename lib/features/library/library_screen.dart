import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/reading_repository.dart';
import '../journey/journey_screen.dart';

/// Unlocked nights, newest first, plus Highlights and Saved (favourites)
/// views. Re-reading any past night is always allowed.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

enum _Tab { nights, highlights, saved }

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  var _tab = _Tab.nights;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Tokens.gutter, 36, Tokens.gutter, 0),
            child: Text('Library', style: TextStyles.screenTitle),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Row(
              children: [
                for (final (tab, label) in const [
                  (_Tab.nights, 'NIGHTS'),
                  (_Tab.highlights, 'HIGHLIGHTS'),
                  (_Tab.saved, 'SAVED'),
                ]) ...[
                  if (tab != _Tab.nights) const SizedBox(width: 24),
                  _Segment(label: label, selected: _tab == tab, onTap: () => setState(() => _tab = tab)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_tab) {
              _Tab.nights => const _NightsList(),
              _Tab.highlights => const _HighlightsList(),
              _Tab.saved => const _SavedList(),
            },
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? Tokens.amber : Colors.transparent, width: 1.5)),
        ),
        child: Text(label, style: TextStyles.label(color: selected ? Tokens.amber : Tokens.parchmentDim, size: 12)),
      ),
    ),
  );
}

class _NightsList extends ConsumerWidget {
  const _NightsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nights = ref.watch(libraryProvider).value ?? const <NightView>[];
    if (nights.isEmpty) {
      return Center(child: Text('Your nights will gather here.', style: TextStyles.byline));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, Tokens.gutter, 24),
      itemCount: nights.length,
      separatorBuilder: (_, _) => Divider(color: Tokens.hairline, height: 1),
      itemBuilder: (context, i) {
        final n = nights[i];
        final done = n.pieces.where((p) => p.done).length;
        return InkWell(
          onTap: () => showNightSheet(context, n.dayNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '${n.dayNumber}',
                    style: const TextStyle(fontFamily: Tokens.display, fontSize: 34, color: Tokens.amber, height: 1),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in n.pieces)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: p.work.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: p.done ? Tokens.parchment : Tokens.parchment.withValues(alpha: 0.75),
                                  ),
                                ),
                                TextSpan(text: '  ${p.work.author}', style: TextStyles.meta.copyWith(fontSize: 14)),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$done/3', textAlign: TextAlign.right, style: TextStyles.meta),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HighlightsList extends ConsumerWidget {
  const _HighlightsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(highlightsProvider).value ?? const [];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Tokens.gutter),
        child: Text('Long-press a sentence while reading to keep it here.', style: TextStyles.byline),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, Tokens.gutter, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(color: Tokens.hairline, height: 1),
      itemBuilder: (context, i) {
        final h = items[i];
        return Dismissible(
          key: ValueKey(h.highlight.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => ref.read(repositoryProvider).removeHighlight(h.highlight.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Tokens.highlight,
                  child: Text(
                    h.highlight.body,
                    style: const TextStyle(fontSize: 19, height: 1.5, color: Tokens.parchment),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${h.work.title.toUpperCase()}  ·  ${h.work.author.toUpperCase()}',
                  style: TextStyles.label(color: Tokens.parchmentDim, size: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavedList extends ConsumerWidget {
  const _SavedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(favoritesProvider).value ?? const [];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Tokens.gutter),
        child: Text('Tap the ribbon while reading to keep a piece here.', style: TextStyles.byline),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, Tokens.gutter, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(color: Tokens.hairline, height: 1),
      itemBuilder: (context, i) {
        final f = items[i];
        return Dismissible(
          key: ValueKey(f.work.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => ref.read(repositoryProvider).toggleFavorite(f.work.id, now: ref.read(clockProvider)()),
          child: InkWell(
            onTap: () => context.push(Routes.read(f.dayNumber, f.work.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${f.work.type.toUpperCase()}  ·  NIGHT ${f.dayNumber}',
                    style: TextStyles.label(color: Tokens.parchmentDim, size: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(f.work.title, style: const TextStyle(fontSize: 19, height: 1.3, color: Tokens.parchment)),
                  const SizedBox(height: 4),
                  Text(f.work.author, style: TextStyles.meta),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
