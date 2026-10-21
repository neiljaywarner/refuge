import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/firebase/community_analytics_service.dart';
import 'core/firebase/organizer_remote_config_service.dart';
import 'core/presentation/coming_soon_view.dart';
import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/auth/presentation/belong_auth_sheet.dart';
import 'features/auth/presentation/belong_firebase_auth_screen.dart';
import 'features/branding/presentation/brand_config_provider.dart';
import 'features/events/presentation/actually_autistic_events_view.dart';
import 'features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'features/fellowship_spaces/domain/fellowship_space.dart';
import 'features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'features/messages/presentation/belong_messages_view.dart';
import 'features/messages/presentation/calm_notifications_view.dart';
import 'features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'features/observability/presentation/observability_easter_egg_dialog.dart';
import 'features/profile/domain/member_profile.dart';
import 'features/profile/presentation/belong_members_directory_view.dart';
import 'features/profile/presentation/member_profile_sheet.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/reflections/data/serverpod_post_repository.dart';
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/quiet_digest_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
import 'features/reflections/presentation/space_navigation_bar.dart';
import 'features/reflections/presentation/tone_filter_row.dart';
import 'features/search/presentation/community_search_view.dart';
import 'features/sensory_themes/domain/sensory_mode.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';

/// Sub-navigation mode below the Belong logo inside the `Home` bottom tab.
enum BelongHomeSubView { feed, spaces, comingSoonItem, membersDirectory }

/// Main screen of **Belong on the Spectrum** (powered by Refuge),
/// built as a [HookConsumerWidget] following CodeWithAndrea's feature-first
/// architecture (#18, #22, #23, #26, #35).
class RefugeHomeScreen extends HookConsumerWidget {
  final PostRepository? repository;
  final ThemeNotifier? themeNotifier;

