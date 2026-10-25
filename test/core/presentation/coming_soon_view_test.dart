import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/presentation/coming_soon_view.dart';

void main() {
  group('ComingSoonView', () {
    patrolWidgetTest('renders placeholder without PWA button by default', (
      $,
    ) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: Scaffold(
            body: ComingSoonView(
              title: 'Community Guidelines',
              emoji: '📜',
              description: 'Guidelines description',
              trackedIssueNumber: 29,
            ),
          ),
        ),
      );

      expect($('Community Guidelines'), findsOneWidget);
      expect($('📜'), findsOneWidget);
      expect($('Guidelines description'), findsOneWidget);
      expect($('Tracked on GitHub Roadmap • Issue #29'), findsOneWidget);
      expect($(const ValueKey('pwa_guide_button')), findsNothing);
    });

    patrolWidgetTest(
      'renders PWA button and opens modal when showPwaInstallGuide is true',
      ($) async {
        $.tester.view.physicalSize = const Size(1080, 2400);
        $.tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidgetAndSettle(
          const MaterialApp(
            home: Scaffold(
              body: ComingSoonView(
                title: 'Download the Android App',
                emoji: '🤖',
                description: 'Android native app placeholder',
                trackedIssueNumber: 30,
                showPwaInstallGuide: true,
              ),
            ),
          ),
        );

        expect($(const ValueKey('pwa_guide_button')), findsOneWidget);
        await $(const ValueKey('pwa_guide_button')).tap();

        // Verify modal content
        expect($('Add Belong to Your Home Screen'), findsOneWidget);
        expect($('Android (Google Chrome)'), findsOneWidget);
        expect($('iPhone & iPad (Apple Safari)'), findsOneWidget);

        expect($(const ValueKey('pwa_guide_dismiss_button')), findsOneWidget);
        await $(const ValueKey('pwa_guide_dismiss_button')).tap();

        expect($('Add Belong to Your Home Screen'), findsNothing);
      },
    );
  });
}
