import 'package:flutter/material.dart';

import '../theme.dart';

class HairlineProgress extends StatelessWidget {
  const HairlineProgress({super.key, required this.value, this.height = 3});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Keep night 1 visible on a 1000-night bar.
        final fill = (c.maxWidth * value.clamp(0, 1)).clamp(height * 3, c.maxWidth);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Tokens.parchment.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fill.toDouble(),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Tokens.amber, borderRadius: BorderRadius.circular(height)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
