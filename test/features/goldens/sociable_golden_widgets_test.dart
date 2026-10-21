import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import '../../support/test_font_loader.dart';

void main() {
  setUpAll(() async {
    await TestFontLoader.loadAppFonts();
  });

  group('Sociable Golden & Visual Regression Widget Tests', () {
    patrolWidgetTest(
      'ToneFilterRow: renders all sensory chips and handles selection sociably',
      ($) async {
        String selected = 'All';

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: RepaintBoundary(
                  child: ToneFilterRow(
                    activeFilter: selected,
                    onSelectFilter: (val) => selected = val,
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Verify all tone tags are present
        expect($('Filter: '), findsOneWidget);
        expect($('All'), findsOneWidget);
        expect($('[Comfort Only]'), findsOneWidget);
        expect($('[Prayer Request]'), findsOneWidget);

        // 2. Tap [Comfort Only] and verify selection callback
        await $('[Comfort Only]').tap();
        await $.pumpAndSettle();
        expect(selected, equals('[Comfort Only]'));

        // 3. Golden verification if file exists
        final goldenFile = File('test/features/goldens/goldens/tone_filter_row.png');
        if (goldenFile.existsSync()) {
          await expectLater(
            find.byType(ToneFilterRow),
            matchesGoldenFile('goldens/tone_filter_row.png'),
          );
        }
      },
    );

    patrolWidgetTest(
      'CommunityAnchorBanner: renders organizer headline, text and dialog tap target',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              organizerRemoteConfigProvider.overrideWithValue(
                OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const Scaffold(
                body: RepaintBoundary(
                  child: CommunityAnchorBanner(
                    primaryColor: Color(0xFF112334),
                    isContrast: false,
                  ),
                ),
              ),
            ),
          ),
        );

        expect($('Welcome to Belong on the Spectrum'), findsOneWidget);
        expect(
          $('You belong here. Take your time, choose a sensory theme that feels comfortable, and introduce yourself in Start Here when you are ready.'),
          findsOneWidget,
        );
        expect($(const Key('organizer_message_banner')), findsOneWidget);

        // Golden verification if file exists
        final goldenFile = File('test/features/goldens/goldens/community_anchor_banner.png');
        if (goldenFile.existsSync()) {
          await expectLater(
            find.byType(CommunityAnchorBanner),
            matchesGoldenFile('goldens/community_anchor_banner.png'),
          );
        }
      },
    );

    patrolWidgetTest(
      'BelongBottomNavBar: renders all 4 tabs (Home, Notifications, Msgs, Search) with selection callback',
      ($) async {
        BelongBottomTab current = BelongBottomTab.home;

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                bottomNavigationBar: RepaintBoundary(
                  child: BelongBottomNavBar(
                    currentTab: current,
                    onSelectTab: (t) => current = t,
                    isContrast: false,
                  ),
                ),
              ),
            ),
          ),
        );

        expect($('Home'), findsOneWidget);
        expect($(Icons.notifications_none_rounded), findsOneWidget);
        expect($(Icons.chat_bubble_outline_rounded), findsOneWidget);
        expect($(Icons.search_rounded), findsOneWidget);

        // Tap Notifications icon
        await $(Icons.notifications_none_rounded).tap();
        await $.pumpAndSettle();
        expect(current, equals(BelongBottomTab.notifications));

        // Golden verification if file exists
        final goldenFile = File('test/features/goldens/goldens/belong_bottom_nav_bar.png');
        if (goldenFile.existsSync()) {
          await expectLater(
            find.byType(BelongBottomNavBar),
            matchesGoldenFile('goldens/belong_bottom_nav_bar.png'),
          );
        }
      },
    );

    patrolWidgetTest(
      'ReflectionCard: renders unhurried reflection, tone badge, reactions and discussion seam',
      ($) async {
        var reactionsAdded = 0;
        var discussionOpened = false;

        final testPost = Post(
          id: 'test-golden-post-1',
          authorName: 'Hannah',
          content: 'He leads me beside quiet waters. Psalm 23 is such a comfort after sensory overload today.',
          spaceKey: 'start_here',
          toneTag: '[Comfort Only]',
          timestamp: DateTime(2026, 10, 20, 14, 0),
          reactions: {'pray': 4, 'peace': 7},
        );

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: RepaintBoundary(
                      child: ReflectionCard(
                        post: testPost,
                        isContrast: false,
                        onAddReaction: (r) => reactionsAdded++,
                        onOpenDiscussion: () => discussionOpened = true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect($('Hannah'), findsOneWidget);
        expect($('[Comfort Only]'), findsOneWidget);
        expect($('He leads me beside quiet waters. Psalm 23 is such a comfort after sensory overload today.'), findsOneWidget);
        expect($('4 Praying'), findsOneWidget);
        expect($('7 Support'), findsOneWidget);

        // Tap reaction button and verify callback
        await $('4 Praying').tap();
        await $.pumpAndSettle();
        expect(reactionsAdded, equals(1));

        // Tap reply / discussion button and verify callback
        await $('Reply').tap();
        await $.pumpAndSettle();
        expect(discussionOpened, isTrue);

        // Golden verification if file exists
        final goldenFile = File('test/features/goldens/goldens/reflection_card.png');
        if (goldenFile.existsSync()) {
          await expectLater(
            find.byType(ReflectionCard),
            matchesGoldenFile('goldens/reflection_card.png'),
          );
        }
      },
    );
  });
}
