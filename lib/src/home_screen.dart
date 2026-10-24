import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/firebase/community_analytics_service.dart';
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
import 'features/sensory_themes/domain/sensory_theme_model.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'features/settings/presentation/simple_auth_screen.dart';

enum BelongBottomTab { home, notifications, msgs, search }

enum BelongHomeSubView { feed, spaces, membersDirectory, comingSoonItem }

class RefugeHomeScreen extends HookConsumerWidget {
  const RefugeHomeScreen({super.key});

  static String _sensoryThemeLabel(SensoryMode mode) => switch (mode) {
    SensoryMode.clean => 'Clean',
    SensoryMode.sage => 'Sage',
    SensoryMode.charcoal => 'Dark',
    SensoryMode.contrast => 'Contrast',
  };

  PopupMenuItem<SensoryMode> _sensoryThemeMenuItem({
    required SensoryMode mode,
    required String emoji,
    required String label,
  }) {
    return PopupMenuItem<SensoryMode>(
      value: mode,
      child: Semantics(
        identifier: 'sensory_theme_option_${mode.name}',
        label: '$label theme',
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(sensoryThemeModeProvider);
    final themeNotifier = ref.read(sensoryThemeProvider.notifier);
    final brand = ref.watch(brandConfigProvider);
    final remoteConfig = ref.watch(organizerRemoteConfigServiceProvider);
    final analytics = ref.watch(communityAnalyticsServiceProvider);

    final isContrast = currentMode == SensoryMode.contrast;
    final primaryColor = isContrast
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    final activeBottomTab = useState<BelongBottomTab>(BelongBottomTab.home);
    final homeSubView = useState<BelongHomeSubView>(BelongHomeSubView.feed);
    final activeComingSoonItem = useState<FellowshipSpaceItem?>(null);
    final activeFilter = useState<String>('All');
    final activeSort = useState<FeedSortOption>(FeedSortOption.recent);

    final selectedSpace = useState<String>('general');
    final profile = ref.watch(memberProfileProvider);

    final easterEggTapCount = useState<int>(0);
    final easterEggLastTap = useState<DateTime?>(null);

    final serverpodRepo = ref.watch(serverpodPostRepositoryProvider);
    final activeRepository = ref.watch(postRepositoryProvider);

    final isLiveServerpod = activeRepository.runtimeType.toString().contains(
      'ServerpodPostRepository',
    );

    final postsSnapshot = useStream(
      useMemoized(
        () => activeRepository.watchPosts(
          spaceSlug: selectedSpace.value,
          sortOption: activeSort.value,
        ),
        [activeRepository, selectedSpace.value, activeSort.value],
      ),
    );

    final quietDigestSnapshot = useStream(
      useMemoized(
        () => activeRepository.watchQuietDigest(spaceSlug: selectedSpace.value),
        [activeRepository, selectedSpace.value],
      ),
    );

    void setSensoryMode(SensoryMode mode) {
      if (themeNotifier != null) {
        themeNotifier!.setMode(mode);
      } else {
        ref.read(sensoryThemeModeProvider.notifier).state = mode;
      }
    }

    void selectSpace(String slug) {
      selectedSpace.value = slug;
      homeSubView.value = BelongHomeSubView.feed;
      analytics.logSpaceViewed(slug);
    }

    Future<void> submitPost({
      required String content,
      String? toneTag,
      String? imageUrl,
    }) async {
      await activeRepository.addPost(
        Post(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          spaceSlug: selectedSpace.value,
          authorName: profile.isSignedIn ? profile.displayName : 'Anonymous',
          authorAvatarUrl: profile.avatarUrl,
          authorMonogram: profile.initials,
          authorRole: profile.isSignedIn
              ? (profile.role.isNotEmpty ? profile.role : 'Member')
              : null,
          content: content,
          toneTag: toneTag,
          imageUrl: imageUrl,
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

                    final userInterests = {
                      ...profile.comfortBadges,
                      if (profile.bio.isNotEmpty)
                        ...profile.bio.split(RegExp(r'[\s,.]+')),
                      if (profile.tagline != null)
                        ...profile.tagline!.split(RegExp(r'[\s,.]+')),
                    };

                    final sortedPosts = FeedSortService.sortPosts(
                      filteredPosts,
                      activeSort.value,
                      userInterests: userInterests,
                    );

                    final posts = sortedPosts;

                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          'No reflections found in ${selectedSpace.value}.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
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
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: brand.appName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const TextSpan(
                              text: ' preview',
                              style: TextStyle(
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
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  key: const Key('menu_item_create_text_post'),
                  value: 'create_text_post',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
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
                              'Share a calming visual, photo, or art',
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
              onSelected: (action) {
                if (action == 'create_image_post') {
                  _showCreatePostModal(
                    context: context,
                    selectedSpace: selectedSpace.value,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                    isImagePost: true,
                    onSubmit: submitPost,
                  );
                } else if (action == 'create_text_post') {
                  _showCreatePostModal(
                    context: context,
                    selectedSpace: selectedSpace.value,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                    isImagePost: false,
                    onSubmit: submitPost,
                  );
                }
              },
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
                        ? (_, _) {}
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
              final bytes =
                  await captureRepaintBoundary(rootFeedbackRepaintBoundaryKey);
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
                final bytes =
                    await captureRepaintBoundary(rootFeedbackRepaintBoundaryKey);
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
    String? toneTag,
    String? imageUrl,
  })
  onSubmit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SystemBottomInset(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ReflectionComposerModal(
          selectedSpace: selectedSpace,
          primaryColor: primaryColor,
          isContrast: isContrast,
          isImagePost: isImagePost,
          onSubmit: onSubmit,
        ),
      ),
    ),
  );
}

Widget _webSemanticsTarget({
  required String label,
  required String identifier,
  required bool selected,
  required VoidCallback onTap,
  required Widget child,
}) {
  if (!kIsWeb) return child;
  return Semantics(
    label: label,
    identifier: identifier,
    selected: selected,
    button: true,
    container: true,
    excludeSemantics: true,
    onTap: onTap,
    child: child,
  );
}
