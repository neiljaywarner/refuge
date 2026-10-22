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
      () => activeRepository.watchPosts(spaceKey: selectedSpace.value),
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
          description: item.description,
          icon: item.icon,
          extraNote: extraNote,
          onBackToSpaces: () => homeSubView.value = BelongHomeSubView.spaces,
        );
      }

      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          CommunityAnchorBanner(
            title: brand.communityName,
            subtitle: brand.tagline,
            primaryColor: primaryColor,
            isContrast: isContrast,
          ),
          SpaceNavigationBar(
            selectedSpaceKey: selectedSpace.value,
            onSelectSpace: selectSpace,
          ),
          QuietDigestBanner(
            snapshot: quietDigestSnapshot,
            isContrast: isContrast,
          ),
          ToneFilterRow(
            activeFilter: activeFilter.value,
            onFilterSelected: (tag) => activeFilter.value = tag,
          ),
          ReflectionComposer(
            onSubmit: submitPost,
            primaryColor: primaryColor,
            isContrast: isContrast,
          ),
          StreamBuilder<List<Post>>(
            stream: postStream,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              final filteredPosts = activeFilter.value == 'All'
                  ? posts
                  : posts.where((p) => p.toneTag == activeFilter.value).toList();

              if (filteredPosts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No reflections yet. Be the first to share.'),
                  ),
                );
              }

              return Column(
                children: filteredPosts.map((post) {
                  return ReflectionCard(
                    post: post,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                    onReact: (reactionKey) =>
                        activeRepository.addReaction(post.id, reactionKey),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            final now = DateTime.now();
            final lastTap = easterEggLastTap.value;
            easterEggLastTap.value = now;

            if (lastTap != null &&
                now.difference(lastTap) < const Duration(seconds: 2)) {
              easterEggTapCount.value++;
            } else {
              easterEggTapCount.value = 1;
            }

            if (easterEggTapCount.value >= 7) {
              easterEggTapCount.value = 0;
              showObservabilityEasterEggDialog(context);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/belong_logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, _, _) => const Text(
                    '♾️',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                brand.communityName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (isLiveServerpod) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green, width: 0.8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isContrast
                  ? Colors.yellow.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: isContrast
                      ? Colors.yellow
                      : primaryColor.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Partnered with DFW Church',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isContrast ? Colors.yellow : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Psalm 139:14',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (homeSubView.value == BelongHomeSubView.spaces) {
                      homeSubView.value = BelongHomeSubView.feed;
                    } else {
                      homeSubView.value = BelongHomeSubView.spaces;
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        homeSubView.value == BelongHomeSubView.spaces
                            ? 'Feed'
                            : 'Spaces (${remoteConfig.spacesCount})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isContrast ? Colors.yellow : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        homeSubView.value == BelongHomeSubView.spaces
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: isContrast ? Colors.yellow : primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // 1-Tap Quick High Contrast Mode Toggle (Issue #277)
          IconButton(
            key: const Key('home_high_contrast_toggle_button'),
            tooltip: isContrast
                ? 'Disable High Contrast'
                : 'Enable High Contrast (WCAG AAA)',
            icon: Icon(
              isContrast ? Icons.contrast_rounded : Icons.contrast_outlined,
              size: 20,
              color: isContrast ? Colors.yellow : null,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => setSensoryMode(
              isContrast ? SensoryMode.sage : SensoryMode.contrast,
            ),
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
              currentFontScale: currentFontScale,
              onSelectFontScale: setSensoryFontScale,
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
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => showBelongAuthSheet(context),
                icon: const Icon(Icons.login_rounded, size: 14),
                label: const Text('Sign In'),
              ),
            )
          else
            GestureDetector(
              onTap: () => showMemberProfileSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isContrast
                      ? Colors.yellow
                      : primaryColor.withValues(alpha: 0.2),
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
          IconButton(
            tooltip: 'Search & Fellowship',
            icon: const Icon(Icons.search_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommunitySearchView()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: switch (activeBottomTab.value) {
        BelongBottomTab.home => buildHomeBody(),
        BelongBottomTab.messages => const BelongMessagesView(),
        BelongBottomTab.notifications => const CalmNotificationsView(),
        BelongBottomTab.feedback => const BelongFeedbackAndVotingSheet(),
      },
      bottomNavigationBar: BelongBottomNavBar(
        currentTab: activeBottomTab.value,
        isContrast: isContrast,
        onTabSelected: (tab) => activeBottomTab.value = tab,
      ),
    );
  }
}
