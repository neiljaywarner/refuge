import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  patrolWidgetTest(
    '7-Tap Easter Egg: Rapidly tapping AppBar header 7 times triggers Observability dialog, NFE and Analytics events',
    ($) async {
      final fakeAnalytics = CommunityAnalyticsService(flavor: AppFlavor.dev);
      final fakeErrorReporter = ErrorReporterService(
        flavor: AppFlavor.dev,
        analyticsService: fakeAnalytics,
      );

      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            communityAnalyticsServiceProvider.overrideWithValue(fakeAnalytics),
            errorReporterServiceProvider.overrideWithValue(fakeErrorReporter),
          ],
          child: SanctuaryApp(
            repository: LocalPostRepository(),
          ),
        ),
      );

      // 1. Initial State: Easter egg dialog is not present
      expect($(const Key('observability_easter_egg_dialog')), findsNothing);

      // 2. Tap the AppBar title target 7 times rapidly
      final tapTarget = $(const Key('belong_app_bar_title_tap_target'));
      expect(tapTarget, findsOneWidget);

      for (var i = 0; i < 7; i++) {
        await tapTarget.tap();
      }
      await $.pumpAndSettle();

      // 3. Dialog is now visible
      expect($(const Key('observability_easter_egg_dialog')), findsOneWidget);
      expect($('Observability Verification'), findsOneWidget);
      expect($(const Key('easter_egg_trigger_nfe_button')), findsOneWidget);
      expect($(const Key('easter_egg_trigger_analytics_button')), findsOneWidget);
      expect($(const Key('easter_egg_trigger_fatal_crash_button')), findsOneWidget);
      expect($(const Key('easter_egg_copy_adb_button')), findsOneWidget);

      // 4. Tap "Record Handled NFE" and verify error is captured in buffer
      await $(const Key('easter_egg_trigger_nfe_button')).tap();
      await $.pumpAndSettle();

      expect(fakeErrorReporter.recordedErrorsForTesting.length, equals(1));
      expect(
        fakeErrorReporter.recordedErrorsForTesting.first['reason'],
        equals('Manual 7-Tap Easter Egg Verification'),
      );

      // 5. Tap "Emit Test Analytics Event" and verify SnackBar
      await $(const Key('easter_egg_trigger_analytics_button')).tap();
      await $.pumpAndSettle();

      // 6. Close the dialog
      await $(const Key('easter_egg_close_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('observability_easter_egg_dialog')), findsNothing);
    },
  );
}
