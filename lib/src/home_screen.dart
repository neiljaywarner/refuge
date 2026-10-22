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
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/quiet_digest_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
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
            children: [
              if (!isCompactHeight)
                CommunityAnchorBanner(
                  primaryColor: primaryColor,
                  isContrast: isContrast,
                ),
              if (!profile.isSignedIn)
                Container(
                  key: const Key('demo_mode_banner'),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Expanded(
                child: StreamBuilder<List<Post>>(
                  stream: postStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    final allPosts = snapshot.data!;
                    final availablePosts = profile.isSignedIn
                        ? allPosts.where((p) => !p.isDemo).toList()
                        : allPosts;
                    var posts = activeFilter.value == 'All'
                        ? availablePosts
                        : availablePosts
                            .where((p) => p.toneTag == activeFilter.value)
                            .toList();

                    if (posts.isEmpty) {
                      if (selectedSpace.value == 'saved_for_later') {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                  key: const Key('empty_saved_reflections_placeholder'),
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
        title: InkWell(
          key: const Key('belong_app_bar_title_tap_target'),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            brand.shortName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Refuge',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                ref.read(sensoryThemeModeProvider.notifier).toggleHighContrast();
              }
            },
          ),
          PopupMenuButton<SensoryMode>(
            tooltip: 'Sensory Themes',
            icon: const Icon(Icons.brightness_6_rounded, size: 20),
            onSelected: setSensoryMode,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: SensoryMode.clean,
                child: Row(
                  children: [
                    Text('☀️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Clean'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.sage,
                child: Row(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Sage'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.charcoal,
                child: Row(
                  children: [
                    Text('🌙', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Dark'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.contrast,
                child: Row(
                  children: [
                    Text('👁️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Contrast'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: IconButton.filledTonal(
              key: const Key('home_top_bar_create_post_button'),
              tooltip: 'Create Post or Image Post (+)',
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _showCreatePostModal(
                context: context,
                selectedSpace: selectedSpace.value,
                primaryColor: primaryColor,
                isContrast: isContrast,
                onSubmit: submitPost,
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
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.black : primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
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
          ChoiceChip(
            key: const Key('subnav_feed_tab'),
            label: const Text('Feed'),
            selected: isFeed,
            onSelected: (_) => onSelectFeed(),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            key: const Key('subnav_spaces_tab'),
            label: const Text('Spaces'),
            selected: isSpaces,
            onSelected: (_) => onSelectSpaces(),
          ),
          const Spacer(),
          ActionChip(
            key: const Key('open_feedback_and_voting_button'),
            avatar: const Icon(Icons.how_to_vote_outlined, size: 16),
            label: const Text('Vote & Feedback'),
            onPressed: () => BelongFeedbackAndVotingSheet.show(context),
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
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
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
                            Icons.post_add_rounded,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Create Reflection or Image Post',
                            style: TextStyle(
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
                  onSubmit: ({
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
