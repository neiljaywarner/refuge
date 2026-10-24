import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'constants/app_theme.dart';
import 'core/analytics/analytics_service.dart';
import 'core/logging/app_logger.dart';
import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/auth/presentation/simple_auth.dart';
import 'features/auth/presentation/simple_auth_profile_dialog.dart';
import 'features/events/presentation/actually_autistic_events_view.dart';
import 'features/feedback/presentation/feedback_submission_dialog.dart';
import 'features/fellowship_spaces/domain/fellowship_space.dart';
import 'features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'features/messages/presentation/belong_messages_view.dart';
import 'features/navigation/domain/belong_bottom_tab.dart';
import 'features/navigation/domain/belong_home_subview.dart';
import 'features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'features/notifications/presentation/calm_notifications_view.dart';
import 'features/observability/presentation/observability_easter_egg_dialog.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/presentation/belong_members_directory_view.dart';
import 'features/reflections/data/local_post_repository.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/reflections/data/serverpod_post_repository.dart';
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/feed_sort_row.dart';
import 'features/reflections/presentation/quiet_digest_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
import 'features/reflections/presentation/reflections_providers.dart';
import 'features/reflections/presentation/space_navigation_bar.dart';
import 'features/reflections/presentation/tone_filter_row.dart';
import 'features/remote_config/data/remote_config_repository.dart';
import 'features/search/presentation/community_search_view.dart';
import 'features/sensory_themes/domain/sensory_mode.dart';
import 'features/sensory_themes/presentation/sensory_theme_menu_dialog.dart';

/// Unhurried refuge home screen with calm sensory controls, authentic fellowship spaces,
/// dual-redundant Serverpod/Firestore synchronization, and private saved reading list.
class RefugeHomeScreen extends HookConsumerWidget {
  final PostRepository? repository;
  final SensoryThemeNotifier? themeNotifier;

