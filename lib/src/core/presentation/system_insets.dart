import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Status-bar and system-navigation-bar insets.
///
/// [SafeArea] reads only [MediaQueryData.padding]. A modal bottom sheet extends
/// through the navigation bar (`useSafeArea` pads the top, left, and right
/// only), and on that route [MediaQueryData.padding] can be 0 while
/// [MediaQueryData.viewPadding] still reports the bar.
class SystemInsets {
  const SystemInsets._();

  /// Navigation-bar inset when this widget is not also avoiding the keyboard.
  ///
  /// While the keyboard is open, [MediaQueryData.padding.bottom] is what
  /// [SafeArea] already uses (the keyboard covers the bar).
  static double navigationBar(MediaQueryData mediaQuery) {
    if (mediaQuery.viewInsets.bottom > 0) {
      return mediaQuery.padding.bottom;
    }
    return math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
  }

  /// Bottom obstruction for a surface that must clear the navigation bar and
  /// the keyboard. The keyboard covers the bar, so the two are not stacked.
  static double bottom(MediaQueryData mediaQuery) {
    if (mediaQuery.viewInsets.bottom > 0) {
      return mediaQuery.viewInsets.bottom;
    }
    return math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
  }

  /// Copies a missing navigation-bar or status-bar inset into
  /// [MediaQueryData.padding] so existing [SafeArea] widgets can see it.
  ///
  /// This does not paint a second inset. The keyboard is left alone: [Dialog]
  /// and [SafeArea] already add [MediaQueryData.viewInsets].
  static MediaQueryData repairPadding(MediaQueryData mediaQuery) {
    final bottom = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.padding.bottom
        : math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
    return mediaQuery.copyWith(
      padding: EdgeInsets.fromLTRB(
        math.max(mediaQuery.padding.left, mediaQuery.viewPadding.left),
        math.max(mediaQuery.padding.top, mediaQuery.viewPadding.top),
        math.max(mediaQuery.padding.right, mediaQuery.viewPadding.right),
        bottom,
      ),
    );
  }

  /// Outer margin for [AlertDialog]. [Dialog] adds [MediaQueryData.viewInsets]
  /// itself, so this stays the status bar and navigation bar only.
  static EdgeInsets dialogInsetPadding(MediaQueryData mediaQuery) {
    final nav = mediaQuery.viewInsets.bottom > 0
        ? 0.0
        : math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
    return EdgeInsets.fromLTRB(
      math.max(40, math.max(mediaQuery.padding.left, mediaQuery.viewPadding.left)),
      math.max(24, math.max(mediaQuery.padding.top, mediaQuery.viewPadding.top)),
      math.max(40, math.max(mediaQuery.padding.right, mediaQuery.viewPadding.right)),
      math.max(24, nav),
    );
  }
}

/// Pads [child] once for the bottom system bar or keyboard, then clears that
/// inset on the child's [MediaQuery] so a nested [SafeArea] does not add it
/// again.
class SystemBottomInset extends StatelessWidget {
  const SystemBottomInset({super.key, required this.child});

  final Widget child;

  static const Key insetKey = Key('system_bottom_inset');

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final inset = SystemInsets.bottom(mediaQuery);
    final cleared = mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(bottom: 0),
      viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
      viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
    );
    return Padding(
      key: insetKey,
      padding: EdgeInsets.only(bottom: inset),
      child: MediaQuery(data: cleared, child: child),
    );
  }
}
