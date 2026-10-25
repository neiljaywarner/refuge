import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/core/firebase/firebase_installations_service.dart';
import 'package:refuge4serverpod/src/core/firebase/in_app_messaging/in_app_messaging_service.dart';
import 'package:refuge4serverpod/src/core/firebase/in_app_messaging/in_app_messaging_stub.dart';
import 'package:refuge4serverpod/src/core/observability/diagnostic_log_service.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  patrolWidgetTest(
    '7-Tap Easter Egg: Rapidly tapping AppBar header 7 times triggers Observability dialog, displays FID, FIAM trigger, and Session Replay Send Logs',
    ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final fakeAnalytics = CommunityAnalyticsService(flavor: AppFlavor.dev);
      final fakeErrorReporter = ErrorReporterService(
        flavor: AppFlavor.dev,
        analyticsService: fakeAnalytics,
      );
      final fakeStorage = InMemoryStorageRepository();
      final fakeInstallations = FirebaseInstallationsService();
      final fakeFiam = StubInAppMessagingService();
      final fakeDiagnosticLogs = DiagnosticLogService(
        storageRepository: fakeStorage,
        installationsService: fakeInstallations,
        flavor: AppFlavor.dev,
      );

      await $.pumpWidgetAndSettle(
        RefugeApp(
          repository: LocalPostRepository(),
          overrides: [
            communityAnalyticsServiceProvider.overrideWithValue(fakeAnalytics),
            errorReporterServiceProvider.overrideWithValue(fakeErrorReporter),
            storageRepositoryProvider.overrideWithValue(fakeStorage),
            firebaseInstallationsServiceProvider.overrideWithValue(fakeInstallations),
            firebaseInstallationsIdProvider.overrideWith(
              (ref) => Future.value('fid_test_device_easter_egg'),
            ),
            inAppMessagingServiceProvider.overrideWithValue(fakeFiam),
            diagnosticLogServiceProvider.overrideWithValue(fakeDiagnosticLogs),
          ],
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

      // 4. Verify Firebase Installation ID display & copy button
      expect($(const Key('easter_egg_installations_id_text')), findsOneWidget);
      expect($('fid_test_device_easter_egg'), findsOneWidget);
      expect($(const Key('easter_egg_copy_fid_button')), findsOneWidget);
      await $(const Key('easter_egg_copy_fid_button')).tap();
      await $.pumpAndSettle();

      // 5. Verify FIAM trigger button
      expect($(const Key('easter_egg_trigger_fiam_button')), findsOneWidget);
      await $(const Key('easter_egg_trigger_fiam_button')).tap();
      await $.pumpAndSettle();

      // 6. Verify "Send Logs to Cloud Storage" button and upload flow
      await $.tester.ensureVisible(find.byKey(const Key('easter_egg_send_logs_button')));
      expect($(const Key('easter_egg_send_logs_button')), findsOneWidget);
      await $(const Key('easter_egg_send_logs_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('easter_egg_uploaded_log_url')), findsOneWidget);
      expect($(const Key('easter_egg_copy_log_link_button')), findsOneWidget);
      await $(const Key('easter_egg_copy_log_link_button')).tap();
      await $.pumpAndSettle();

      // 7. Verify "View Session Replay & Breadcrumbs" opens modal sheet
      await $.tester.ensureVisible(find.byKey(const Key('easter_egg_view_replay_button')));
      expect($(const Key('easter_egg_view_replay_button')), findsOneWidget);
      await $(const Key('easter_egg_view_replay_button')).tap();
      await $.pumpAndSettle();
      expect($('Diagnostic Session Replay'), findsOneWidget);
      expect($(const Key('easter_egg_copy_full_replay_button')), findsOneWidget);

      // Close bottom sheet (tap barrier or dismiss)
      Navigator.of($.tester.element($(const Key('easter_egg_copy_full_replay_button')))).pop();
      await $.pumpAndSettle();

      // 8. Tap "Trigger Handled NFE" and verify error is captured in buffer
      await $.tester.ensureVisible(find.byKey(const Key('easter_egg_trigger_nfe_button')));
      await $(const Key('easter_egg_trigger_nfe_button')).tap();
      await $.pumpAndSettle();
      expect(fakeErrorReporter.recordedErrorsForTesting.length, 1);
      expect(
        fakeErrorReporter.recordedErrorsForTesting.first['reason'],
        'Manual 7-Tap Easter Egg Verification',
      );

      // 9. Tap "Emit Test Analytics Event" and verify analytics event dispatched
      await $.tester.ensureVisible(find.byKey(const Key('easter_egg_trigger_analytics_button')));
      await $(const Key('easter_egg_trigger_analytics_button')).tap();
      await $.pumpAndSettle();
      expect(
        fakeAnalytics.dispatchedEventsForTesting.any((e) => e['name'] == 'easter_egg_test_event'),
        isTrue,
      );

      // 10. Dismiss dialog cleanly
      await $.tester.ensureVisible(find.byKey(const Key('easter_egg_close_button')));
      await $(const Key('easter_egg_close_button')).tap();
      await $.pumpAndSettle();
      expect($(const Key('observability_easter_egg_dialog')), findsNothing);
    },
  );
}
