import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('web semantics helper is a no-op when not running on web', () {
    expect(enableWebSemanticsForAutomation, returnsNormally);
  });

  testWidgets('theme, about, and composer labels are exposed for automation', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(RefugeApp(repository: LocalPostRepository()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sensory Themes'), findsOneWidget);
      expect(find.bySemanticsIdentifier('sensory_theme_toggle_button'), findsOneWidget);
      expect(find.byTooltip('About Belong'), findsOneWidget);
      expect(find.bySemanticsIdentifier('about_belong_info_button'), findsOneWidget);
      expect(find.bySemanticsIdentifier('reflection_composer'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.bySemanticsLabel('Active sensory theme Sage'), findsOneWidget);

      await tester.tap(find.byTooltip('Sensory Themes'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsWidgets);
      expect(find.bySemanticsIdentifier('sensory_theme_charcoal'), findsOneWidget);
      expect(find.bySemanticsIdentifier('sensory_theme_clean'), findsOneWidget);
      expect(find.bySemanticsIdentifier('sensory_theme_contrast'), findsOneWidget);

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Active sensory theme Dark'), findsOneWidget);
      expect(find.bySemanticsIdentifier('active_sensory_theme_charcoal'), findsOneWidget);

      await tester.tap(find.byTooltip('About Belong'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Psalm 139:14'), findsOneWidget);
      expect(find.bySemanticsLabel('About Belong'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Psalm 139:14'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
}
