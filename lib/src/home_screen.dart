import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/firebase/community_analytics_service.dart';
import 'core/theme/belong_text_styles.dart';
import 'core/firebase/organizer_remote_config_service.dart';
import 'core/presentation/coming_soon_view.dart';
import 'core/presentation/system_insets.dart';
import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/auth/presentation/simple_auth.dart';
import 'features/branding/presentation/brand_config_provider.dart';
import 'features/events/presentation/actually_autistic_events_view.dart';
import 'features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'features/feedback/presentation/feedback_drawing_canvas.dart';
import 'features/fellowship_spaces/domain/fellowship_space.dart';
import 'features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'features/messages/presentation/belong_messages_view.dart';
import 'features/messages/presentation/calm_notifications_view.dart';
import 'features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'features/notifications/domain/notification_navigation_target.dart';
import 'features/notifications/presentation/notifications_controller.dart';
import 'features/observability/presentation/observability_easter_egg_dialog.dart';
import 'features/profile/domain/member_profile.dart';
import 'features/profile/presentation/belong_members_directory_view.dart';
import 'features/profile/presentation/member_profile_sheet.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/reflections/data/serverpod_post_repository.dart';
import 'features/reflections/domain/feed_sort_option.dart';
import 'features/reflections/domain/feed_sort_service.dart';
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/feed_sort_row.dart';
import 'features/reflections/presentation/quiet_digest_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
import 'features/reflections/presentation/reflections_providers.dart';
import 'features/reflections/presentation/space_navigation_bar.dart';
import 'features/reflections/presentation/threaded_discussion_sheet.dart';
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
    if (themeNotifier != null) {
      useListenable(themeNotifier!);
    }
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
    final analytics = ref.watch(communityAnalyticsServiceProvider);

    final selectedSpace = useState<String>('prayer');
    final activeFilter = useState<String>('All');
    final activeSort = useState<FeedSortOption>(FeedSortOption.latest);
    final activityTimestampsAsync = ref.watch(postActivityTimestampsProvider);
    final commentCountsAsync = ref.watch(allCommentCountsProvider);
    final activeBottomTab = useState<BelongBottomTab>(BelongBottomTab.home);
    final homeSubView = useState<BelongHomeSubView>(BelongHomeSubView.feed);
    final activeComingSoonItem = useState<BelongSpaceItem?>(null);
    final activeDirectMessageThreadId = useState<String?>(null);
    final highlightedPostId = useState<String?>(null);
    final easterEggTapCount = useState<int>(0);
    final easterEggLastTap = useState<DateTime?>(null);

    // Deep-link navigation handler for in-app or push notifications (#330)
    ref.listen<NotificationNavigationTarget?>(
      notificationNavigationTargetProvider,
      (_, target) {
        if (target != null) {
          activeBottomTab.value = target.tab;
          if (target.spaceKey != null) {
            selectedSpace.value = target.spaceKey!;
            homeSubView.value = BelongHomeSubView.feed;
          }
          if (target.conversationId != null) {
            activeDirectMessageThreadId.value = target.conversationId;
          }
          if (target.postId != null) {
            highlightedPostId.value = target.postId;
          }
          ref.read(notificationNavigationTargetProvider.notifier).state = null;
        }
      },
    );

    final PostRepository activeRepository =
        repository ?? ref.watch(postRepositoryProvider);

    final postStream = useMemoized(
      () => selectedSpace.value == 'saved_for_later'
          ? activeRepository.watchSavedPosts().asBroadcastStream()
          : activeRepository
                .watchPosts(spaceKey: selectedSpace.value)
                .asBroadcastStream(),
      [activeRepository, selectedSpace.value],
    );
    // Subscribe at the screen level (not inside the feed sub-view) so the
    // subscription and its latest snapshot survive switching to Spaces /
    // other bottom tabs and back. A broadcast stream does not replay its last
    // event to a fresh listener, so re-subscribing via a StreamBuilder that
    // was unmounted left the feed stuck on a spinner / grey screen (#402).
    final postsSnapshot = useStream(postStream, preserveState: false);
    final quietDigestFuture = useMemoized(
      () => activeRepository.getQuietDigest(spaceKey: selectedSpace.value),
      [activeRepository, selectedSpace.value],
    );
    final quietDigestSnapshot = useFuture(quietDigestFuture);

    final SensoryMode currentMode =
        themeNotifier?.mode ?? ref.watch(sensoryThemeModeProvider);
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
      if (selectedSpace.value == 'saved_for_later') {
        // Saved for later is a private bookmarks sanctuary; public reflections cannot be posted here.
        return;
      }
      final targetSpace = selectedSpace.value;
      await activeRepository.createPost(
        Post(
          id: 'post-${DateTime.now().millisecondsSinceEpoch}',
          authorName: profile.displayName,
          content: content,
          timestamp: DateTime.now(),
          spaceKey: targetSpace,
          reactions: {},
          toneTag: toneTag,
          specialInterestTag: specialInterestTag,
          imageUrl: imageUrl,
        ),
      );
      final lengthBucket = content.length <= 140
          ? 1
          : content.length <= 280
          ? 2
          : 3;
      analytics.logReflectionPublished(tag: toneTag, lengthBucket: lengthBucket);
    }

    Widget buildHomeBody() {
      if (homeSubView.value == BelongHomeSubView.membersDirectory) {
        return BelongMembersDirectoryView(
          onBackToSpaces: () =>
              homeSubView.value = BelongHomeSubView.spaces,
        );
      }

      if (homeSubView.value == BelongHomeSubView.spaces) {
        return BelongSpacesDirectoryView(
          selectedSpaceSlug: selectedSpace.value,
          onSelectSpaceItem: (item) {
            if (item.isComingSoon) {
              activeComingSoonItem.value = item;
              homeSubView.value = BelongHomeSubView.comingSoonItem;
              return;
            }
            if (item.slug == 'members_directory') {
              homeSubView.value = BelongHomeSubView.membersDirectory;
              return;
            }
            selectSpace(item.slug);
          },
        );
      }

      if (homeSubView.value == BelongHomeSubView.comingSoonItem &&
          activeComingSoonItem.value != null) {
        final item = activeComingSoonItem.value!;
        return ComingSoonView(
          title: item.title,
          emoji: item.emoji,
          description: item.subtitle,
          trackedIssueNumber: item.trackedIssueNumber,
          onBackToFeed: () => homeSubView.value = BelongHomeSubView.spaces,
        );
      }

      // Default: Feed View
      return LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return Column(
            children: [
              SpaceNavigationBar(
                selectedSpace: selectedSpace.value,
                onSelectSpace: selectSpace,
              ),
              ToneFilterRow(
                activeFilter: activeFilter.value,
                onSelectFilter: (tone) {
                  activeFilter.value = tone;
                },
              ),
              FeedSortRow(
                activeSort: activeSort.value,
                onSelectSort: (sort) {
                  activeSort.value = sort;
                },
                isContrast: isContrast,
              ),
              if (selectedSpace.value == 'saved_for_later')
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 4.0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.black
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isContrast
                          ? Colors.yellow
                          : primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_added_rounded,
                        size: 16,
                        color: isContrast ? Colors.yellow : primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your private bookmarks sanctuary. Only you can see reflections saved here.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isContrast
                                ? Colors.white
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (remoteConfig.bannerEnabled)
                CommunityAnchorBanner(
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                ),
              if (quietDigestSnapshot.hasData &&
                  quietDigestSnapshot.data != null &&
                  quietDigestSnapshot.data!.isNotEmpty)
                QuietDigestBanner(
                  primaryColor: primaryColor,
                  legacyMessage: quietDigestSnapshot.data,
                  isContrast: isContrast,
                ),
              if (!isDesktop && selectedSpace.value != 'saved_for_later')
                ReflectionComposer(
                  selectedSpace: selectedSpace.value,
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                  onSubmit:
                      ({
                        required String content,
                        required String toneTag,
                        String? specialInterestTag,
                        String? imageUrl,
                      }) => submitPost(
                        content: content,
                        toneTag: toneTag,
                        specialInterestTag: specialInterestTag,
                        imageUrl: imageUrl,
                      ),
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (postsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading reflections: ${postsSnapshot.error}',
                        ),
                      );
                    }
                    if (!postsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var posts = postsSnapshot.data!;

                    // Apply Tone Filter
                    if (activeFilter.value != 'All') {
                      posts = posts
                          .where((p) => p.toneTag == activeFilter.value)
                          .toList();
                    }

                    // Apply Feed Sort
                    final activityTimestamps =
                        activityTimestampsAsync.value ?? {};
                    final commentCounts = commentCountsAsync.value ?? {};
                    posts = FeedSortService.sortPosts(
                      posts,
                      sortOption: activeSort.value,
                      latestActivityByPost: activityTimestamps,
                      commentCounts: commentCounts,
                    );

                    if (posts.isEmpty) {
                      if (selectedSpace.value == 'saved_for_later') {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 40,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved reflections yet.\nTap the bookmark icon on any reflection to save it for quiet contemplation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
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
                      itemCount: posts.length,
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 8.0,
                        bottom: 48.0,
                      ),
                      itemBuilder: (context, index) {
                        final p = posts[index];
                        return ReflectionCard(
                          post: p,
                          isContrast: isContrast,
                          isHighlighted: highlightedPostId.value == p.id,
                          onAddReaction: (reactionType) =>
                              activeRepository.addReaction(
                                postId: p.id,
                                reactionType: reactionType,
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
            onNavigate: (target) async {
              activeBottomTab.value = target.tab;
              if (target.spaceKey != null) {
                selectSpace(target.spaceKey!);
              }
              if (target.postId != null && target.openDiscussion) {
                final posts = await activeRepository
                    .watchPosts(
                      spaceKey: target.spaceKey ?? selectedSpace.value,
                    )
                    .first
                    .timeout(
                      const Duration(milliseconds: 600),
                      onTimeout: () => [],
                    );
                final post = posts.cast<Post?>().firstWhere(
                  (p) => p?.id == target.postId,
                  orElse: () => null,
                );
                if (context.mounted && post != null) {
                  ThreadedDiscussionSheet.show(context, post: post);
                }
              }
            },
          );
        case BelongBottomTab.msgs:
          return BelongMessagesView(
            initialActiveThreadId: activeDirectMessageThreadId.value,
          );
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
            if (easterEggLastTap.value == null ||
                now.difference(easterEggLastTap.value!).inSeconds > 4) {
              easterEggTapCount.value = 1;
            } else {
              easterEggTapCount.value++;
            }
            easterEggLastTap.value = now;

            if (easterEggTapCount.value >= 7) {
              easterEggTapCount.value = 0;
              ObservabilityEasterEggDialog.show(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    brand.logoAssetPath,
                    key: const Key('belong_header_logo'),
                    width: 28,
                    height: 28,
                    errorBuilder: (_, _, _) =>
                        const Text('♾️', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                brand.shortName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BelongTextStyles.of(context).emphasis
                                    .copyWith(fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Refuge',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BelongTextStyles.of(context).emphasis
                                  .copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLiveServerpod
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF68A67D),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Semantics(
                              identifier:
                                  'active_sensory_theme_${currentMode.name}',
                              label:
                                  'Active sensory theme ${_sensoryThemeLabel(currentMode)}',
                              container: true,
                              explicitChildNodes: true,
                              child: Text(
                                'Calm Tech • ${isLiveServerpod ? "Live" : "Resilient"}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const Key('home_high_contrast_toggle_button'),
            tooltip: isContrast
                ? 'Switch to Sage Theme'
                : 'Switch to High Contrast',
            icon: Icon(
              isContrast ? Icons.contrast_rounded : Icons.circle_outlined,
              color: isContrast ? Colors.yellow : null,
              size: 20,
            ),
            onPressed: () {
              if (themeNotifier != null) {
                themeNotifier!.toggleHighContrast();
              } else {
                ref
                    .read(sensoryThemeModeProvider.notifier)
                    .toggleHighContrast();
              }
            },
          ),
          Semantics(
            identifier: 'sensory_theme_toggle_button',
            child: PopupMenuButton<SensoryMode>(
              tooltip: 'Sensory Themes',
              icon: const Icon(Icons.brightness_6_rounded, size: 20),
              onSelected: setSensoryMode,
              itemBuilder: (context) => [
                _sensoryThemeMenuItem(
                  mode: SensoryMode.clean,
                  emoji: '☀️',
                  label: 'Clean',
                ),
                _sensoryThemeMenuItem(
                  mode: SensoryMode.sage,
                  emoji: '🌿',
                  label: 'Sage',
                ),
                _sensoryThemeMenuItem(
                  mode: SensoryMode.charcoal,
                  emoji: '🌙',
                  label: 'Dark',
                ),
                _sensoryThemeMenuItem(
                  mode: SensoryMode.contrast,
                  emoji: '👁️',
                  label: 'Contrast',
                ),
              ],
            ),
          ),
          Semantics(
            identifier: 'about_belong_info_button',
            child: IconButton(
              tooltip: 'About Belong',
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () => showAboutRefugeDialog(
                context,
                primaryColor: primaryColor,
                isContrast: isContrast,
                currentMode: currentMode,
                onSelectMode: setSensoryMode,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: PopupMenuButton<String>(
              key: const Key('home_top_bar_create_post_button'),
              tooltip: 'Create post or image post (+)',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isContrast
                      ? Colors.white
                      : Theme.of(context).dividerColor,
                ),
              ),
              onSelected: (action) {
                if (action == 'create_post') {
                  _showCreatePostModal(
                    context: context,
                    selectedSpace: selectedSpace.value == 'saved_for_later'
                        ? 'general_chat'
                        : selectedSpace.value,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                    isImagePost: false,
                    onSubmit: submitPost,
                  );
                } else if (action == 'create_image_post') {
                  _showCreatePostModal(
                    context: context,
                    selectedSpace: selectedSpace.value == 'saved_for_later'
                        ? 'general_chat'
                        : selectedSpace.value,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                    isImagePost: true,
                    onSubmit: submitPost,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  key: const Key('menu_item_create_post'),
                  value: 'create_post',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create Post',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Share an unhurried thought or prayer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  key: const Key('menu_item_create_image_post'),
                  value: 'create_image_post',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create Image Post',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Share a meme, photo, or scripture art',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
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
                onPressed: () => SimpleAuthScreen.show(context),
                icon: const Icon(Icons.login_rounded, size: 15),
                label: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
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
                        ? Colors.yellow
                        : primaryColor.withValues(alpha: 0.2),
                    backgroundImage:
                        (profile.avatarUrl != null &&
                            profile.avatarUrl!.isNotEmpty)
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    onBackgroundImageError:
                        (profile.avatarUrl != null &&
                            profile.avatarUrl!.isNotEmpty)
                        ? (_, __) {}
                        : null,
                    child:
                        (profile.avatarUrl == null ||
                            profile.avatarUrl!.isEmpty)
                        ? Text(
                            profile.initials,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isContrast ? Colors.black : primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RepaintBoundary(
        key: rootFeedbackRepaintBoundaryKey,
        child: SafeArea(
          top: false,
          bottom: true,
          left: true,
          right: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: buildActiveBottomTabBody(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BelongBottomNavBar(
        currentTab: activeBottomTab.value,
        isContrast: isContrast,
        onSelectTab: (tab) {
          activeBottomTab.value = tab;
          analytics.logBottomTabSelected(tab.name);
        },
      ),
    );
  }
}

/// Backward-compatible alias for SanctuaryHomeScreen.
typedef SanctuaryHomeScreen = RefugeHomeScreen;

class _BelongSubHeaderBar extends StatelessWidget {
  const _BelongSubHeaderBar({
    required this.activeSubView,
    required this.onSelectFeed,
    required this.onSelectSpaces,
    required this.primaryColor,
    required this.isContrast,
  });

  final BelongHomeSubView activeSubView;
  final VoidCallback onSelectFeed;
  final VoidCallback onSelectSpaces;
  final Color primaryColor;
  final bool isContrast;

  @override
  Widget build(BuildContext context) {
    final isFeed = activeSubView == BelongHomeSubView.feed;
    final isSpaces = activeSubView == BelongHomeSubView.spaces;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Row(
        children: [
          _webSemanticsTarget(
            label: 'Feed',
            identifier: 'feed_tab',
            selected: isFeed,
            onTap: onSelectFeed,
            child: ChoiceChip(
              key: const Key('subnav_feed_tab'),
              label: const Text('Feed'),
              selected: isFeed,
              onSelected: (_) => onSelectFeed(),
            ),
          ),
          const SizedBox(width: 8),
          _webSemanticsTarget(
            label: 'Spaces',
            identifier: 'spaces_tab',
            selected: isSpaces,
            onTap: onSelectSpaces,
            child: ChoiceChip(
              key: const Key('subnav_spaces_tab'),
              label: const Text('Spaces'),
              selected: isSpaces,
              onSelected: (_) => onSelectSpaces(),
            ),
          ),
          const Spacer(),
          _webSemanticsTarget(
            label: 'Vote & Feedback',
            identifier: 'vote_feedback_button',
            onTap: () async {
              final bytes = await captureRepaintBoundary(
                rootFeedbackRepaintBoundaryKey,
              );
              if (context.mounted) {
                BelongFeedbackAndVotingSheet.show(
                  context,
                  screenshotBytes: bytes,
                );
              }
            },
            child: ActionChip(
              key: const Key('open_feedback_and_voting_button'),
              avatar: const Icon(Icons.how_to_vote_outlined, size: 16),
              label: const Text('Vote & Feedback'),
              onPressed: () async {
                final bytes = await captureRepaintBoundary(
                  rootFeedbackRepaintBoundaryKey,
                );
                if (context.mounted) {
                  BelongFeedbackAndVotingSheet.show(
                    context,
                    screenshotBytes: bytes,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _showCreatePostModal({
  required BuildContext context,
  required String selectedSpace,
  required Color primaryColor,
  required bool isContrast,
  bool isImagePost = false,
  required Future<void> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
    String? imageUrl,
  })
  onSubmit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SystemBottomInset(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isImagePost
                                ? Icons.image_outlined
                                : Icons.post_add_rounded,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isImagePost
                                ? 'Create Image Post'
                                : 'Create Reflection Post',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                ReflectionComposer(
                  selectedSpace: selectedSpace,
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                  isImagePost: isImagePost,
                  isModal: true,
                  onSubmit:
                      ({
                        required String content,
                        required String toneTag,
                        String? specialInterestTag,
                        String? imageUrl,
                      }) async {
                        await onSubmit(
                          content: content,
                          toneTag: toneTag,
                          specialInterestTag: specialInterestTag,
                          imageUrl: imageUrl,
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Web Maestro reads semantics identifiers even when a chip's label text is
/// dropped from the accessibility tree. Mobile keeps the chip unchanged.
Widget _webSemanticsTarget({
  required String label,
  required String identifier,
  required VoidCallback onTap,
  bool selected = false,
  required Widget child,
}) {
  if (!kIsWeb) return child;
  return Semantics(
    label: label,
    identifier: identifier,
    button: true,
    selected: selected,
    container: true,
    excludeSemantics: true,
    onTap: onTap,
    child: child,
  );
}

/// Short accessible name for [mode]. Menu items and the calm-tech status
/// use the same words so Maestro can assert the theme that was just chosen.
String _sensoryThemeLabel(SensoryMode mode) => switch (mode) {
  SensoryMode.clean => 'Clean',
  SensoryMode.sage => 'Sage',
  SensoryMode.charcoal => 'Dark',
  SensoryMode.contrast => 'Contrast',
};

/// Popup rows whose accessible name is exactly [label].
///
/// The emoji is decorative. Leaving it in the semantics tree makes the
/// menuitem's name "🌙 Dark", which Maestro's full-string match will not
/// hit with `tapOn: "Dark"`. [PopupMenuItem] already exposes a tappable
/// menuitem; a tooltip on the row would only prepend another copy of the
/// same word.
PopupMenuItem<SensoryMode> _sensoryThemeMenuItem({
  required SensoryMode mode,
  required String emoji,
  required String label,
}) {
  return PopupMenuItem<SensoryMode>(
    value: mode,
    child: Semantics(
      identifier: 'sensory_theme_${mode.name}',
      label: label,
      button: true,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    ),
  );
}
