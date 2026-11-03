import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/space_navigation_bar.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

void main() {
  group('Prayer Sanctuary Directory & Re-entry (#846 Bruce Feedback)', () {
    testWidgets(
      'Prayer Sanctuary is prominently pinned in Spaces Directory and selects prayer slug',
      (tester) async {
        BelongSpaceItem? selected;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 2400);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BelongSpacesDirectoryView(
                  selectedSpaceSlug: 'general_chat',
                  onSelectSpaceItem: (item) => selected = item,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Prayer Sanctuary appears under PINNED or at the top of the directory
        final prayerTile = find.byKey(const Key('space_tile_prayer'));
        expect(prayerTile, findsOneWidget);
        expect(find.text('Prayer Sanctuary'), findsOneWidget);
        expect(find.text('🙏'), findsOneWidget);

        // Tap Prayer Sanctuary tile
        await tester.tap(prayerTile);
        await tester.pumpAndSettle();

        expect(selected?.slug, equals('prayer'));
        expect(selected?.title, equals('Prayer Sanctuary'));
      },
    );

    testWidgets(
      'SpaceNavigationBar shows 1-tap Return to Prayer Sanctuary button when in other space',
      (tester) async {
        String? switchedSpace;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: SensoryThemeData.getTheme(SensoryMode.sage),
              home: Scaffold(
                body: SpaceNavigationBar(
                  selectedSpace: 'general_chat',
                  onSelectSpace: (space) => switchedSpace = space,
                  onBackToSpaces: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find quick-return to Prayer Sanctuary button
        final returnButton = find.byKey(const Key('return_to_prayer_sanctuary_button'));
        expect(returnButton, findsOneWidget);

        await tester.tap(returnButton);
        await tester.pumpAndSettle();

        expect(switchedSpace, equals('prayer'));
      },
    );

    testWidgets(
      'SpaceNavigationBar hides Return to Prayer Sanctuary button when already in prayer',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: SensoryThemeData.getTheme(SensoryMode.sage),
              home: Scaffold(
                body: SpaceNavigationBar(
                  selectedSpace: 'prayer',
                  onSelectSpace: (_) {},
                  onBackToSpaces: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('return_to_prayer_sanctuary_button')), findsNothing);
      },
    );
  });
}
