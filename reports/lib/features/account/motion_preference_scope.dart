import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MotionPreferenceScope extends InheritedWidget {
  const MotionPreferenceScope({
    super.key,
    required this.preference,
    required super.child,
  });
  final ValueListenable<bool> preference;

  static ValueListenable<bool>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MotionPreferenceScope>()
      ?.preference;

  @override
  bool updateShouldNotify(MotionPreferenceScope oldWidget) =>
      preference != oldWidget.preference;
}
