import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/database.dart';
import '../../data/reading_repository.dart';
import '../journey/constellation.dart';
import 'share_card.dart';

/// What goes to the share sheet: the card as a PNG plus a line of text.
class SharePayload {
  const SharePayload({required this.png, required this.fileName, required this.text, this.origin});

  final Uint8List png;
  final String fileName;
  final String text;

  /// Where the share sheet anchors on iPad.
  final Rect? origin;
}

/// Hands a payload to the platform. Returns true when the user shared it.
typedef ShareFunction = Future<bool> Function(SharePayload payload);

/// The iOS share sheet via share_plus. Overridden in tests, which have no
/// platform.
final shareFunctionProvider = Provider<ShareFunction>((ref) => _shareWithPlatform);

Future<bool> _shareWithPlatform(SharePayload p) async {
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(p.png, mimeType: 'image/png', name: p.fileName)],
      text: p.text,
      sharePositionOrigin: p.origin,
    ),
  );
  return result.status == ShareResultStatus.success;
}

/// The card, scaled to fit, with "Share" and "Close".
Future<void> showSharePreview(BuildContext context, WidgetRef ref, ShareCardData data) {
  ref
      .read(analyticsProvider)
      .track(AnalyticsEvent.shareCardOpened, dayNumber: data.dayNumber, props: {'kind': data.kind});
  final image = data.imagePath;
  if (image != null) precacheImage(AssetImage(image), context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // over the tab bar: the card needs the height
    useRootNavigator: true,
    builder: (_) => _SharePreviewSheet(data: data),
  );
}

/// Library → Highlights: finds the night the work was read on, then shares.
Future<void> shareHighlight(BuildContext context, WidgetRef ref, HighlightWithWork h) async {
  final day = await nightOfWork(ref.read(databaseProvider), h.work.id);
  if (!context.mounted) return;
  await showSharePreview(context, ref, HighlightShare.of(h.highlight.body, h.work, dayNumber: day ?? 1));
}

/// The first night that carries [workId], or null if no night does.
Future<int?> nightOfWork(AppDatabase db, String workId) async {
  final q = db.select(db.days)
    ..where((d) => d.storyId.equals(workId) | d.poemId.equals(workId) | d.essayId.equals(workId))
    ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)])
    ..limit(1);
  return (await q.getSingleOrNull())?.dayNumber;
}

/// The highest milestone reached with [nightsCompleted] nights, if any.
int? latestMilestone(int nightsCompleted) =>
    ConstellationLayout.milestones.where((m) => nightsCompleted >= m).lastOrNull;

/// Journey: the milestone card, with the streaks as they stand.
Future<void> shareMilestone(BuildContext context, WidgetRef ref, JourneyView journey, int milestone) async {
  final streak = await ref.read(databaseProvider).getStreak();
  if (!context.mounted) return;
  await showSharePreview(
    context,
    ref,
    MilestoneShare(
      milestone: milestone,
      nightsCompleted: journey.nightsCompleted,
      streak: streak.current,
      longestStreak: streak.longest,
    ),
  );
}

class _SharePreviewSheet extends ConsumerStatefulWidget {
  const _SharePreviewSheet({required this.data});
  final ShareCardData data;

  @override
  ConsumerState<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends ConsumerState<_SharePreviewSheet> {
  final _boundary = GlobalKey();
  final _shareButton = GlobalKey();
  var _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = widget.data;
      // the engraving must be decoded and painted before the capture
      final image = data.imagePath;
      if (image != null) {
        await precacheImage(AssetImage(image), context);
        await WidgetsBinding.instance.endOfFrame;
      }
      final png = await _capture();
      final payload = SharePayload(png: png, fileName: data.fileName, text: data.shareText, origin: _originRect());
      final shared = await ref.read(shareFunctionProvider)(payload);
      if (shared) {
        ref
            .read(analyticsProvider)
            .track(AnalyticsEvent.shareCardShared, dayNumber: data.dayNumber, props: {'kind': data.kind});
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _capture() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Rect? _originRect() {
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final maxCard = MediaQuery.sizeOf(context).height * 0.58;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SHARE', style: TextStyles.label(color: Tokens.parchmentDim, size: 11)),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxCard),
              child: AspectRatio(
                aspectRatio: ShareCard.size.aspectRatio,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Tokens.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FittedBox(
                      child: RepaintBoundary(key: _boundary, child: ShareCard(widget.data)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: _shareButton,
                onPressed: _busy ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: Tokens.amber,
                  foregroundColor: Tokens.ink,
                  disabledBackgroundColor: Tokens.amber.withValues(alpha: 0.5),
                  disabledForegroundColor: Tokens.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontFamily: Tokens.serif, fontSize: 18, letterSpacing: 0.5),
                ),
                icon: const LineIconView(LineIcon.share, size: 19, color: Tokens.ink),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Tokens.parchmentDim, minimumSize: const Size(120, 44)),
              child: const Text('Close', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}
