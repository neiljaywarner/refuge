import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/space_navigation_bar.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

/// Canonical postable spaces, in directory order, as the switcher must show them.
///
/// Weekly Study stays its own space (`study`). Main Hall (`general`) is a legacy
/// key and is not a switcher row. Labels are the emoji plus the title, with no
/// channel hash and no "room" wording.
const List<(String slug, String label)> _expectedSwitcherSpaces = [
  ('prayer', '🙏 Prayer Sanctuary'),
  ('general_chat', '📌 General Chat'),
  ('start_here', '👋 Start Here & Introduce Yourself'),
  ('announcements', '📢 Announcements'),
  ('study', '📖 Weekly Study'),
  ('saved_for_later', '🔖 Saved for Later'),
  ('memes', '😂 Memes'),
  ('resources_videos', '🎥 Online Resources / Videos'),
  ('actually_autistic_chat', '♾️ Actually Autistic Chat'),
  ('friends_chat', '🧑‍🤝‍🧑 Friends Chat'),
  ('family_chat', '🏡 Family Chat'),
];

void main() {
  group('Space switcher canonical postable spaces (#1003)', () {
    testWidgets('lists postable spaces with Space wording and no hash', (tester) async {
      String? selected;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SensoryThemeData.getTheme(SensoryMode.sage),
            home: Scaffold(
              body: SpaceNavigationBar(
                selectedSpace: 'general_chat',
                onSelectSpace: (space) => selected = space,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_containerOf(tester).read(activeSpaceKeyProvider), 'general_chat');
      expect(find.byKey(const Key('space_room_title')), findsOneWidget);
      expect(find.text('General Chat'), findsOneWidget);
      expect(find.byTooltip('Switch fellowship space'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('room', caseSensitive: false)), findsNothing);

      await tester.tap(find.byKey(const Key('space_switcher_popup_button')));
      await tester.pumpAndSettle();

      final menuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      );
      expect(
        menuItems.map((item) => item.value).toList(),
        _expectedSwitcherSpaces.map((space) => space.$1).toList(),
      );

      for (final space in _expectedSwitcherSpaces) {
        expect(find.byKey(Key('space_chip_${space.$1}')), findsOneWidget);
        expect(find.text(space.$2), findsOneWidget);
        expect(space.$2.contains('#'), isFalse);
        expect(space.$2.toLowerCase().contains('room'), isFalse);
      }

      expect(find.textContaining('#'), findsNothing);
      expect(find.textContaining('room'), findsNothing);
      expect(find.byKey(const Key('space_chip_general')), findsNothing);
      expect(find.byKey(const Key('space_chip_members_directory')), findsNothing);
      expect(find.text('Main Hall'), findsNothing);
      expect(find.text('🌿 #main-hall'), findsNothing);

      await tester.tap(find.byKey(const Key('space_chip_study')));
      await tester.pumpAndSettle();
      expect(selected, 'study');
      expect(_containerOf(tester).read(activeSpaceKeyProvider), 'study');
    });
  });
}

ProviderContainer _containerOf(WidgetTester tester) {
  final context = tester.element(find.byType(SpaceNavigationBar));
  return ProviderScope.containerOf(context);
}
