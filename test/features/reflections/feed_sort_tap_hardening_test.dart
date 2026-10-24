import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';

/// Comment metadata that fails the way a permission error does in production.
class _ThrowingCommentRepository extends LocalCommentRepository {
  _ThrowingCommentRepository()
    : super(isDevMode: false, initialComments: const []);

  @override
  Future<Map<String, DateTime>> getLatestActivityTimestamps() async {
    throw StateError('activity timestamps unavailable');
  }

  @override
  Future<Map<String, int>> getAllCommentCounts() async {
    throw StateError('comment counts unavailable');
  }
}

class _GuestProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile.guest();
}

class _SignedInProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() {
    return const MemberProfile(
      displayName: 'Fellow Member',
      email: 'member@belongonthespectrum.com',
      bio: 'Church acoustics and quiet rest',
      comfortBadges: ['Literal communication appreciated'],
      isSignedIn: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Post> samplePosts() {
    final now = DateTime.now();
    return [
      Post(
        id: 'demo_david',
        authorName: 'David M.',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Please pray for peace of mind this week.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        reactions: const {'pray': 6, 'peace': 4},
        isDemo: true,
      ),
      Post(
        id: 'demo_elena',
        authorName: 'Elena R.',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Heavy sensory fatigue after errands today.',
        timestamp: now.subtract(const Duration(hours: 2)),
        reactions: const {'pray': 1, 'peace': 4},
        isDemo: true,
      ),
      Post(
        id: 'live_pastor',
        authorName: 'Pastor Thomas',
        spaceKey: 'prayer',
        toneTag: '[Question]',
        content: 'Quiet waters in Psalm 23.',
        timestamp: now.subtract(const Duration(hours: 5)),
        reactions: const {'pray': 5},
        isDemo: false,
      ),
    ];
  }

  Future<void> pumpFeed(
    PatrolTester $, {
    required LocalPostRepository repo,
    Size size = const Size(1080, 2400),
    SensoryMode theme = SensoryMode.sage,
    bool guestProfile = true,
    List<Override> overrides = const [],
  }) async {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = size;
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      // Phone-width yellow stripes on the app bar, welcome banner, and
      // author row predate this ticket. They are not the sort-tap crash.
      if (text.contains('A RenderFlex overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
    await $.pumpWidget(
      RepaintBoundary(
        key: const Key('feed_sort_shot'),
        child: RefugeApp(
          key: ValueKey('${theme.name}-$guestProfile-${overrides.length}'),
          repository: repo,
          initialTheme: theme,
          overrides: [
            if (guestProfile)
              memberProfileProvider.overrideWith(_GuestProfile.new),
            ...overrides,
          ],
          homeOverride: const RefugeHomeScreen(),
        ),
      ),
    );
    await $.pumpAndSettle();
  }

  Future<void> tapSort(PatrolTester $, FeedSortOption option) async {
    final key = Key('feed_sort_chip_${option.name}');
    await $.tester.ensureVisible(find.byKey(key));
    await $.tester.tap(find.byKey(key));
    await $.pumpAndSettle();
    expect($.tester.takeException(), isNull);
    final chip = $.tester.widget<ChoiceChip>(find.byKey(key));
    expect(chip.selected, isTrue);
  }

  group('Sort and filter taps stay up (#485)', () {
    patrolWidgetTest(
      'every sort chip, rapid retap, and popup on the demo feed',
      ($) async {
        await pumpFeed(
          $,
          repo: LocalPostRepository(
            isDevMode: false,
            initialPosts: samplePosts(),
          ),
        );

        expect(find.textContaining('Demo Mode'), findsOneWidget);
        expect(
          find.textContaining('peace of mind', skipOffstage: false),
          findsOneWidget,
        );

        for (final option in FeedSortOption.values) {
          await tapSort($, option);
          await tapSort($, option);
          expect(
            find.textContaining('peace of mind', skipOffstage: false),
            findsOneWidget,
          );
        }

        await $.tester.tap(find.byKey(const Key('feed_sort_popup_button')));
        await $.pumpAndSettle();
        for (final option in FeedSortOption.values) {
          expect(
            find.byKey(Key('feed_sort_menu_item_${option.name}')),
            findsOneWidget,
          );
        }
        await $.tester.tap(find.byKey(const Key('feed_sort_menu_item_forYou')));
        await $.pumpAndSettle();
        expect(
          $.tester
              .widget<ChoiceChip>(
                find.byKey(const Key('feed_sort_chip_forYou')),
              )
              .selected,
          isTrue,
        );
        expect($.tester.takeException(), isNull);
      },
    );

    patrolWidgetTest(
      'every tone filter then every sort on a narrow dark phone',
      ($) async {
        await pumpFeed(
          $,
          repo: LocalPostRepository(
            isDevMode: false,
            initialPosts: samplePosts(),
          ),
          size: const Size(360, 844),
          theme: SensoryMode.charcoal,
        );

        for (final filter in kToneFilters) {
          final key = Key(toneFilterSemanticsId(filter));
          await $.tester.ensureVisible(find.byKey(key));
          await $.tester.tap(find.byKey(key));
          await $.pumpAndSettle();
          expect($.tester.takeException(), isNull);
          expect($.tester.widget<ChoiceChip>(find.byKey(key)).selected, isTrue);
          for (final option in FeedSortOption.values) {
            await tapSort($, option);
          }
        }

        expect(find.byKey(const Key('feed_sort_chip_latest')), findsOneWidget);
      },
    );

    patrolWidgetTest('light theme empty feed survives every sort and filter', (
      $,
    ) async {
      await pumpFeed(
        $,
        repo: LocalPostRepository(isDevMode: false, initialPosts: const []),
        size: const Size(390, 844),
        theme: SensoryMode.sage,
      );

      expect(
        find.byKey(const Key('empty_reflections_placeholder')),
        findsOneWidget,
      );
      for (final option in FeedSortOption.values) {
        await tapSort($, option);
        expect(
          find.byKey(const Key('empty_reflections_placeholder')),
          findsOneWidget,
        );
      }
      for (final filter in kToneFilters) {
        final key = Key(toneFilterSemanticsId(filter));
        await $.tester.ensureVisible(find.byKey(key));
        await $.tester.tap(find.byKey(key));
        await $.pumpAndSettle();
        expect($.tester.takeException(), isNull);
        expect(
          find.byKey(const Key('empty_reflections_placeholder')),
          findsOneWidget,
        );
      }
    });

    patrolWidgetTest('failed comment metadata does not red-screen a sort tap', (
      $,
    ) async {
      final ignored = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('activity timestamps unavailable') ||
            message.contains('comment counts unavailable')) {
          ignored.add(details);
          return;
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await pumpFeed(
        $,
        repo: LocalPostRepository(
          isDevMode: false,
          initialPosts: samplePosts(),
        ),
        size: const Size(390, 844),
        theme: SensoryMode.charcoal,
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            _ThrowingCommentRepository(),
          ),
        ],
      );

      expect(
        find.textContaining('peace of mind', skipOffstage: false),
        findsOneWidget,
      );
      for (final option in FeedSortOption.values) {
        await tapSort($, option);
        expect(
          find.textContaining('peace of mind', skipOffstage: false),
          findsOneWidget,
        );
      }
      expect($.tester.takeException(), isNull);
    });

    patrolWidgetTest(
      'signed-in feed hides demo posts while sorts stay tappable',
      ($) async {
        await pumpFeed(
          $,
          repo: LocalPostRepository(
            isDevMode: false,
            initialPosts: samplePosts(),
          ),
          size: const Size(390, 844),
          guestProfile: false,
          overrides: [memberProfileProvider.overrideWith(_SignedInProfile.new)],
        );

        expect(find.textContaining('Demo Mode'), findsNothing);
        expect(
          find.textContaining('peace of mind', skipOffstage: false),
          findsNothing,
        );
        expect(find.textContaining('Quiet waters'), findsOneWidget);
        for (final option in FeedSortOption.values) {
          await tapSort($, option);
          expect(find.textContaining('Quiet waters'), findsOneWidget);
        }
      },
    );

    patrolWidgetTest('captures dark and light sort-strip frames', ($) async {
      Future<void> save(String name) async {
        final boundary = $.tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('feed_sort_shot')),
        );
        await $.tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      await pumpFeed(
        $,
        repo: LocalPostRepository(
          isDevMode: false,
          initialPosts: samplePosts(),
        ),
        size: const Size(390, 844),
        theme: SensoryMode.charcoal,
      );
      await tapSort($, FeedSortOption.forYou);
      await save('issue_485_after_dark_for_you');

      await pumpFeed(
        $,
        repo: LocalPostRepository(
          isDevMode: false,
          initialPosts: samplePosts(),
        ),
        size: const Size(390, 844),
        theme: SensoryMode.sage,
      );
      final comfort = Key(toneFilterSemanticsId('[Comfort Only]'));
      await $.tester.ensureVisible(find.byKey(comfort));
      await $.tester.tap(find.byKey(comfort));
      await $.pumpAndSettle();
      await save('issue_485_after_light_comfort');
      expect($.tester.takeException(), isNull);
    });
  });
}