  const RefugeHomeScreen({super.key, this.repository, this.themeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);
    final isPreview = ref.watch(previewFeaturesEnabledProvider);

    // Sub-view within Home (Feed vs Spaces Directory vs Members)
    final homeSubView = useState<BelongHomeSubView>(BelongHomeSubView.feed);

    // Active bottom-nav index (0: Home, 1: Events, 2: Msgs, 3: Search)
    final activeNavIndex = useState<int>(0);

    final currentSpace = useState<FellowshipSpace>(FellowshipSpace.prayerSanctuary);
    final toneFilter = useState<String>('all');

    final effectiveThemeNotifier = themeNotifier ?? ThemeNotifier();
    final currentMode = effectiveThemeNotifier.mode;
    final primaryColor = SensoryThemeData.getPrimaryColor(currentMode);
    final isContrast = SensoryThemeData.isHighContrast(currentMode);

    void setSensoryMode(SensoryMode mode) {
      effectiveThemeNotifier.setMode(mode);
      ref.read(communityAnalyticsServiceProvider).logSensoryThemeChanged(mode.name);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: InkWell(
          key: const Key('belong_home_logo_button'),
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            homeSubView.value = BelongHomeSubView.feed;
            activeNavIndex.value = 0;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isContrast ? Colors.white : primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '♾️',
                      style: TextStyle(fontSize: 16, color: isContrast ? Colors.black : Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brand.shortName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    Text(
                      brand.brandTagline,
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.2,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: SensoryThemePicker(
              primaryColor: primaryColor,
              isContrast: isContrast,
              currentMode: currentMode,
              onSelectMode: setSensoryMode,
            ),
          ),
          IconButton(
            key: const Key('belong_about_info_button'),
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: 'About Belong',
            onPressed: () => AboutRefugeDialog.show(context),
          ),
          if (!profile.isSignedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: FilledButton.tonalIcon(
                key: const Key('home_top_bar_sign_in_button'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BelongFirebaseSignInScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 15),
                label: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: const Key('belong_profile_avatar_button'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => MemberProfileDialog.show(context),
              child: Tooltip(
                message: 'Member Profile (${profile.displayName})',
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isContrast
                      ? Colors.white
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    profile.initials,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isContrast
                          ? Colors.black
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BelongBottomNavBar(
        currentIndex: activeNavIndex.value,
        onTap: (index) {
          activeNavIndex.value = index;
          if (index == 0) {
            homeSubView.value = BelongHomeSubView.feed;
          }
        },
      ),
      body: IndexedStack(
        index: activeNavIndex.value,
        children: [
          // 0: Home view with top sub-navigation
          Column(
            children: [
              // Home sub-view navigation chips (Feed vs Spaces)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        key: const Key('home_subview_feed_chip'),
                        avatar: const Icon(Icons.dynamic_feed_rounded, size: 15),
                        label: const Text('Feed', style: TextStyle(fontSize: 12)),
                        selected: homeSubView.value == BelongHomeSubView.feed,
                        onSelected: (_) => homeSubView.value = BelongHomeSubView.feed,
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        key: const Key('home_subview_spaces_chip'),
                        avatar: const Icon(Icons.hub_outlined, size: 15),
                        label: const Text('Spaces', style: TextStyle(fontSize: 12)),
                        selected: homeSubView.value == BelongHomeSubView.spaces,
                        onSelected: (_) => homeSubView.value = BelongHomeSubView.spaces,
                      ),
                      if (isPreview) ...[
                        const SizedBox(width: 6),
                        ChoiceChip(
                          key: const Key('home_subview_members_chip'),
                          avatar: const Icon(Icons.people_outline_rounded, size: 15),
                          label: const Text('Members', style: TextStyle(fontSize: 12)),
                          selected: homeSubView.value == BelongHomeSubView.membersDirectory,
                          onSelected: (_) => homeSubView.value = BelongHomeSubView.membersDirectory,
                        ),
                      ],
                      const SizedBox(width: 6),
                      ActionChip(
                        key: const Key('home_subview_feedback_chip'),
                        avatar: const Icon(Icons.how_to_vote_rounded, size: 15),
                        label: const Text('Vote & Feedback', style: TextStyle(fontSize: 12)),
                        onPressed: () => BelongFeedbackAndVotingSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Active sub-view body
              Expanded(
                child: switch (homeSubView.value) {
                  BelongHomeSubView.feed => _buildFeedView(
                      context,
                      ref,
                      brand,
                      currentSpace,
                      toneFilter,
                    ),
                  BelongHomeSubView.spaces => BelongSpacesDirectoryView(
                      currentSpace: currentSpace.value,
                      onSelectSpace: (space) {
                        currentSpace.value = space;
                        homeSubView.value = BelongHomeSubView.feed;
                      },
                    ),
                  BelongHomeSubView.membersDirectory => const BelongMembersDirectoryView(),
                  BelongHomeSubView.comingSoonItem => ComingSoonView(
                      featureTitle: 'Community Fellowship',
                      onDismiss: () => homeSubView.value = BelongHomeSubView.feed,
                    ),
                },
              ),
            ],
          ),

          // 1: Actually Autistic Events View (ADR-0008, #28)
          const ActuallyAutisticEventsView(),

          // 2: Messages View (ADR-0008, #27)
          const BelongMessagesView(),

          // 3: Community Search View (ADR-0007, #21)
          const CommunitySearchView(),
        ],
      ),
    );
  }

  Widget _buildFeedView(
    BuildContext context,
    WidgetRef ref,
    dynamic brand,
    ValueNotifier<FellowshipSpace> currentSpace,
    ValueNotifier<String> toneFilter,
  ) {
    return Column(
      children: [
        // Community anchor welcome banner
        CommunityAnchorBanner(
          onTapStartHere: () {
            currentSpace.value = FellowshipSpace.startHere;
          },
        ),

        // Organizer Announcements Banner (#50, ADR-0006)
        const OrganizerRemoteConfigBanner(),

        // Space selection tabs
        SpaceNavigationBar(
          currentSpace: currentSpace.value,
          onSpaceSelected: (space) {
            currentSpace.value = space;
          },
        ),

        // Quiet digest banner
        const QuietDigestBanner(),

        // Reflection composer
        ReflectionComposer(
          activeSpace: currentSpace.value,
        ),

        // Tone & intent filter row
        ToneFilterRow(
          selectedFilter: toneFilter.value,
          onFilterChanged: (filter) {
            toneFilter.value = filter;
          },
        ),

        // Reflections feed list
        Expanded(
          child: _FeedList(
            currentSpace: currentSpace.value,
            toneFilter: toneFilter.value,
            repository: repository,
          ),
        ),
      ],
    );
  }
}

class _FeedList extends ConsumerWidget {
  final FellowshipSpace currentSpace;
  final String toneFilter;
  final PostRepository? repository;

  const _FeedList({
    required this.currentSpace,
    required this.toneFilter,
    this.repository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When a PostRepository is passed directly (tests / overrides), read its stream.
    // Otherwise fallback to the registered postRepositoryProvider.
    final effectiveRepo = repository ?? ref.watch(postRepositoryProvider);

    return StreamBuilder<List<Post>>(
      stream: effectiveRepo.watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = (snapshot.data ?? const <Post>[])
            .where((post) {
              if (currentSpace != FellowshipSpace.all && post.space != currentSpace) {
                // If post has no space assigned, display it everywhere
                if (post.space != null) return false;
              }
              if (toneFilter != 'all' && post.tone != toneFilter) {
                return false;
              }
              return true;
            })
            .toList();

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_outlined, size: 36, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    'No reflections in ${currentSpace.displayName} yet.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Be the first to share a quiet, honest thought.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return ReflectionCard(
              post: post,
              onAffirmationAdded: (type) {
                effectiveRepo.addAffirmation(post.id, type);
              },
            );
          },
        );
      },
    );
  }
}
