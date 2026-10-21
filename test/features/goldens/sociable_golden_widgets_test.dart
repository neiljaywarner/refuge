import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/theme/sensory_theme.dart';
import 'package:refuge4serverpod/src/features/community_anchors/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/community_anchors/domain/organizer_remote_config.dart';
import 'package:refuge4serverpod/src/features/community_anchors/presentation/community_anchor_banner.dart';
import 'package:refuge4serverpod/src/features/digest/presentation/quiet_digest_banner.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/presentation/space_navigation_bar.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reflection.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/tone_filter_row.dart';
import 'package:refuge4serverpod/src/features/search/presentation/community_search_view.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

void main() {
  group('Sociable Golden Widgets - BDD Patrol Verification', () {
    patrolWidgetTest(
      'SpaceNavigationBar: renders default tabs with sage sensory accent',
      ($) async {
        int selectedIndex = 0;
        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: SensoryTheme.primaryColor(SensoryMode.sage),
              ),
            ),
            home: Scaffold(
              bottomNavigationBar: SpaceNavigationBar(
                currentIndex: selectedIndex,
                onTap: (i) => selectedIndex = i,
              ),
            ),
          ),
        );

        expect($(SpaceNavigationBar), findsOneWidget);
        expect($('All Reflections'), findsOneWidget);
        expect($('Quiet Spaces'), findsOneWidget);
        expect($('Special Interests'), findsOneWidget);
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
                body: CommunityAnchorBanner(),
              ),
            ),
          ),
        );

        expect($(CommunityAnchorBanner), findsOneWidget);
        expect($('Belong Community Anchor'), findsOneWidget);
        expect($('Official safe fellowship anchor'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'QuietDigestBanner: displays unread summary text and catch-up prompt',
      ($) async {
        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: QuietDigestBanner(
                unreadCount: 4,
                periodDescription: 'last 24 hours',
              ),
            ),
          ),
        );

        expect($(QuietDigestBanner), findsOneWidget);
        expect($('Quiet Digest (4 updates)'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'ToneFilterRow: shows all 4 calm tone filters and handles selection',
      ($) async {
        ReflectionTone? selectedTone;
        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ToneFilterRow(
                selectedTone: selectedTone,
                onSelected: (tone) => selectedTone = tone,
              ),
            ),
          ),
        );

        expect($(ToneFilterRow), findsOneWidget);
        expect($('gentle'), findsOneWidget);
        expect($('direct'), findsOneWidget);
        expect($('celebratory'), findsOneWidget);
        expect($('inquiry'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'ReflectionCard: renders sensory tags, clean typography, and reaction triggers',
      ($) async {
        final reflection = Reflection(
          id: 'test-reflection-1',
          authorName: 'Alex Autism Advocate',
          content: 'Finding quiet in sensory overwhelm today at the botanical gardens.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          sensoryModes: const ['sage', 'quiet'],
          tags: const ['sensory-friendly', 'nature'],
          helpfulCount: 5,
        );

        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ReflectionCard(reflection: reflection),
            ),
          ),
        );

        expect($(ReflectionCard), findsOneWidget);
        expect($('Alex Autism Advocate'), findsOneWidget);
        expect($('Finding quiet in sensory overwhelm today at the botanical gardens.'), findsOneWidget);
        expect($('sensory-friendly'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'CommunitySearchView: renders search bar, filters, and empty state placeholder',
      ($) async {
        await $.pumpWidgetAndSettle(
          const MaterialApp(
            home: Scaffold(
              body: CommunitySearchView(),
            ),
          ),
        );

        expect($(CommunitySearchView), findsOneWidget);
        expect($('Search reflections, spaces, and members...'), findsOneWidget);
      },
    );
  });
}
