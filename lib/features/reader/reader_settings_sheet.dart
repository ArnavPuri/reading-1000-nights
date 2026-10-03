import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import 'reader_screen.dart';

/// "Aa": type size (5 steps), line spacing (3 steps), theme (Night, Sepia,
/// Paper).
Future<void> showReaderSettings(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(context: context, builder: (_) => const _ReaderSettingsSheet());
}

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value;
    if (s == null) return const SizedBox(height: 240);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TYPE SIZE', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StepButton(
                  label: 'A',
                  size: 15,
                  semantics: 'Smaller text',
                  onTap: s.fontStep > 0 ? () => _set(ref, SettingsCompanion(fontStep: Value(s.fontStep - 1))) : null,
                ),
                Expanded(
                  child: _Dots(count: readerFontSizes.length, active: s.fontStep),
                ),
                _StepButton(
                  label: 'A',
                  size: 24,
                  semantics: 'Larger text',
                  onTap: s.fontStep < readerFontSizes.length - 1
                      ? () => _set(ref, SettingsCompanion(fontStep: Value(s.fontStep + 1)))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('LINE SPACING', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < readerLineHeights.length; i++) ...[
                  Expanded(
                    child: _Choice(
                      selected: s.lineStep == i,
                      semantics: ['Compact', 'Normal', 'Airy'][i],
                      onTap: () => _set(ref, SettingsCompanion(lineStep: Value(i))),
                      child: _LinesGlyph(gap: 3.0 + i * 2.5),
                    ),
                  ),
                  if (i < readerLineHeights.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text('THEME', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final t in ReaderTheme.values) ...[
                  Expanded(
                    child: _Choice(
                      selected: s.theme == t.name,
                      semantics: '${t.label} theme',
                      color: t.background,
                      onTap: () => _set(ref, SettingsCompanion(theme: Value(t.name))),
                      child: Text(t.label, style: TextStyle(color: t.text, fontSize: 16)),
                    ),
                  ),
                  if (t != ReaderTheme.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _set(WidgetRef ref, SettingsCompanion c) => updateReaderSettings(ref, c);
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.size, required this.semantics, required this.onTap});

  final String label;
  final double size;
  final String semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: size, color: onTap == null ? Tokens.parchmentFaint : Tokens.parchment),
          ),
        ),
      ),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (var i = 0; i < count; i++)
        Container(
          width: i == active ? 9 : 6,
          height: i == active ? 9 : 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: i == active ? Tokens.amber : Tokens.parchmentFaint),
        ),
    ],
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.semantics,
    this.color,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String semantics;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: semantics,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? Tokens.ink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Tokens.amber : Tokens.hairline, width: selected ? 1.5 : 1),
        ),
        child: child,
      ),
    ),
  );
}

class _LinesGlyph extends StatelessWidget {
  const _LinesGlyph({required this.gap});
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++) ...[
        Container(width: 26, height: 1.5, color: Tokens.parchmentDim),
        if (i < 2) SizedBox(height: gap),
      ],
    ],
  );
}
