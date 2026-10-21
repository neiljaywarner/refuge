import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/presentation/coming_soon_view.dart';

void main() {
  group('ComingSoonView', () {
    testWidgets('renders placeholder without PWA button by default', (tester) async {
      await tester.pumpWidget(
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

      expect(find.text('Community Guidelines'), findsOneWidget);
      expect(find.text('📜'), findsOneWidget);
      expect(find.text('Guidelines description'), findsOneWidget);
      expect(find.text('Tracked on GitHub Roadmap • Issue #29'), findsOneWidget);
      expect(find.byKey(const ValueKey('pwa_guide_button')), findsNothing);
    });

    testWidgets('renders PWA button and opens modal when showPwaInstallGuide is true', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
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

      final guideButton = find.byKey(const ValueKey('pwa_guide_button'));
      expect(guideButton, findsOneWidget);

      await tester.tap(guideButton);
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Add Belong to Your Home Screen'), findsOneWidget);
      expect(find.text('Android (Google Chrome)'), findsOneWidget);
      expect(find.text('iPhone & iPad (Apple Safari)'), findsOneWidget);

      final dismissButton = find.byKey(const ValueKey('pwa_guide_dismiss_button'));
      expect(dismissButton, findsOneWidget);

      // Dismiss modal
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      expect(find.text('Add Belong to Your Home Screen'), findsNothing);
    });
  });
}
