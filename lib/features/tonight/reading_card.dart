import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/line_icons.dart';
import '../../data/database.dart';

String typeLabel(String type) => switch (type) {
  'story' => 'SHORT STORY',
  'poem' => 'POEM',
  'essay' => 'ESSAY',
  _ => type.toUpperCase(),
};

/// Engraving card: label, title, author, read time; the illustration bleeds
/// off the right side under a dark fade.
class ReadingCard extends StatelessWidget {
  const ReadingCard({super.key, required this.work, required this.done, required this.onTap, this.minHeight = 186});

  final Work work;
  final bool done;
  final VoidCallback onTap;

  /// Cards grow past this with long titles or large Dynamic Type sizes.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final label = [
      typeLabel(work.type),
      if (work.partLabel == 'from') 'EXCERPT' else if (work.partLabel != null) work.partLabel!.toUpperCase(),
    ].join('  ·  ');

    return Semantics(
      button: true,
      label:
          '${typeLabel(work.type).toLowerCase()}, ${work.title} by ${work.author}, '
          '${work.estMinutes} minutes${done ? ', finished' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: done ? 0.55 : 1,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              color: Tokens.inkRaised,
              borderRadius: BorderRadius.circular(Tokens.cardRadius),
              border: Border.all(color: Tokens.hairline, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (work.imagePath != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 260,
                    child: Image.asset(
                      work.imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, _, _) => const SizedBox(),
                    ),
                  ),
                // dark fade from the text side over the illustration
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        stops: [0, 0.42, 0.7, 1],
                        colors: [Tokens.inkRaised, Tokens.inkRaised, Color(0x991B1F2B), Color(0x001B1F2B)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyles.label(color: Tokens.amber, size: 11.5)),
                      const SizedBox(height: 12),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: Text(
                          work.title,
                          style: TextStyles.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(work.author, style: TextStyles.byline),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          LineIconView(LineIcon.clock, size: 17, color: Tokens.parchment.withValues(alpha: 0.75)),
                          const SizedBox(width: 10),
                          Text('${work.estMinutes} min', style: TextStyles.meta),
                        ],
                      ),
                    ],
                  ),
                ),
                if (done)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Tokens.ink.withValues(alpha: 0.7),
                        border: Border.all(color: Tokens.amber, width: 1.2),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const LineIconView(LineIcon.check, size: 14, color: Tokens.amber),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
