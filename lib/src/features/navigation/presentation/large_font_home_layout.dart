import 'package:flutter/material.dart';

import '../../reflections/domain/feed_sort_option.dart';
import '../../reflections/domain/post.dart';
import '../../reflections/presentation/reflection_composer.dart';
import '../../reflections/presentation/space_navigation_bar.dart';

/// Text scale above which the home feed drops its pinned chrome (#951).
///
/// 1.3 keeps the scrolling header from #932. Above that, a Pixel-sized phone
/// cannot show the welcome card, room controls, and composer and still leave
/// the feed the screen's main job.
const double kLargeFontHomeLayoutThreshold = 1.3;

/// True when [textScale] should use the drawer and full-screen composer.
bool useLargeFontHomeLayout(double textScale) => textScale > kLargeFontHomeLayoutThreshold;

/// Home controls that would otherwise sit above the first reflection.
///
/// The bottom navigation bar stays the top-level switch (Home, Notifications,
/// Messages, Search). This drawer holds the secondary home chrome: Feed and
/// Spaces, Vote & Feedback, the room and its filters, the gathering summary,
/// and the welcome note.
class LargeFontHomeDrawer extends StatelessWidget {
  const LargeFontHomeDrawer({
    super.key,
    required this.spaceTitle,
    required this.selectedSpace,
    required this.feedSelected,
    required this.spacesSelected,
    required this.activeFilter,
    required this.activeSort,
    required this.isContrast,
    required this.primaryColor,
    required this.showWelcome,
    required this.welcomeTitle,
    required this.welcomeMessage,
    required this.gatheringSummary,
    required this.onSelectFeed,
    required this.onSelectSpaces,
    required this.onSelectSpace,
    required this.onSelectFilter,
    required this.onSelectSort,
    required this.onOpenVote,
    required this.onOpenAbout,
    this.onBackToSpaces,
  });

  final String spaceTitle;
  final String selectedSpace;
  final bool feedSelected;
  final bool spacesSelected;
  final String activeFilter;
  final FeedSortOption activeSort;
  final bool isContrast;
  final Color primaryColor;
  final bool showWelcome;
  final String welcomeTitle;
  final String welcomeMessage;
  final String? gatheringSummary;
  final VoidCallback onSelectFeed;
  final VoidCallback onSelectSpaces;
  final ValueChanged<String> onSelectSpace;
  final ValueChanged<String> onSelectFilter;
  final ValueChanged<FeedSortOption> onSelectSort;
  final VoidCallback onOpenVote;
  final VoidCallback onOpenAbout;
  final VoidCallback? onBackToSpaces;

  @override
  Widget build(BuildContext context) {
    final titleColor = isContrast ? Colors.yellow : primaryColor;
    return Drawer(
      key: const Key('large_font_home_drawer'),
      semanticLabel: 'Home menu',
      child: SafeArea(
        child: ListView(
          padding: const .only(bottom: 24),
          children: [
            Padding(
              padding: const .fromLTRB(16, 16, 16, 4),
              child: Text(
                spaceTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),
            _DestinationTile(
              tileKey: const Key('subnav_feed_tab'),
              identifier: 'feed_tab',
              label: 'Feed',
              icon: Icons.dynamic_feed_outlined,
              selected: feedSelected,
              onTap: () {
                Navigator.of(context).pop();
                onSelectFeed();
              },
            ),
            _DestinationTile(
              tileKey: const Key('subnav_spaces_tab'),
              identifier: 'spaces_tab',
              label: 'Spaces',
              icon: Icons.grid_view_rounded,
              selected: spacesSelected,
              onTap: () {
                Navigator.of(context).pop();
                onSelectSpaces();
              },
            ),
            _DestinationTile(
              tileKey: const Key('open_feedback_and_voting_button'),
              identifier: 'vote_feedback_button',
              label: 'Vote & Feedback',
              icon: Icons.how_to_vote_outlined,
              onTap: () {
                Navigator.of(context).pop();
                onOpenVote();
              },
            ),
            _DestinationTile(
              tileKey: const Key('large_font_drawer_about_button'),
              identifier: 'banner_learn_more_button',
              label: 'About',
              icon: Icons.info_outline_rounded,
              onTap: () {
                Navigator.of(context).pop();
                onOpenAbout();
              },
            ),
            const Divider(),
            SpaceNavigationBar(
              selectedSpace: selectedSpace,
              onSelectSpace: onSelectSpace,
              onBackToSpaces: onBackToSpaces,
              activeFilter: activeFilter,
              onSelectFilter: onSelectFilter,
              activeSort: activeSort,
              onSelectSort: onSelectSort,
              isContrast: isContrast,
              minControlHeight: 48,
            ),
            if (gatheringSummary != null && gatheringSummary!.isNotEmpty)
              Padding(
                padding: const .fromLTRB(16, 12, 16, 8),
                child: Text(
                  gatheringSummary!,
                  key: const Key('large_font_gathering_summary'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                    color: isContrast ? Colors.yellow : null,
                  ),
                ),
              ),
            if (showWelcome)
              Padding(
                padding: const .fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      welcomeTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(welcomeMessage, style: const TextStyle(fontSize: 14, height: 1.35)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.tileKey,
    required this.identifier,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final Key tileKey;
  final String identifier;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: identifier,
    label: label,
    button: true,
    selected: selected,
    container: true,
    excludeSemantics: true,
    onTap: onTap,
    child: ListTile(
      key: tileKey,
      selected: selected,
      minTileHeight: 48,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    ),
  );
}

/// Full-screen composer so posting, not the surrounding chrome, fills the phone.
Future<void> showLargeFontComposer({
  required BuildContext context,
  required String selectedSpace,
  required Color primaryColor,
  required bool isContrast,
  bool isImagePost = false,
  required Future<PostPublishStatus> Function({
    required String content,
    required String toneTag,
    String? specialInterestTag,
    String? imageUrl,
  })
  onSubmit,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (routeContext) => Scaffold(
      key: const Key('large_font_composer_screen'),
      appBar: AppBar(
        title: Text(
          isImagePost ? 'Share an image' : 'Share a thought',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          tooltip: 'Close composer',
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(routeContext).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('large_font_composer_surface'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: ReflectionComposer(
                selectedSpace: selectedSpace,
                primaryColor: primaryColor,
                isContrast: isContrast,
                isImagePost: isImagePost,
                isModal: true,
                onSubmit: onSubmit,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// Compact post action. It floats over the feed instead of pushing the first
/// reflection down the page.
class LargeFontShareThoughtButton extends StatelessWidget {
  const LargeFontShareThoughtButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    key: const Key('large_font_share_thought_button'),
    heroTag: 'large_font_share_thought',
    tooltip: 'Share a thought',
    onPressed: onPressed,
    icon: const Icon(Icons.edit_note_rounded),
    label: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: const Text('Share a thought', maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
