import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/firebase/community_analytics_service.dart';
import 'core/firebase/organizer_remote_config_service.dart';
import 'core/presentation/coming_soon_view.dart';
import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/auth/presentation/belong_auth_sheet.dart';
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

/// Main screen of **Belong on the Spectrum** (powered by Refuge / Sanctuary),
/// built as a [HookConsumerWidget] following CodeWithAndrea's feature-first
/// architecture (#18, #22, #23, #26, #35).
class SanctuaryHomeScreen extends HookConsumerWidget {
  final VoidCallback? onSwitchTheme;

  const SanctuaryHomeScreen({super.key, this.onSwitchTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = useState(0);
    final selectedSpace = useState('general_chat');
    final activeToneFilter = useState('All');
    final homeSubView = useState(BelongHomeSubView.feed);
    final activeComingSoonItem = useState<FellowshipSpaceItem?>(null);

    // 7-tap Observability Easter Egg state
    final easterEggTapCount = useState(0);
    final easterEggLastTap = useState<DateTime>(DateTime.now());

    final brand = ref.watch(brandConfigProvider);
    final theme = ref.watch(sensoryThemeControllerProvider);
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
    final analytics = ref.watch(communityAnalyticsServiceProvider);
    final activeRepository = ref.watch(postRepositoryProvider);
    final profile = ref.watch(activeUserProfileProvider);

    final isContrast = theme.mode == SensoryMode.highContrast;
    final primaryColor = isContrast ? Colors.white : brand.primaryColor;

    void handleTabChange(int index) {
      currentTab.value = index;
      analytics.logScreenView(switch (index) {
        0 => 'home_screen',
        1 => 'spaces_directory',
        2 => 'direct_messages',
        3 => 'notifications',
        _ => 'search',
      });
    }

    void handleSelectSpace(String spaceKey) {
      selectedSpace.value = spaceKey;
      homeSubView.value = BelongHomeSubView.feed;
      activeComingSoonItem.value = null;
      analytics.logSpaceViewed(spaceKey);
    }

    void selectSpace(String spaceKey) {
      selectedSpace.value = spaceKey;
      homeSubView.value = BelongHomeSubView.feed;
      activeComingSoonItem.value = null;
      analytics.logSpaceViewed(spaceKey);
    }

    Future<void> submitPost({
      required String content,
      required String toneTag,
      String? specialInterestTag,
      String? imageUrl,
    }) async {
      await activeRepository.createPost(
        Post(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorName: profile.displayName,
          spaceKey: selectedSpace.value,
          toneTag: toneTag,
          specialInterestTag: specialInterestTag,
          imageUrl: imageUrl,
          content: content,
          timestamp: DateTime.now(),
          reactions: {'pray': 1, 'peace': 1, 'encouraged': 1, 'relatable': 1},
        ),
      );
    }

    Widget buildHomeBody() {
      if (homeSubView.value == BelongHomeSubView.membersDirectory) {
        return BelongMembersDirectoryView(
          onBackToSpaces: () => homeSubView.value = BelongHomeSubView.spaces,
        );
      }

      if (homeSubView.value == BelongHomeSubView.spaces) {
        return BelongSpacesDirectoryView(
          selectedSpaceSlug: selectedSpace.value,
          onSelectSpaceItem: (item) {
            if (item.slug == 'members_directory') {
              homeSubView.value = BelongHomeSubView.membersDirectory;
            } else if (item.isComingSoon) {
              activeComingSoonItem.value = item;
            } else {
              handleSelectSpace(item.slug);
            }
          },
        );
      }

      // If a coming soon item was clicked from a drawer or directory
      if (activeComingSoonItem.value != null) {
        return ComingSoonView(
          item: activeComingSoonItem.value!,
          onBack: () => activeComingSoonItem.value = null,
        );
      }

      // Default: Clean Single-Column Feed with Reflections
      return StreamBuilder<List<Post>>(
        stream: activeRepository.watchPosts(spaceKey: selectedSpace.value),
        builder: (context, snapshot) {
          final posts = snapshot.data ?? [];
          final spaceTitle =
              FellowshipSpaceDirectory.resolveTitle(selectedSpace.value);

          final filteredPosts = activeToneFilter.value == 'All'
              ? posts
              : posts.where((p) => p.toneTag == activeToneFilter.value).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SpaceNavigationBar(
                  currentSpaceSlug: selectedSpace.value,
                  onSelectSpace: handleSelectSpace,
                  onOpenAllSpaces: () =>
                      homeSubView.value = BelongHomeSubView.spaces,
                ),
              ),
              if (selectedSpace.value == 'general_chat' ||
                  selectedSpace.value == 'start_here')
                SliverToBoxAdapter(
                  child: CommunityAnchorBanner(
                    remoteConfig: remoteConfig,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                  ),
                ),
              SliverToBoxAdapter(
                child: ToneFilterRow(
                  activeFilter: activeToneFilter.value,
                  onSelectFilter: (filter) => activeToneFilter.value = filter,
                  primaryColor: primaryColor,
                ),
              ),
              SliverToBoxAdapter(
                child: ReflectionComposer(
                  selectedSpace: selectedSpace.value,
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                  onSubmit: submitPost,
                ),
              ),
              if (filteredPosts.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(24.0),
                    padding: const EdgeInsets.all(20.0),
                    alignment: Alignment.center,
                    child: Text(
                      'No reflections under "${activeToneFilter.value}" yet.\nFeel free to share an unhurried thought above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];
                        return ReflectionCard(
                          post: post,
                          isContrast: isContrast,
                          onAddReaction: (type) => activeRepository.addReaction(
                            postId: post.id,
                            reactionType: type,
                          ),
                        );
                      },
                      childCount: filteredPosts.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      );
    }

    Widget buildCurrentTabBody() {
      return switch (currentTab.value) {
        0 => buildHomeBody(),
        1 => BelongSpacesDirectoryView(
            selectedSpaceSlug: selectedSpace.value,
            onSelectSpaceItem: (item) {
              if (item.slug == 'members_directory') {
                homeSubView.value = BelongHomeSubView.membersDirectory;
                currentTab.value = 0;
              } else if (item.isComingSoon) {
                activeComingSoonItem.value = item;
                currentTab.value = 0;
              } else {
                handleSelectSpace(item.slug);
                currentTab.value = 0;
              }
            },
          ),
        2 => const BelongMessagesView(),
        3 => const CalmNotificationsView(),
        _ => const CommunitySearchView(),
      };
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final now = DateTime.now();
            final difference = now.difference(easterEggLastTap.value);
            easterEggLastTap.value = now;

            if (difference < const Duration(milliseconds: 700)) {
              easterEggTapCount.value++;
            } else {
              easterEggTapCount.value = 1;
            }

            if (easterEggTapCount.value >= 7) {
              easterEggTapCount.value = 0;
              showDialog(
                context: context,
                builder: (_) => const ObservabilityEasterEggDialog(),
              );
            }
          },
          child: Row(
            children: [
              Image.asset(
                brand.logoAssetPath,
                height: 28,
                width: 28,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.all_inclusive, size: 24, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  brand.communityName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'About Belong on the Spectrum',
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AboutRefugeDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Feedback & Feature Voting Board',
            icon: const Icon(Icons.how_to_vote_outlined, size: 20),
            onPressed: () => showBelongFeedbackAndVotingSheet(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: () {
                final auth = ref.read(authServiceProvider);
                final currentUser = auth.currentUser;

                if (currentUser == null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const BelongAuthSheet(),
                  );
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const MemberProfileDialog(),
                  );
                }
              },
              child: CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : 'B',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: buildCurrentTabBody(),
      bottomNavigationBar: BelongBottomNavBar(
        currentIndex: currentTab.value,
        onTap: handleTabChange,
        primaryColor: primaryColor,
      ),
    );
  }
}
