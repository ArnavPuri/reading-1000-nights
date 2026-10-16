import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/database.dart';
import '../../data/reading_repository.dart';
import '../share/share_card.dart';
import '../share/share_sheet.dart';
import 'md_text.dart';
import 'reader_selection.dart';
import 'reader_settings_sheet.dart';

/// Title and author in small caps, ornamental drop cap, serif body, amber
/// ribbon progress, long-press to select and highlight, "Finish" at the end.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.dayNumber, required this.workId});

  final int dayNumber;
  final String workId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);
  final _clock = Stopwatch();
  final _viewportKey = GlobalKey();
  late final _selection = ReaderSelection(scroll: _scroll, viewportKey: _viewportKey);
  late final ReadingRepository _repo;

  Work? _work;
  List<MdBlock> _blocks = const [];
  bool _restored = false;
  double _savedPos = 0;
  bool _finishing = false;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = ref.read(repositoryProvider);
    _scroll.addListener(_onScroll);
    _load();
  }

  Future<void> _load() async {
    final work = await _repo.work(widget.workId);
    await _repo.startPiece(widget.workId, widget.dayNumber, ref.read(clockProvider)());
    final progress = await _repo.progressFor(widget.workId, widget.dayNumber);
    if (!mounted) return;
    setState(() {
      _work = work;
      _blocks = parseMarkdown(work.textMd, verse: work.type == 'poem');
      _selection.blocks = _blocks;
      _savedPos = progress?.completedAt != null ? 0 : (progress?.scrollPos ?? 0);
    });
    _clock.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  void _restore() {
    if (_restored || !_scroll.hasClients) return;
    _restored = true;
    final max = _scroll.position.maxScrollExtent;
    if (_savedPos > 0 && max > 0) _scroll.jumpTo(_savedPos * max);
    _onScroll();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _progress.value = max <= 0 ? 1 : (_scroll.offset / max).clamp(0, 1);
    _selection.dismissIfOffscreen();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), _save);
  }

  /// Seconds read since the last save, ignoring long idle stretches.
  int _takeSeconds() {
    final s = _clock.elapsed.inSeconds.clamp(0, 15 * 60);
    _clock.reset();
    return s;
  }

  void _save() {
    if (_work == null || _finishing) return;
    _repo.saveReading(widget.workId, widget.dayNumber, scrollPos: _progress.value, addSeconds: _takeSeconds());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _save();
      _clock.stop();
    } else if (state == AppLifecycleState.resumed) {
      _clock.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    _save();
    _selection.dispose();
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    HapticFeedback.lightImpact();
    final result = await _repo.finishPiece(
      widget.workId,
      widget.dayNumber,
      now: ref.read(clockProvider)(),
      today: todayOf(ref.read),
      addSeconds: _takeSeconds(),
      subscriber: ref.read(isSubscriberProvider),
    );
    if (!mounted) return;
    if (result.nightComplete) {
      context.go(Routes.nightComplete(result.dayNumber));
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.tonight);
    }
  }

  /// Saves [start, end) as a highlight, merged with any it overlaps. A
  /// resized highlight ([replacing]) is swapped for the new range.
  Future<void> _saveHighlight(int start, int end, {int? replacing}) async {
    final m = mergeHighlight(start, end, [
      for (final h in _selection.highlights) (id: h.id, start: h.startOffset, end: h.endOffset),
    ], replacing: replacing);
    final text = _blocks.textOf(m.start, m.end);
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    await _repo.replaceHighlights(widget.workId, m.remove, m.start, m.end, text);
    if (!mounted) return;
    final work = _work;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Highlight saved to your Library'),
        duration: const Duration(seconds: 4),
        action: work == null
            ? null
            : SnackBarAction(label: 'Share', textColor: ReaderTheme.paper.accent, onPressed: () => _share(text)),
      ),
    );
  }

  void _share(String text) {
    final work = _work;
    if (work == null) return;
    showSharePreview(context, ref, HighlightShare.of(text, work, dayNumber: widget.dayNumber));
  }

  /// The menu over the selection: Remove for a stored highlight, else
  /// Highlight. Each action ends the selection.
  List<SelectionAction> _menu() {
    final (start, end) = _selection.range!;
    final text = _blocks.textOf(start, end);
    final id = _selection.highlightId;
    void done() => _selection.clear();
    return [
      if (_selection.isStoredHighlight)
        (
          label: 'Remove',
          onTap: () {
            done();
            HapticFeedback.selectionClick();
            _repo.removeHighlight(id!);
          },
        )
      else
        (
          label: 'Highlight',
          onTap: () {
            done();
            _saveHighlight(start, end, replacing: id);
          },
        ),
      (
        label: 'Copy',
        onTap: () {
          done();
          Clipboard.setData(ClipboardData(text: text));
        },
      ),
      (
        label: 'Share',
        onTap: () {
          done();
          _share(text);
        },
      ),
    ];
  }

  /// VoiceOver cannot drag handles, so each paragraph has actions to
  /// highlight all of it, or remove the highlights in it.
  Map<CustomSemanticsAction, VoidCallback> _paragraphActions(int i, List<Highlight> highlights) {
    final b = _blocks[i];
    final inside = [
      for (final h in highlights)
        if (b.plainRangeOf(h.startOffset, h.endOffset) != null) h,
    ];
    return {
      _highlightParagraph: () => _saveHighlight(b.mdStart, b.mdEnd),
      if (inside.isNotEmpty)
        _removeHighlight: () async {
          for (final h in inside) {
            await _repo.removeHighlight(h.id);
          }
        },
    };
  }

  static const _highlightParagraph = CustomSemanticsAction(label: 'Highlight paragraph');
  static const _removeHighlight = CustomSemanticsAction(label: 'Remove highlight');

  static const _textInsets = EdgeInsets.fromLTRB(26, 28, 34, 48);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final theme = ReaderTheme.byName(settings?.theme ?? 'night');
    final fontSize = readerFontSizes[(settings?.fontStep ?? 2).clamp(0, readerFontSizes.length - 1)];
    final lineHeight = readerLineHeights[(settings?.lineStep ?? 1).clamp(0, readerLineHeights.length - 1)];
    final highlights = ref.watch(workHighlightsProvider(widget.workId)).value ?? const [];
    _selection.highlights = highlights;
    final work = _work;

    final body = TextStyle(fontFamily: Tokens.serif, fontSize: fontSize, height: lineHeight, color: theme.text);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme == ReaderTheme.night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                color: theme.text,
                accent: theme.accent,
                isFavorite: ref.watch(isFavoriteProvider(widget.workId)).value ?? false,
                onBack: () => context.canPop() ? context.pop() : context.go(Routes.tonight),
                onFavorite: () {
                  HapticFeedback.lightImpact();
                  _repo.toggleFavorite(widget.workId, now: ref.read(clockProvider)());
                },
                onSettings: () {
                  _selection.clear();
                  showReaderSettings(context, ref);
                },
              ),
              Expanded(
                child: work == null
                    ? const SizedBox()
                    : Stack(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            // VoiceOver gets the paragraph actions instead
                            excludeFromSemantics: true,
                            onTapUp: (d) => _selection.tap(d.globalPosition),
                            onLongPressStart: (d) => _selection.longPressStart(d.globalPosition),
                            onLongPressMoveUpdate: (d) => _selection.longPressMove(d.globalPosition),
                            onLongPressEnd: (_) => _selection.longPressEnd(),
                            child: Scrollbar(
                              controller: _scroll,
                              thickness: 0,
                              child: SingleChildScrollView(
                                key: _viewportKey,
                                controller: _scroll,
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: _textInsets,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _TitleBlock(work: work, theme: theme),
                                          const SizedBox(height: 30),
                                          for (var i = 0; i < _blocks.length; i++)
                                            Semantics(
                                              container: true,
                                              label: _blocks[i].plain,
                                              excludeSemantics: true,
                                              customSemanticsActions: _paragraphActions(i, highlights),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: fontSize * (_blocks[i].verse ? 1.2 : 1.1),
                                                ),
                                                child: i == 0 && !_blocks[i].verse
                                                    ? _DropCapBlock(
                                                        index: i,
                                                        block: _blocks[i],
                                                        style: body,
                                                        theme: theme,
                                                        highlights: highlights,
                                                        selection: _selection,
                                                      )
                                                    : _BlockText(
                                                        index: i,
                                                        block: _blocks[i],
                                                        from: 0,
                                                        to: _blocks[i].plain.length,
                                                        style: body,
                                                        theme: theme,
                                                        highlights: highlights,
                                                        selection: _selection,
                                                      ),
                                              ),
                                            ),
                                          const SizedBox(height: 24),
                                          _FinishButton(theme: theme, onTap: _finish),
                                        ],
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: ReaderSelectionOverlay(
                                        selection: _selection,
                                        color: theme.accent,
                                        textInsets: _textInsets,
                                        actions: _menu,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 8,
                            bottom: 24,
                            child: _Ribbon(progress: _progress, theme: theme),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.color,
    required this.accent,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
    required this.onSettings,
  });

  final Color color;
  final Color accent;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
                child: LineIconView(LineIcon.back, size: 22, color: color.withValues(alpha: 0.85)),
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Favourite',
            selected: isFavorite,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFavorite,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 4, 13),
                child: LineIconView(
                  LineIcon.bookmark,
                  size: 22,
                  filled: isFavorite,
                  color: isFavorite ? accent : color.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Reading settings',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSettings,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 20, 10),
                child: Text('Aa', style: TextStyle(fontSize: 22, color: color.withValues(alpha: 0.9))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.work, required this.theme});

  final Work work;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    final from = work.partLabel == 'from';
    return Column(
      children: [
        Text(
          '${from ? 'FROM ' : ''}${work.title.toUpperCase()}',
          textAlign: TextAlign.center,
          style: TextStyles.label(color: theme.text, size: 13.5),
        ),
        const SizedBox(height: 16),
        Text(
          work.author.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyles.label(color: theme.text.withValues(alpha: 0.7), size: 11),
        ),
        if (work.partLabel != null && !from) ...[
          const SizedBox(height: 10),
          Text(
            work.partLabel!,
            style: TextStyle(fontStyle: FontStyle.italic, color: theme.text.withValues(alpha: 0.7)),
          ),
        ],
        const SizedBox(height: 22),
        Container(width: 34, height: 1, color: theme.accent),
      ],
    );
  }
}