  const RefugeHomeScreen({super.key, this.repository, this.themeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpace = useState<String>('general_chat');
    final activeFilter = useState<String>('All');
    final activeSort = useState<FeedSortOption>(FeedSortOption.newest);
    final profile = ref.watch(profileRepositoryProvider).currentProfile;
    final analytics = ref.watch(analyticsServiceProvider);
    final remoteConfig = ref.watch(remoteConfigRepositoryProvider);
    final activeBottomTab = useState<BelongBottomTab>(BelongBottomTab.home);
    final homeSubView = useState<BelongHomeSubView>(BelongHomeSubView.feed);
    final activeComingSoonItem = useState<BelongSpaceItem?>(null);
    final easterEggTapCount = useState<int>(0);
    final easterEggLastTap = useState<DateTime?>(null);

    final PostRepository activeRepository =
        repository ?? ref.watch(postRepositoryProvider);

    final postStream = useMemoized(
      () => selectedSpace.value == 'saved_for_later'
          ? activeRepository.watchSavedPosts()
          : activeRepository.watchPosts(spaceKey: selectedSpace.value),
      [activeRepository, selectedSpace.value],
    );
    // Subscribe at the screen level (not inside the feed sub-view) so the
    // subscription and its latest snapshot survive switching to Spaces /
    // other bottom tabs and back (#402, #458).
    final postsSnapshot = useStream(postStream, preserveState: true);
    final quietDigestFuture = useMemoized(
      () => activeRepository.getQuietDigest(spaceKey: selectedSpace.value),
      [activeRepository, selectedSpace.value],
    );
    final quietDigestSnapshot = useFuture(quietDigestFuture);

    final SensoryMode currentMode =
        themeNotifier?.mode ?? ref.watch(sensoryThemeModeProvider);
    final SensoryFontScale currentFontScale =
        themeNotifier?.fontScale ?? ref.watch(sensoryFontScaleProvider);
    final isContrast = currentMode == SensoryMode.contrast;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isLiveServerpod =
        activeRepository is ServerpodPostRepository &&
        activeRepository.isLiveConnected;

    void setSensoryMode(SensoryMode mode) {
      if (themeNotifier != null) {
        themeNotifier!.setMode(mode);
      } else {
        ref.read(sensoryThemeModeProvider.notifier).setMode(mode);
      }
      analytics.logSensoryModeChanged(mode.name);
    }

    void setSensoryFontScale(SensoryFontScale scale) {
      if (themeNotifier != null) {
        themeNotifier!.setFontScale(scale);
      }
      ref.read(sensoryFontScaleProvider.notifier).setScale(scale);
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
      final targetSpace = selectedSpace.value == 'saved_for_later'
          ? 'general_chat'
          : selectedSpace.value;
      await activeRepository.createPost(
        Post(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorName: profile.displayName,
          spaceKey: targetSpace,
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
              homeSubView.value = BelongHomeSubView.comingSoonItem;
            } else {
              selectSpace(item.slug);
            }
          },
        );
      }

      if (homeSubView.value == BelongHomeSubView.comingSoonItem &&
          activeComingSoonItem.value != null) {
        final item = activeComingSoonItem.value!;
        if (item.slug == 'actually_autistic_events') {
          return ActuallyAutisticEventsView(
            onBackToSpaces: () => homeSubView.value = BelongHomeSubView.spaces,
          );
        }
        final isMobileAppLink =
            item.slug == 'link_android_app' || item.slug == 'link_ios_app';
        final extraNote = item.slug == 'link_community_guidelines'
            ? remoteConfig.communityGuidelinesMarkdown
            : item.slug == 'actually_autistic_events'
            ? 'Monthly fellowship meetups on Zoom with soft breakout rooms, shared interests, and text-only participation options.'
            : isMobileAppLink
            ? 'Refuge for Android & iOS is currently available in internal testing with zero popups, calm notifications, and offline reading.'
            : null;

        return BelongComingSoonSpaceView(
          item: item,
          extraNote: extraNote,
          showPwaInstallGuide: isMobileAppLink,
          onBackToFeed: () => homeSubView.value = BelongHomeSubView.feed,
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompactHeight = constraints.maxHeight < 520;
          return Column(
            children: [
              if (!isCompactHeight)
                CommunityAnchorBanner(
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                ),
              if (!profile.isSignedIn)
                Container(
                  key: const Key('demo_mode_banner'),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.black
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isContrast
                          ? Colors.white
                          : primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('🎭', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo Mode · Sample reflections shown. Sign in to view and share live community reflections.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SpaceNavigationBar(
                selectedSpace: selectedSpace.value,
                onSelectSpace: selectSpace,
              ),
              if (!isCompactHeight)
                QuietDigestBanner(
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                  legacyMessage: quietDigestSnapshot.data,
                ),
              ReflectionComposer(
                selectedSpace: selectedSpace.value,
                primaryColor: primaryColor,
                isContrast: isContrast,
                onSubmit: submitPost,
              ),
              ToneFilterRow(
                activeFilter: activeFilter.value,
                onSelectFilter: (f) => activeFilter.value = f,
              ),
              FeedSortRow(
                activeSort: activeSort.value,
                isContrast: isContrast,
                onSelectSort: (s) {
                  activeSort.value = s;
                  ref.read(feedSortOptionProvider.notifier).state = s;
                  analytics.logEvent(
                    'feed_sort_changed',
                    parameters: {'sort': s.name},
                  );
                },
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final snapshot = postsSnapshot;
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    final allPosts = snapshot.data!;
                    final availablePosts = profile.isSignedIn
                        ? allPosts.where((p) => !p.isDemo).toList()
                        : allPosts;
                    final filteredPosts = activeFilter.value == 'All'
                        ? availablePosts
                        : availablePosts
                              .where((p) => p.toneTag == activeFilter.value)
                              .toList();

                    final sortedPosts = ref.watch(sortedFeedPostsProvider(filteredPosts));

                    if (sortedPosts.isEmpty) {
                      if (selectedSpace.value == 'saved_for_later') {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No saved reflections yet.\nTap the bookmark ribbon (🔖) on any reflection to save it for quiet, unhurried reading later.',
                                  key: const Key(
                                    'empty_saved_reflections_placeholder',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Text(
                          profile.isSignedIn
                              ? 'No community reflections yet in this space.'
                              : 'Space is quiet right now.\nBe the first to share an unhurried thought.',
                          key: const Key('empty_reflections_placeholder'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: sortedPosts.length,
                      itemBuilder: (context, index) {
                        final post = sortedPosts[index];
                        return ReflectionCard(
                          post: post,
                          isContrast: isContrast,
                          onAddReaction: (r) => activeRepository.addReaction(
                            postId: post.id,
                            reactionType: r,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }

    Widget buildActiveBottomTabBody() {
      switch (activeBottomTab.value) {
        case BelongBottomTab.home:
          return Column(
            children: [
              _BelongSubHeaderBar(
                activeSubView: homeSubView.value,
                onSelectFeed: () => homeSubView.value = BelongHomeSubView.feed,
                onSelectSpaces: () =>
                    homeSubView.value = BelongHomeSubView.spaces,
                primaryColor: primaryColor,
                isContrast: isContrast,
              ),
              Expanded(child: buildHomeBody()),
            ],
          );
        case BelongBottomTab.notifications:
          return CalmNotificationsView(
            onBackToHome: () => activeBottomTab.value = BelongBottomTab.home,
          );
        case BelongBottomTab.msgs:
          return const BelongMessagesView();
        case BelongBottomTab.search:
          return CommunitySearchView(
            repository: activeRepository,
            isContrast: isContrast,
          );
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        titleSpacing: 8,
        title: InkWell(
          key: const Key('belong_app_bar_title_tap_target'),
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final now = DateTime.now();
            final last = easterEggLastTap.value;
            if (last != null && now.difference(last).inMilliseconds < 1500) {
              easterEggTapCount.value++;
            } else {
              easterEggTapCount.value = 1;
            }
            easterEggLastTap.value = now;

            if (easterEggTapCount.value >= 7) {
              easterEggTapCount.value = 0;
              analytics.logEvent('easter_egg_unlocked');
              ObservabilityEasterEggDialog.show(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.yellow
                        : primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '✝',
                    style: TextStyle(
                      fontSize: 14,
                      color: isContrast ? Colors.black : primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BELONG',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: isContrast
                        ? Colors.yellow
                        : Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '♾',
                  style: TextStyle(
                    fontSize: 13,
                    color: isContrast ? Colors.yellow : const Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const Key('sensory_menu_button'),
            tooltip: 'Sensory Comfort & Theme Options',
            icon: Icon(
              Icons.palette_outlined,
              color: isContrast ? Colors.yellow : null,
            ),
            onPressed: () => SensoryThemeMenuDialog.show(
              context,
              currentMode: currentMode,
              currentScale: currentFontScale,
              onSelectMode: setSensoryMode,
              onSelectScale: setSensoryFontScale,
            ),
          ),
          IconButton(
            key: const Key('feature_voting_action_button'),
            tooltip: 'Feature Voting & Community Feedback',
            icon: Icon(
              Icons.how_to_vote_outlined,
              color: isContrast ? Colors.yellow : null,
            ),
            onPressed: () => FeedbackSubmissionDialog.show(
              context,
              initialCategory: FeedbackCategory.featureVote,
            ),
          ),
          IconButton(
            key: const Key('community_feedback_action_button'),
            tooltip: 'Private Community Feedback & Care Suggestion',
            icon: Icon(
              Icons.volunteer_activism_outlined,
              color: isContrast ? Colors.yellow : null,
            ),
            onPressed: () => FeedbackSubmissionDialog.show(
              context,
              initialCategory: FeedbackCategory.privateFeedback,
            ),
          ),
          IconButton(
            key: const Key('about_belong_action_button'),
            tooltip: 'About Belong & ICOC Fellowship',
            icon: Icon(
              Icons.info_outline,
              color: isContrast ? Colors.yellow : null,
            ),
            onPressed: () => AboutRefugeDialog.show(
              context,
              remoteConfig: remoteConfig,
              isContrast: isContrast,
            ),
          ),
          if (profile.isSignedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                key: const Key('user_profile_avatar_tap_target'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => SimpleAuthProfileDialog.show(context),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    key: const Key('user_profile_avatar'),
                    radius: 14,
                    backgroundColor: isContrast
                        ? Colors.yellow
                        : primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.black : primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                key: const Key('simple_auth_signin_button'),
                tooltip: 'Sign In / Register',
                icon: Icon(
                  Icons.login_rounded,
                  color: isContrast ? Colors.yellow : null,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimpleAuthScreen()),
                ),
              ),
            ),
        ],
      ),
      body: buildActiveBottomTabBody(),
      bottomNavigationBar: BelongBottomNavBar(
        currentTab: activeBottomTab.value,
        onSelectTab: (tab) {
          activeBottomTab.value = tab;
          analytics.logEvent(
            'bottom_nav_switched',
            parameters: {'tab': tab.name},
          );
        },
        isContrast: isContrast,
      ),
    );
  }
}

class _BelongSubHeaderBar extends StatelessWidget {
  final BelongHomeSubView activeSubView;
  final VoidCallback onSelectFeed;
  final VoidCallback onSelectSpaces;
  final Color primaryColor;
  final bool isContrast;

  const _BelongSubHeaderBar({
    required this.activeSubView,
    required this.onSelectFeed,
    required this.onSelectSpaces,
    required this.primaryColor,
    required this.isContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isContrast ? Colors.white : Theme.of(context).dividerColor,
            width: isContrast ? 1.5 : 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _SubHeaderTab(
            key: const Key('subnav_feed_tab'),
            label: 'Feed',
            icon: Icons.dynamic_feed_rounded,
            isSelected: activeSubView == BelongHomeSubView.feed,
            onTap: onSelectFeed,
            primaryColor: primaryColor,
            isContrast: isContrast,
          ),
          const SizedBox(width: 8),
          _SubHeaderTab(
            key: const Key('subnav_spaces_tab'),
            label: 'Spaces',
            icon: Icons.grid_view_rounded,
            isSelected:
                activeSubView == BelongHomeSubView.spaces ||
                activeSubView == BelongHomeSubView.comingSoonItem ||
                activeSubView == BelongHomeSubView.membersDirectory,
            onTap: onSelectSpaces,
            primaryColor: primaryColor,
            isContrast: isContrast,
          ),
        ],
      ),
    );
  }
}

class _SubHeaderTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isContrast;

  const _SubHeaderTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.isContrast,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSelected
        ? (isContrast ? Colors.black : primaryColor)
        : (isContrast ? Colors.white : Colors.grey.shade700);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
