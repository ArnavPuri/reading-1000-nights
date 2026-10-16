import 'package:flutter/cupertino.dart';

import '../../core/theme.dart';
import '../../domain/reminder_plan.dart';

/// An on/off switch in the app's line style: a hairline track that fills
/// with amber. It slides; it does not bounce.
class QuietToggle extends StatelessWidget {
  const QuietToggle({super.key, required this.value, required this.onChanged, required this.semantics});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 260);
    return Semantics(
      toggled: value,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 56,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? Tokens.amber : Tokens.ink,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: value ? Tokens.amber : Tokens.parchmentFaint, width: 1),
              ),
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: duration,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: value ? Tokens.ink : Tokens.parchmentDim),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reminder time as an inline wheel: Newsreader numerals between two
/// hairlines, on the sheet's own colour. Reports a new time when the wheel
/// comes to rest.
class ReminderTimePicker extends StatefulWidget {
  const ReminderTimePicker({super.key, required this.value, required this.onChanged, this.height = 168});

  final ReminderTime value;
  final ValueChanged<ReminderTime> onChanged;
  final double height;

  @override
  State<ReminderTimePicker> createState() => _ReminderTimePickerState();
}

class _ReminderTimePickerState extends State<ReminderTimePicker> {
  static const _itemExtent = 40.0;

  /// Bumped when the time is set from outside (a preset chip), so the wheel
  /// is rebuilt at the new time. Times the wheel itself reported keep it.
  var _revision = 0;
  late ReminderTime _reported = widget.value;

  @override
  void didUpdateWidget(ReminderTimePicker old) {
    super.didUpdateWidget(old);
    if (widget.value != _reported) {
      _reported = widget.value;
      _revision++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.value;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // the selected row: two hairlines and a faint amber wash
          Center(
            child: Container(
              height: _itemExtent,
              decoration: BoxDecoration(
                color: Tokens.amber.withValues(alpha: 0.06),
                border: Border.symmetric(horizontal: BorderSide(color: Tokens.amber.withValues(alpha: 0.35))),
              ),
            ),
          ),
          CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontFamily: Tokens.serif,
                  fontSize: 23,
                  color: Tokens.parchment,
                  fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()],
                ),
              ),
            ),
            // a slow cross-fade when a preset moves the wheel
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: CupertinoDatePicker(
                key: ValueKey(_revision),
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2026, 1, 1, t.hour, t.minute - t.minute % 5),
                minuteInterval: 5,
                itemExtent: _itemExtent,
                backgroundColor: const Color(0x00000000),
                selectionOverlayBuilder: (context, {required columnCount, required selectedIndex}) => null,
                changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                onDateTimeChanged: (d) {
                  _reported = ReminderTime(d.hour, d.minute);
                  widget.onChanged(_reported);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