/// A block (or a slice of one) as one paragraph, with any highlight that
/// overlaps it and the selection painted behind it.
class _BlockText extends StatefulWidget {
  const _BlockText({
    required this.index,
    required this.block,
    required this.from,
    required this.to,
    required this.style,
    required this.theme,
    required this.highlights,
    required this.selection,
  });

  final int index;
  final MdBlock block;
  final int from;
  final int to;
  final TextStyle style;
  final ReaderTheme theme;
  final List<Highlight> highlights;
  final ReaderSelection selection;

  @override
  State<_BlockText> createState() => _BlockTextState();
}

class _BlockTextState extends State<_BlockText> {
  final _key = GlobalKey();
  late ReaderSlice _slice;

  @override
  void initState() {
    super.initState();
    _slice = widget.selection.attach(widget.index, widget.from, widget.to, _key);
  }

  @override
  void didUpdateWidget(_BlockText old) {
    super.didUpdateWidget(old);
    if (old.selection != widget.selection) {
      old.selection.detach(_slice);
      _slice = widget.selection.attach(widget.index, widget.from, widget.to, _key);
    }
    _slice
      ..block = widget.index
      ..from = widget.from
      ..to = widget.to;
  }

  @override
  void dispose() {
    widget.selection.detach(_slice);
    super.dispose();
  }

