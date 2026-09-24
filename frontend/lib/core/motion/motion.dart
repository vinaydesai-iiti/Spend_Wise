import 'package:flutter/material.dart';

/// Central helper for the "reduce motion" accessibility requirement.
/// Widgets should read durations through here instead of hardcoding
/// `Duration(milliseconds: ...)` so a user with reduce-motion enabled at
/// the OS level automatically gets little to no animation everywhere.
class Motion {
  const Motion._();

  static bool reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

  /// Returns [normal], or [Duration.zero] when the user prefers reduced
  /// motion.
  static Duration duration(BuildContext context, Duration normal) =>
      reduceMotion(context) ? Duration.zero : normal;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
}
