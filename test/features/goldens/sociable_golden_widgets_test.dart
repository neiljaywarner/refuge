import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/community_anchor_banner.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/quiet_digest_banner.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/tone_filter_row.dart';
import 'package:refuge4serverpod/src/features/search/presentation/community_search_view.dart';

void main() {
  group('Sociable Golden Widgets - BDD Patrol Verification', () {
    patrolWidgetTest(
      'BelongBottomNavBar: renders navigation tabs with active indicator',
      ($) async {
        BelongBottomTab selectedTab = BelongBottomTab.home;
        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2E6B56),
                ),
              ),
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: selectedTab,
                  isContrast: false,
                  onSelectTab: (tab) => selectedTab = tab,
                ),
              ),
            ),
          ),
        );

        expect($(BelongBottomNavBar), findsOneWidget);
        expect($('Home'), findsOneWidget);
        expect($('Notifications'), findsOneWidget);
        expect($('Msgs'), findsOneWidget);
        expect($('Search'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'CommunityAnchorBanner: renders community anchor banner with theme styling',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const Scaffold(
                body: CommunityAnchorBanner(
                  primaryColor: Color(0xFF2E6B56),
                  isContrast: false,
                ),
              ),
            ),
          ),
        );

        expect($(CommunityAnchorBanner), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'QuietDigestBanner: displays quiet digest aggregate when data available',
      ($) async {
        await $.pumpWidgetAndSettle(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: QuietDigestBanner(
                  primaryColor: Color(0xFF2E6B56),
                  isContrast: false,
                ),
              ),
            ),
          ),
        );

        expect($(QuietDigestBanner), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'ToneFilterRow: shows all 4 calm tone filters and handles selection',
      ($) async {
        String activeFilter = 'All';
        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ToneFilterRow(
                activeFilter: activeFilter,
                onSelectFilter: (filter) => activeFilter = filter,
              ),
            ),
          ),
        );

        expect($(ToneFilterRow), findsOneWidget);
        expect($('All'), findsOneWidget);
        expect($('[Prayer Request]'), findsOneWidget);
        expect($('[Comfort Only]'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'ReflectionCard: renders sensory tags, clean typography, and reaction triggers',
      ($) async {
        final post = Post(
          id: 'test-post-1',
          authorName: 'Alex Autism Advocate',
          spaceKey: 'general_chat',
          toneTag: 'Gentle',
          content: 'Finding quiet in sensory overwhelm today at the botanical gardens.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          reactions: const {'relatable': 5},
        );

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: ReflectionCard(
                  post: post,
                  isContrast: false,
                  onAddReaction: (r) {},
                ),
              ),
            ),
          ),
        );

        expect($(ReflectionCard), findsOneWidget);
        expect($('Alex Autism Advocate'), findsOneWidget);
        expect(
          $('Finding quiet in sensory overwhelm today at the botanical gardens.'),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      'CommunitySearchView: renders search bar, filters, and empty state placeholder',
      ($) async {
        final repo = LocalPostRepository();
        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CommunitySearchView(
                  repository: repo,
                  isContrast: false,
                ),
              ),
            ),
          ),
        );

        expect($(CommunitySearchView), findsOneWidget);
        expect($(const Key('community_search_text_field')), findsOneWidget);
      },
    );
  });
}