  List<InlineSpan> _spans() {
    final block = widget.block;
    final marked = List<bool>.filled(block.plain.length, false);
    for (final h in widget.highlights) {
      final r = block.plainRangeOf(h.startOffset, h.endOffset);
      if (r == null) continue;
      for (var i = r.$1; i < r.$2; i++) {
        marked[i] = true;
      }
    }
    final spans = <InlineSpan>[];
    var i = widget.from;
    while (i < widget.to) {
      final it = block.italicAt(i), hl = marked[i];
      var j = i + 1;
      while (j < widget.to && block.italicAt(j) == it && marked[j] == hl) {
        j++;
      }
      spans.add(
        TextSpan(
          text: block.plain.substring(i, j),
          style: TextStyle(
            fontStyle: it ? FontStyle.italic : null,
            backgroundColor: hl ? widget.theme.highlight : null,
          ),
        ),
      );
      i = j;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SelectionPainter(widget.selection, _slice, widget.theme.accent.withValues(alpha: 0.34)),
      child: RichText(
        key: _key,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(style: widget.style, children: _spans()),
      ),
    );
  }
}

/// First paragraph with an ornamental drop cap three lines tall.
class _DropCapBlock extends StatelessWidget {
  const _DropCapBlock({
    required this.index,
    required this.block,
    required this.style,
    required this.theme,
    required this.highlights,
    required this.selection,
  });

