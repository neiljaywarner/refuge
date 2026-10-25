import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Circle-Style Post Creation Menu & Flows (Epic #315)', () {
    late LocalPostRepository repo;

    setUp(() {
      repo = LocalPostRepository(isDevMode: true);
    });

    patrolWidgetTest(
      'Top AppBar "+" button opens Circle-style menu with Create Post and Create Image Post',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        final createButton = $(Key('home_top_bar_create_post_button'));
        expect(createButton, findsOneWidget);

        // Tap the '+' menu affordance
        await $(createButton).tap();
        await $.pumpAndSettle();

        // Verify Circle-style popup menu items are present
        expect($(Key('menu_item_create_post')), findsOneWidget);
        expect($('Create Post'), findsOneWidget);
        expect($('Share an unhurried thought or prayer'), findsOneWidget);

        expect($(Key('menu_item_create_image_post')), findsOneWidget);
        expect($('Create Image Post'), findsOneWidget);
        expect($('Share a meme, photo, or scripture art'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Selecting "Create Post" opens text reflection composer and publishes to feed',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        // Open menu and tap Create Post
        await $(Key('home_top_bar_create_post_button')).tap();
        await $.pumpAndSettle();
        await $(Key('menu_item_create_post')).tap();
        await $.pumpAndSettle();

        // Verify modal title
        expect($('Create Reflection Post'), findsOneWidget);
        expect($(Key('image_post_url_input')), findsNothing);

        // Enter reflection text
        final input = $(Key('reflection_composer_input'));
        expect(input, findsWidgets);
        await $(input.last).enterText('Grateful for unhurried rest in Christ today.');
        await $.pumpAndSettle();

        // Tap publish
        await $(Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        // Verify modal dismissed and post appears in feed
        expect($('Grateful for unhurried rest in Christ today.'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Selecting "Create Image Post" opens image composer with URL & alt-text fields and publishes',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        // Open menu and tap Create Image Post
        await $(Key('home_top_bar_create_post_button')).tap();
        await $.pumpAndSettle();
        await $(Key('menu_item_create_image_post')).tap();
        await $.pumpAndSettle();

        // Verify image post modal title & dedicated inputs
        expect($('Create Image Post'), findsOneWidget);
        expect($(Key('image_post_url_input')), findsOneWidget);
        expect($(Key('image_post_alt_text_input')), findsOneWidget);
        expect($(Key('special_interest_tag_input')), findsOneWidget);

        // Enter image details
        await $(Key('image_post_url_input'))
            .enterText('https://images.unsplash.com/photo-nature-calm');
        await $(Key('image_post_alt_text_input'))
            .enterText('Quiet stream flowing over smooth mossy stones in morning light');
        await $(Key('reflection_composer_input')).last
            .enterText('He leads me beside quiet waters. (Psalm 23:2)');
        await $.pumpAndSettle();

        // Verify preview container appeared
        expect($(Key('image_post_preview_container')), findsOneWidget);
        expect($(Key('remove_image_button')), findsOneWidget);

        // Tap publish
        await $(Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        // Verify post rendered with text and alt-text tag
        expect(
          $(find.textContaining('He leads me beside quiet waters. (Psalm 23:2)')),
          findsOneWidget,
        );
        expect(
          $(find.textContaining('Quiet stream flowing over smooth mossy stones in morning light')),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      'Bug #321 verification: Empty text with no image shows gentle snackbar feedback',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        // Open menu and tap Create Post
        await $(Key('home_top_bar_create_post_button')).tap();
        await $.pumpAndSettle();
        await $(Key('menu_item_create_post')).tap();
        await $.pumpAndSettle();

        // Tap publish with empty text
        await $(Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        // Verify snackbar is displayed informing author gently
        expect($(Key('empty_reflection_warning_snackbar')), findsOneWidget);
        expect($('Please write a thought or reflection before publishing.'), findsOneWidget);
      },
    );
  });
}
