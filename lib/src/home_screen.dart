import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'core/firebase/analytics_service.dart';
import 'core/firebase/auth_provider.dart';
import 'core/firebase/organizer_remote_config_service.dart';
import 'core/presentation/coming_soon_view.dart';
import 'core/presentation/top_bar_sign_in_button.dart';
import 'features/auth/domain/user_profile.dart';
import 'features/auth/presentation/auth_view.dart';
import 'features/branding/domain/community_brand_config.dart';
import 'features/feedback/presentation/feedback_sheet.dart';
import 'features/fellowship_spaces/domain/fellowship_space.dart';
import 'features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'features/fellowship_spaces/presentation/spaces_drawer.dart';
import 'features/messages/presentation/calm_messages_view.dart';
import 'features/messages/presentation/calm_notifications_view.dart';
import 'features/observability/presentation/observability_easter_egg_dialog.dart';
import 'features/preview/data/preview_mode_service.dart';
import 'features/profile/presentation/member_profile_sheet.dart';
import 'features/profile/presentation/members_directory_view.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
import 'features/reflections/presentation/tone_filter_row.dart';
import 'features/search/presentation/community_search_view.dart';
import 'features/sensory/domain/sensory_theme.dart';
import 'features/sensory/presentation/ambient_soundscape_sheet.dart';
import 'features/sensory/presentation/sensory_theme_modal.dart';

/// Top-level Home navigation sub-view: Main feed, directory, or direct spaces
enum BelongHomeSubView { feed, spaces, membersDirectory }

/// Cleaned up Belong on the Spectrum home screen with 4 bottom tabs,
/// sensory accessibility theme switcher, and quiet reassurance.
class HomeScreen extends HookConsumerWidget {
  final VoidCallback? onSwitchTheme;

  const HomeScreen({super.key, this.onSwitchTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = useState(0);
    final selectedSpace = useState('general_chat');
    final activeToneFilter = useState('All');
    final homeSubView = useState(BelongHomeSubView.feed);
    final isSensoryModalOpen = useState(false);
    final activeComingSoonItem = useState<FellowshipSpaceItem?>(null);

    // State for 7-tap Observability Easter Egg
    final easterEggTapCount = useState(0);
    final easterEggLastTap = useState<DateTime>(DateTime.now());

    final brand = ref.watch(communityBrandConfigProvider);
    final theme = ref.watch(sensoryThemeProvider);
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final activeRepository = ref.watch(postRepositoryProvider);
    final profile = ref.watch(currentUserProfileProvider);

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
          final spaceTitle = FellowshipSpaceDirectory.resolveTitle(selectedSpace.value);

          final filteredPosts = activeToneFilter.value == 'All'
              ? posts
              : posts.where((p) => p.toneTag == activeToneFilter.value).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            spaceTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${posts.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => homeSubView.value = BelongHomeSubView.spaces,
                        icon: const Icon(Icons.apps_rounded, size: 16),
                        label: const Text('All Spaces', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedSpace.value == 'general_chat' || selectedSpace.value == 'start_here')
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
        2 => const CalmMessagesView(),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Calm Soundscapes & Brown Noise',
            icon: const Icon(Icons.waves_rounded, size: 20),
            onPressed: () => showAmbientSoundscapeModal(context),
          ),
          IconButton(
            tooltip: 'Sensory Theme & Comfort Preferences',
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () {
              isSensoryModalOpen.value = true;
              showSensoryThemeModal(context, onClosed: () => isSensoryModalOpen.value = false);
            },
          ),
          IconButton(
            tooltip: 'Feedback & Feature Voting Board',
            icon: const Icon(Icons.how_to_vote_outlined, size: 20),
            onPressed: () => showFeedbackModal(context),
          ),
          const TopBarSignInButton(),
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const BelongAuthSheet(),
                  );
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const MemberProfileDialog(),
                  );
                }
              },
              child: CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                child: Text(
                  profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'B',
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
      drawer: SpacesDrawer(
        currentSpaceKey: selectedSpace.value,
        onSelectSpace: (spaceKey) {
          handleSelectSpace(spaceKey);
          Navigator.of(context).pop();
        },
        onOpenComingSoon: (item) {
          activeComingSoonItem.value = item;
          homeSubView.value = BelongHomeSubView.feed;
          Navigator.of(context).pop();
        },
        onOpenMembersDirectory: () {
          homeSubView.value = BelongHomeSubView.membersDirectory;
          Navigator.of(context).pop();
        },
      ),
      body: buildCurrentTabBody(),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: currentTab.value,
        onTap: handleTabChange,
        selectedItemColor: primaryColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            title: const Text('Home'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view_rounded),
            title: const Text('Spaces'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.mail_outline_rounded),
            activeIcon: const Icon(Icons.mail_rounded),
            title: const Text('Msgs'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.notifications_none_rounded),
            activeIcon: const Icon(Icons.notifications_rounded),
            title: const Text('Alerts'),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.search_rounded),
            activeIcon: const Icon(Icons.manage_search_rounded),
            title: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