  static const _lines = 3;

  final int index;
  final MdBlock block;
  final TextStyle style;
  final ReaderTheme theme;
  final List<Highlight> highlights;
  final ReaderSelection selection;

  @override
  Widget build(BuildContext context) {
    final s = block.plain;
    // Skip an opening quote: the cap is the first letter.
    var capAt = 0;
    while (capAt < s.length && '“‘"\''.contains(s[capAt])) {
      capAt++;
    }
    if (capAt >= s.length) {
      return _BlockText(
        index: index,
        block: block,
        from: 0,
        to: s.length,
        style: style,
        theme: theme,
        highlights: highlights,
        selection: selection,
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    final lineH = scaler.scale(style.fontSize!) * style.height!;
    final capStyle = TextStyle(
      fontFamily: Tokens.display,
      fontSize: lineH * _lines * 0.98,
      height: 1,
      color: theme.accent,
      fontWeight: FontWeight.w300,
    );
    final capPainter = TextPainter(
      text: TextSpan(text: s[capAt], style: capStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final capW = capPainter.width;
    const gap = 10.0;
    final restFrom = capAt + 1;

    return LayoutBuilder(
      builder: (context, c) {
        final besideW = c.maxWidth - capW - gap;
        final p = TextPainter(
          text: TextSpan(text: s.substring(restFrom), style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout(maxWidth: besideW);
        final metrics = p.computeLineMetrics();
        var split = s.length;
        if (metrics.length > _lines) {
          final y = metrics[_lines - 1].baseline;
          final endPos = p.getPositionForOffset(Offset(besideW, y));
          split = restFrom + p.getLineBoundary(endPos).end;
        }
        var after = split;
        while (after < s.length && s[after] == ' ') {
          after++;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.only(top: lineH * 0.12),
                    child: Text(s[capAt], style: capStyle, textScaler: TextScaler.noScaling),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _BlockText(
                    index: index,
                    block: block,
                    from: restFrom,
                    to: split,
                    style: style,
                    theme: theme,
                    highlights: highlights,
                    selection: selection,
                  ),
                ),
              ],
            ),
            if (after < s.length)
              _BlockText(
                index: index,
                block: block,
                from: after,
                to: s.length,
                style: style,
                theme: theme,
                highlights: highlights,
                selection: selection,
              ),
          ],
        );
      },
    );
  }
}

/// Thin ribbon on the right edge: scroll progress.
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.progress, required this.theme});

  final ValueListenable<double> progress;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 8,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, v, _) => CustomPaint(painter: _RibbonPainter(v, theme.accent)),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final y = size.height * value;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.value != value || old.color != color;
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({required this.theme, required this.onTap});

  final ReaderTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('⁂', style: TextStyle(fontSize: 22, color: theme.accent)),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.accent,
              side: BorderSide(color: theme.accent.withValues(alpha: 0.7)),
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 18, letterSpacing: 0.5),
            ),
            child: const Text('Finish'),
          ),
        ),
      ],
    );
  }
}

/// Writes one reader setting.
Future<void> updateReaderSettings(WidgetRef ref, SettingsCompanion change) {
  final db = ref.read(databaseProvider);
  return db.update(db.settings).write(change);
}
