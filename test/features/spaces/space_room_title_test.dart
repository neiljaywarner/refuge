import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/space_navigation_bar.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

void main() {
  group('BelongSpaceInfo & getBelongSpaceInfo (#618)', () {
    test('resolves canonical Circle spaces to human-friendly titles', () {
      final memes = getBelongSpaceInfo('memes');
      expect(memes.title, equals('Memes'));
      expect(memes.emoji, equals('😂'));

      final autisticChat = getBelongSpaceInfo('actually_autistic_chat');
      expect(autisticChat.title, equals('Actually Autistic Chat'));
      expect(autisticChat.emoji, equals('♾️'));

      final generalChat = getBelongSpaceInfo('general_chat');
      expect(generalChat.title, equals('General Chat'));
      expect(generalChat.emoji, equals('📌'));

      final startHere = getBelongSpaceInfo('start_here');
      expect(startHere.title, equals('Start Here & Introduce Yourself'));
      expect(startHere.emoji, equals('👋'));
    });

    test('resolves legacy kFellowshipSpaces keys to clean titles', () {
      final prayer = getBelongSpaceInfo('prayer');
      expect(prayer.title, equals('Prayer Sanctuary'));
      expect(prayer.emoji, equals('🙏'));

      final study = getBelongSpaceInfo('study');
      expect(study.title, equals('Weekly Study'));
      expect(study.emoji, equals('📖'));

      final general = getBelongSpaceInfo('general');
      expect(general.title, equals('Main Hall'));
      expect(general.emoji, equals('🌿'));
    });

    test('falls back gracefully on unknown slugs', () {
      final custom = getBelongSpaceInfo('sensory_garden_room');
      expect(custom.title, equals('Sensory Garden Room'));
      expect(custom.emoji, equals('💬'));
    });
  });

  group('SpaceNavigationBar Room Title & Breadcrumb Widget Tests (#618)', () {
    testWidgets('renders room header and title for active space', (tester) async {
      String? selected;
      bool backTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SensoryThemeData.getTheme(SensoryMode.sage),
            home: Scaffold(
              body: SpaceNavigationBar(
                selectedSpace: 'general_chat',
                onSelectSpace: (space) => selected = space,
                onBackToSpaces: () => backTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify room title header exists with human display name
      expect(find.byKey(const Key('space_room_header')), findsOneWidget);
      expect(find.byKey(const Key('space_room_title')), findsOneWidget);
      expect(find.text('General Chat'), findsOneWidget);
      expect(find.text('📌'), findsOneWidget);

      // Verify breadcrumb back navigation affordances
      expect(find.byKey(const Key('space_breadcrumb_back_button')), findsOneWidget);
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.byKey(const Key('space_breadcrumb_all_spaces_button')), findsOneWidget);
      expect(find.text('All Spaces'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('space_breadcrumb_back_button')));
      await tester.pumpAndSettle();
      expect(backTapped, isTrue);

      // Open space switcher popup menu and select another space
      await tester.tap(find.byKey(const Key('space_switcher_popup_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('space_chip_start_here')));
      await tester.pumpAndSettle();
      expect(selected, equals('start_here'));
    });

    testWidgets('renders cleanly in High Contrast mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: SensoryThemeData.getTheme(SensoryMode.contrast),
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

      expect(find.text('Prayer Sanctuary'), findsOneWidget);
      expect(find.text('🙏'), findsOneWidget);
      expect(find.byKey(const Key('space_breadcrumb_back_button')), findsOneWidget);
    });
  });
}
