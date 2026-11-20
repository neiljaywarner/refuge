import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #977 guard: a button whose handler awaits network or storage work should
/// use `AsyncActionButton`, which spins and ignores repeat taps.
///
/// Inline `onPressed: () async` / `onTap: () async` handlers are only allowed
/// where the await is a menu, dialog, picker, or URL launch (no spinner wanted)
/// or the button lives inside an `AsyncActionButton`. Adding a new one fails
/// here; either use `AsyncActionButton` or add it below with a reason.
const _allowed = <String, int>{
  // Opens an external URL.
  'lib/src/features/auth/presentation/auth_help_and_about_sheet.dart': 1,
  // Opens a popup menu.
  'lib/src/features/auth/presentation/belong_auth_sheet.dart': 1,
  // Close (confirm-discard dialog) and Draw (opens the drawing dialog).
  'lib/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart': 2,
  // Debug-only preview notification.
  'lib/src/features/notifications/presentation/calm_notification_preferences_sheet.dart': 1,
  // Hidden debug dialog.
  'lib/src/features/observability/presentation/observability_easter_egg_dialog.dart': 2,
  // Opens a bottom-sheet picker.
  'lib/src/features/profile/presentation/first_visit_welcome_card.dart': 1,
  // Opens a popup menu.
  'lib/src/features/profile/presentation/member_profile_sheet.dart': 1,
  // Save for Later: already inside AsyncActionButton.
  'lib/src/features/reflections/presentation/reflection_card.dart': 1,
};

void main() {
  test('new async button handlers use AsyncActionButton (#977)', () {
    final pattern = RegExp(r'on(Pressed|Tap): \(\) async');
    final offenders = <String>[];
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final count = pattern.allMatches(entity.readAsStringSync()).length;
      if (count > (_allowed[path] ?? 0)) offenders.add('$path ($count)');
    }
    expect(offenders, isEmpty, reason: 'Use AsyncActionButton for async buttons (#977).');
  });
}
