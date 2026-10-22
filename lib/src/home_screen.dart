import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/firebase/community_analytics_service.dart';
import 'core/firebase/organizer_remote_config_service.dart';
import 'core/presentation/coming_soon_view.dart';
import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/auth/presentation/belong_auth_sheet.dart';
import 'features/auth/presentation/simple_auth.dart';
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
import 'features/reflections/presentation/tone_filter_row.dart';
import 'features/search/presentation/community_search_view.dart';
import 'features/sensory_themes/domain/sensory_font_scale.dart';
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
    final easterEggTapCount = useState<int>(0);
    final easterEggLastTap = useState<DateTime?>(null);

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
            : isMobileAppLink
            ? 'Tip: You can add Belong directly to your phone Home Screen right now via Safari ("Add to Home Screen") or Chrome ("Install App") with zero App Store wait!'
            : null;
        return ComingSoonView(
          title: item.title,
          emoji: item.emoji,
          description: item.subtitle,
          trackedIssueNumber: item.trackedIssueNumber,
          extraMarkdownOrNote: extraNote,
          showPwaInstallGuide: isMobileAppLink,
          onBackToFeed: () => homeSubView.value = BelongHomeSubView.feed,
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompactHeight = constraints.maxHeight < 520;
          return Column(
            children: [\n              if (!isCompactHeight)\n                CommunityAnchorBanner(\n                  primaryColor: primaryColor,\n                  isContrast: isContrast,\n                ),\n              if (!profile.isSignedIn)\n                Container(\n                  key: const Key('demo_mode_banner'),\n                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),\n                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),\n                  decoration: BoxDecoration(\n                    color: isContrast\n                        ? Colors.black\n                        : primaryColor.withValues(alpha: 0.08),\n                    borderRadius: BorderRadius.circular(8),\n                    border: Border.all(\n                      color: isContrast\n                          ? Colors.white\n                          : primaryColor.withValues(alpha: 0.25),\n                    ),\n                  ),\n                  child: const Row(\n                    children: [\n                      Text('🎭', style: TextStyle(fontSize: 14)),\n                      SizedBox(width: 8),\n                      Expanded(\n                        child: Text(\n                          'Demo Mode · Sample reflections shown. Sign in to view and share live community reflections.',\n                          style: TextStyle(\n                            fontSize: 11.5,\n                            fontWeight: FontWeight.w500,\n                          ),\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              SpaceNavigationBar(\n                selectedSpace: selectedSpace.value,\n                onSelectSpace: selectSpace,\n              ),\n              if (!isCompactHeight)\n                QuietDigestBanner(\n                  primaryColor: primaryColor,\n                  isContrast: isContrast,\n                  legacyMessage: quietDigestSnapshot.data,\n                ),\n              ReflectionComposer(\n                selectedSpace: selectedSpace.value,\n                primaryColor: primaryColor,\n                isContrast: isContrast,\n                onSubmit: submitPost,\n              ),\n              ToneFilterRow(\n                activeFilter: activeFilter.value,\n                onSelectFilter: (f) => activeFilter.value = f,\n              ),\n              FeedSortRow(\n                activeSort: activeSort.value,\n                isContrast: isContrast,\n                onSelectSort: (s) {\n                  activeSort.value = s;\n                  ref.read(feedSortOptionProvider.notifier).state = s;\n                  analytics.logEvent(\n                    'feed_sort_changed',\n                    parameters: {'sort': s.name},\n                  );\n                },\n              ),\n              Expanded(\n                child: StreamBuilder<List<Post>>(\n                  stream: postStream,\n                  builder: (context, snapshot) {\n                    if (!snapshot.hasData) {\n                      return const Center(\n                        child: CircularProgressIndicator.adaptive(),\n                      );\n                    }\n\n                    final allPosts = snapshot.data!;\n                    final availablePosts = profile.isSignedIn\n                        ? allPosts.where((p) => !p.isDemo).toList()\n                        : allPosts;\n                    final filteredPosts = activeFilter.value == 'All'\n                        ? availablePosts\n                        : availablePosts\n                            .where((p) => p.toneTag == activeFilter.value)\n                            .toList();\n\n                    final userInterests = {\n                      ...profile.comfortBadges,\n                      if (profile.bio.isNotEmpty)\n                        ...profile.bio.split(RegExp(r'[\\s,.]+')),\n                      if (profile.tagline != null)\n                        ...profile.tagline!.split(RegExp(r'[\\s,.]+')),\n                    };\n\n                    final posts = FeedSortService.sortPosts(\n                      filteredPosts,\n                      sortOption: activeSort.value,\n                      latestActivityByPost: activityTimestampsAsync.value,\n                      commentCounts: commentCountsAsync.value,\n                      userInterests: userInterests,\n                    );\n\n                    if (posts.isEmpty) {\n                      if (selectedSpace.value == 'saved_for_later') {\n                        return Center(\n                          child: Padding(\n                            padding: const EdgeInsets.symmetric(horizontal: 24.0),\n                            child: Column(\n                              mainAxisSize: MainAxisSize.min,\n                              children: [\n                                const Icon(\n                                  Icons.bookmark_border_rounded,\n                                  size: 40,\n                                  color: Colors.grey,\n                                ),\n                                const SizedBox(height: 8),\n                                Text(\n                                  'No saved reflections yet.\\nTap the bookmark ribbon (🔖) on any reflection to save it for quiet, unhurried reading later.',\n                                  key: const Key('empty_saved_reflections_placeholder'),\n                                  textAlign: TextAlign.center,\n                                  style: TextStyle(\n                                    fontSize: 12,\n                                    color: Theme.of(context)\n                                        .textTheme\n                                        .bodySmall\n                                        ?.color\n                                        ?.withValues(alpha: 0.7),\n                                  ),\n                                ),\n                              ],\n                            ),\n                          ),\n                        );\n                      }\n                      return Center(\n                        child: Text(\n                          profile.isSignedIn\n                              ? 'No community reflections yet in this space.'\n                              : 'Space is quiet right now.\\nBe the first to share an unhurried thought.',\n                          key: const Key('empty_reflections_placeholder'),\n                          textAlign: TextAlign.center,\n                          style: TextStyle(\n                            fontSize: 12,\n                            color: Theme.of(context).textTheme.bodySmall?.color\n                                ?.withValues(alpha: 0.6),\n                          ),\n                        ),\n                      );\n                    }\n\n                    return ListView.builder(\n                      itemCount: posts.length,\n                      padding: const EdgeInsets.only(\n                        left: 12.0,\n                        right: 12.0,\n                        top: 8.0,\n                        bottom: 48.0,\n                      ),\n                      itemBuilder: (context, index) {\n                        final p = posts[index];\n                        return ReflectionCard(\n                          post: p,\n                          isContrast: isContrast,\n                          onAddReaction: (reactionType) =>\n                              activeRepository.addReaction(\n                                postId: p.id,\n                                reactionType: reactionType,\n                              ),\n                        );\n                      },\n                    );\n                  },\n                ),\n              ),\n            ],\n          );\n        },\n      );\n    }\n\n    Widget buildActiveBottomTabBody() {\n      switch (activeBottomTab.value) {\n        case BelongBottomTab.home:\n          return Column(\n            children: [\n              _BelongSubHeaderBar(\n                activeSubView: homeSubView.value,\n                onSelectFeed: () => homeSubView.value = BelongHomeSubView.feed,\n                onSelectSpaces: () =>\n                    homeSubView.value = BelongHomeSubView.spaces,\n                primaryColor: primaryColor,\n                isContrast: isContrast,\n              ),\n              Expanded(child: buildHomeBody()),\n            ],\n          );\n        case BelongBottomTab.notifications:\n          return CalmNotificationsView(\n            onBackToHome: () => activeBottomTab.value = BelongBottomTab.home,\n          );\n        case BelongBottomTab.msgs:\n          return const BelongMessagesView();\n        case BelongBottomTab.search:\n          return CommunitySearchView(\n            repository: activeRepository,\n            isContrast: isContrast,\n          );\n      }\n    }\n\n    return Scaffold(\n      appBar: AppBar(\n        elevation: 0.5,\n        title: InkWell(\n          key: const Key('belong_app_bar_title_tap_target'),\n          borderRadius: BorderRadius.circular(8),\n          onTap: () {\n            final now = DateTime.now();\n            if (easterEggLastTap.value == null ||\n                now.difference(easterEggLastTap.value!).inSeconds > 4) {\n              easterEggTapCount.value = 1;\n            } else {\n              easterEggTapCount.value++;\n            }\n            easterEggLastTap.value = now;\n\n            if (easterEggTapCount.value >= 7) {\n              easterEggTapCount.value = 0;\n              ObservabilityEasterEggDialog.show(context);\n            }\n          },\n          child: Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),\n            child: Row(\n              mainAxisSize: MainAxisSize.min,\n              children: [\n                ClipRRect(\n                  borderRadius: BorderRadius.circular(6),\n                  child: Image.asset(\n                    brand.logoAssetPath,\n                    key: const Key('belong_header_logo'),\n                    width: 28,\n                    height: 28,\n                    errorBuilder: (_, _, _) =>\n                        const Text('♾️', style: TextStyle(fontSize: 18)),\n                  ),\n                ),\n                const SizedBox(width: 8),\n                Flexible(\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.start,\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          Text(\n                            brand.shortName,\n                            style: const TextStyle(\n                              fontSize: 15,\n                              fontWeight: FontWeight.bold,\n                            ),\n                          ),\n                          const SizedBox(width: 6),\n                          const Text(\n                            'Refuge',\n                            style: TextStyle(\n                              fontSize: 12,\n                              fontWeight: FontWeight.w500,\n                            ),\n                          ),\n                        ],\n                      ),\n                      Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          Container(\n                            width: 7,\n                            height: 7,\n                            decoration: BoxDecoration,\n                              shape: BoxShape.circle,\n                              color: isLiveServerpod\n                                  ? const Color(0xFF4CAF50)\n                                  : const Color(0xFF68A67D),\n                            ),\n                          ),\n                          const SizedBox(width: 5),\n                          Flexible(\n                            child: Text(\n                              'Calm Tech • ${isLiveServerpod ? \"Live\" : \"Resilient\"}',\n                              overflow: TextOverflow.ellipsis,\n                              style: TextStyle(\n                                fontSize: 11,\n                                color: Theme.of(context)\n                                    .textTheme\n                                    .bodySmall\n                                    ?.color\n                                    ?.withValues(alpha: 0.7),\n                              ),\n                            ),\n                          ),\n                        ],\n                      ),\n                    ],\n                  ),\n                ),\n              ],\n            ),\n          ),\n        ),\n        actions: [\n          IconButton(\n            key: const Key('home_high_contrast_toggle_button'),\n            tooltip: isContrast\n                ? 'Switch to Sage Theme'\n                : 'Switch to High Contrast',\n            icon: Icon(\n              isContrast ? Icons.contrast_rounded : Icons.circle_outlined,\n              color: isContrast ? Colors.yellow : null,\n              size: 20,\n            ),\n            onPressed: () {\n              if (themeNotifier != null) {\n                themeNotifier!.toggleHighContrast();\n              } else {\n                ref.read(sensoryThemeModeProvider.notifier).toggleHighContrast();\n              }\n            },\n          ),\n          PopupMenuButton<SensoryMode>(\n            tooltip: 'Sensory Themes',\n            icon: const Icon(Icons.brightness_6_rounded, size: 20),\n            onSelected: setSensoryMode,\n            itemBuilder: (context) => const [\n              PopupMenuItem(\n                value: SensoryMode.clean,\n                child: Row(\n                  children: [\n                    Text('☀️', style: TextStyle(fontSize: 14)),\n                    SizedBox(width: 8),\n                    Text('Clean'),\n                  ],\n                ),\n              ),\n              PopupMenuItem(\n                value: SensoryMode.sage,\n                child: Row(\n                  children: [\n                    Text('🌿', style: TextStyle(fontSize: 14)),\n                    SizedBox(width: 8),\n                    Text('Sage'),\n                  ],\n                ),\n              ),\n              PopupMenuItem(\n                value: SensoryMode.charcoal,\n                child: Row(\n                  children: [\n                    Text('🌙', style: TextStyle(fontSize: 14)),\n                    SizedBox(width: 8),\n                    Text('Dark'),\n                  ],\n                ),\n              ),\n              PopupMenuItem(\n                value: SensoryMode.contrast,\n                child: Row(\n                  children: [\n                    Text('👁️', style: TextStyle(fontSize: 14)),\n                    SizedBox(width: 8),\n                    Text('Contrast'),\n                  ],\n                ),\n              ),\n            ],\n          ),\n          IconButton(\n            tooltip: 'About Belong',\n            icon: const Icon(Icons.info_outline_rounded, size: 18),\n            visualDensity: VisualDensity.compact,\n            onPressed: () => showAboutRefugeDialog(\n              context,\n              primaryColor: primaryColor,\n              isContrast: isContrast,\n              currentMode: currentMode,\n              onSelectMode: setSensoryMode,\n            ),\n          ),\n          Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 2.0),\n            child: PopupMenuButton<String>(\n              key: const Key('home_top_bar_create_post_button'),\n              tooltip: 'Create post or image post (+)',\n              offset: const Offset(0, 40),\n              shape: RoundedRectangleBorder(\n                borderRadius: BorderRadius.circular(14),\n                side: BorderSide(\n                  color: isContrast ? Colors.white : Theme.of(context).dividerColor,\n                ),\n              ),\n              onSelected: (action) {\n                if (action == 'create_post') {\n                  _showCreatePostModal(\n                    context: context,\n                    selectedSpace: selectedSpace.value,\n                    primaryColor: primaryColor,\n                    isContrast: isContrast,\n                    isImagePost: false,\n                    onSubmit: submitPost,\n                  );\n                } else if (action == 'create_image_post') {\n                  _showCreatePostModal(\n                    context: context,\n                    selectedSpace: selectedSpace.value,\n                    primaryColor: primaryColor,\n                    isContrast: isContrast,\n                    isImagePost: true,\n                    onSubmit: submitPost,\n                  );\n                }\n              },\n              itemBuilder: (context) => [\n                PopupMenuItem<String>(\n                  key: const Key('menu_item_create_post'),\n                  value: 'create_post',\n                  child: Row(\n                    children: [\n                      Container(\n                        padding: const EdgeInsets.all(6),\n                        decoration: BoxDecoration(\n                          color: primaryColor.withValues(alpha: 0.15),\n                          borderRadius: BorderRadius.circular(8),\n                        ),\n                        child: Icon(\n                          Icons.edit_note_rounded,\n                          color: primaryColor,\n                          size: 18,\n                        ),\n                      ),\n                      const SizedBox(width: 12),\n                      Expanded(\n                        child: Column(\n                          crossAxisAlignment: CrossAxisAlignment.start,\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            const Text(\n                              'Create Post',\n                              style: TextStyle(\n                                fontSize: 13,\n                                fontWeight: FontWeight.bold,\n                              ),\n                            ),\n                            Text(\n                              'Share an unhurried thought or prayer',\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: TextStyle(\n                                fontSize: 10,\n                                color: Theme.of(context).textTheme.bodySmall?.color,\n                              ),\n                            ),\n                          ],\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n                const PopupMenuDivider(),\n                PopupMenuItem<String>(\n                  key: const Key('menu_item_create_image_post'),\n                  value: 'create_image_post',\n                  child: Row(\n                    children: [\n                      Container(\n                        padding: const EdgeInsets.all(6),\n                        decoration: BoxDecoration(\n                          color: Colors.amber.withValues(alpha: 0.2),\n                          borderRadius: BorderRadius.circular(8),\n                        ),\n                        child: const Icon(\n                          Icons.image_outlined,\n                          color: Colors.amber,\n                          size: 18,\n                        ),\n                      ),\n                      const SizedBox(width: 12),\n                      Expanded(\n                        child: Column(\n                          crossAxisAlignment: CrossAxisAlignment.start,\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            const Text(\n                              'Create Image Post',\n                              style: TextStyle(\n                                fontSize: 13,\n                                fontWeight: FontWeight.bold,\n                              ),\n                            ),\n                            Text(\n                              'Share a meme, photo, or scripture art',\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: TextStyle(\n                                fontSize: 10,\n                                color: Theme.of(context).textTheme.bodySmall?.color,\n                              ),\n                            ),\n                          ],\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              ],\n              child: Container(\n                padding: const EdgeInsets.all(6),\n                decoration: BoxDecoration(\n                  color: Theme.of(context).colorScheme.secondaryContainer,\n                  shape: BoxShape.circle,\n                ),\n                child: Icon(\n                  Icons.add_rounded,\n                  size: 20,\n                  color: Theme.of(context).colorScheme.onSecondaryContainer,\n                ),\n              ),\n            ),\n          ),\n          if (!profile.isSignedIn)\n            Padding(\n              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),\n              child: FilledButton.tonalIcon(\n                key: const Key('home_top_bar_sign_in_button'),\n                style: FilledButton.styleFrom(\n                  padding: const EdgeInsets.symmetric(\n                    horizontal: 10,\n                    vertical: 0,\n                  ),\n                  visualDensity: VisualDensity.compact,\n                ),\n                onPressed: () => SimpleAuthScreen.show(context),\n                icon: const Icon(Icons.login_rounded, size: 15),\n                label: const Text(\n                  'Sign In',\n                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),\n                ),\n              ),\n            )\n          else\n            Padding(\n              padding: const EdgeInsets.only(right: 8),\n              child: InkWell(\n                key: const Key('belong_profile_avatar_button'),\n                borderRadius: BorderRadius.circular(999),\n                onTap: () => MemberProfileDialog.show(context),\n                child: Tooltip(\n                  message: 'Member Profile (${profile.displayName})',\n                  child: CircleAvatar(\n                    radius: 14,\n                    backgroundColor: isContrast\n                        ? Colors.yellow\n                        : primaryColor.withValues(alpha: 0.2),\n                    child: Text(\n                      profile.initials,\n                      style: TextStyle(\n                        fontSize: 11,\n                        fontWeight: FontWeight.bold,\n                        color: isContrast ? Colors.black : primaryColor,\n                      ),\n                    ),\n                  ),\n                ),\n              ),\n            ),\n        ],\n      ),\n      body: SafeArea(\n        top: false,\n        bottom: true,\n        left: true,\n        right: true,\n        child: Center(\n          child: ConstrainedBox(\n            constraints: const BoxConstraints(maxWidth: 820),\n            child: buildActiveBottomTabBody(),\n          ),\n        ),\n      ),\n      bottomNavigationBar: BelongBottomNavBar(\n        currentTab: activeBottomTab.value,\n        isContrast: isContrast,\n        onSelectTab: (tab) {\n          activeBottomTab.value = tab;\n          analytics.logBottomTabSelected(tab.name);\n        },\n      ),\n    );\n  }\n}\n\n/// Backward-compatible alias for SanctuaryHomeScreen.\ntypedef SanctuaryHomeScreen = RefugeHomeScreen;\n\nclass _BelongSubHeaderBar extends StatelessWidget {\n  const _BelongSubHeaderBar({\n    required this.activeSubView,\n    required this.onSelectFeed,\n    required this.onSelectSpaces,\n    required this.primaryColor,\n    required this.isContrast,\n  });\n\n  final BelongHomeSubView activeSubView;\n  final VoidCallback onSelectFeed;\n  final VoidCallback onSelectSpaces;\n  final Color primaryColor;\n  final bool isContrast;\n\n  @override\n  Widget build(BuildContext context) {\n    final isFeed = activeSubView == BelongHomeSubView.feed;\n    final isSpaces = activeSubView == BelongHomeSubView.spaces;\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),\n      child: Row(\n        children: [\n          ChoiceChip(\n            key: const Key('subnav_feed_tab'),\n            label: const Text('Feed'),\n            selected: isFeed,\n            onSelected: (_) => onSelectFeed(),\n          ),\n          const SizedBox(width: 8),\n          ChoiceChip(\n            key: const Key('subnav_spaces_tab'),\n            label: const Text('Spaces'),\n            selected: isSpaces,\n            onSelected: (_) => onSelectSpaces(),\n          ),\n          const Spacer(),\n          ActionChip(\n            key: const Key('open_feedback_and_voting_button'),\n            avatar: const Icon(Icons.how_to_vote_outlined, size: 16),\n            label: const Text('Vote & Feedback'),\n            onPressed: () => BelongFeedbackAndVotingSheet.show(context),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nvoid _showCreatePostModal({\n  required BuildContext context,\n  required String selectedSpace,\n  required Color primaryColor,\n  required bool isContrast,\n  bool isImagePost = false,\n  required Future<void> Function({\n    required String content,\n    required String toneTag,\n    String? specialInterestTag,\n    String? imageUrl,\n  })\n  onSubmit,\n}) {\n  showModalBottomSheet<void>(\n    context: context,\n    isScrollControlled: true,\n    backgroundColor: Theme.of(context).scaffoldBackgroundColor,\n    shape: const RoundedRectangleBorder(\n      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),\n    ),\n    builder: (ctx) {\n      return Padding(\n        padding: EdgeInsets.only(\n          bottom: MediaQuery.of(ctx).viewInsets.bottom,\n        ),\n        child: SafeArea(\n          child: SingleChildScrollView(\n            child: Column(\n              mainAxisSize: MainAxisSize.min,\n              crossAxisAlignment: CrossAxisAlignment.stretch,\n              children: [\n                Padding(\n                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),\n                  child: Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      Row(\n                        children: [\n                          Icon(\n                            isImagePost ? Icons.image_outlined : Icons.post_add_rounded,\n                            size: 20,\n                            color: primaryColor,\n                          ),\n                          const SizedBox(width: 8),\n                          Text(\n                            isImagePost ? 'Create Image Post' : 'Create Reflection Post',\n                            style: const TextStyle(\n                              fontSize: 15,\n                              fontWeight: FontWeight.bold,\n                            ),\n                          ),\n                        ],\n                      ),\n                      IconButton(\n                        visualDensity: VisualDensity.compact,\n                        icon: const Icon(Icons.close_rounded, size: 20),\n                        onPressed: () => Navigator.of(ctx).pop(),\n                      ),\n                    ],\n                  ),\n                ),\n                ReflectionComposer(\n                  selectedSpace: selectedSpace,\n                  primaryColor: primaryColor,\n                  isContrast: isContrast,\n                  isImagePost: isImagePost,\n                  onSubmit: ({\n                    required String content,\n                    required String toneTag,\n                    String? specialInterestTag,\n                    String? imageUrl,\n                  }) async {\n                    await onSubmit(\n                      content: content,\n                      toneTag: toneTag,\n                      specialInterestTag: specialInterestTag,\n                      imageUrl: imageUrl,\n                    );\n                    if (ctx.mounted) {\n                      Navigator.of(ctx).pop();\n                    }\n                  },\n                ),\n                const SizedBox(height: 12),\n              ],\n            ),\n          ),\n        ),\n      );\n    },\n  );\n}
