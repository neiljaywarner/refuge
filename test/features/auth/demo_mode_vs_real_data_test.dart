import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

class FakeMemberProfileNotifier extends MemberProfileNotifier {
  final MemberProfile initial;
  FakeMemberProfileNotifier(this.initial);

  @override
  MemberProfile build() => initial;
}

void main() {
  group('Demo Mode vs Signed-In Real Community Feed BDD Tests', () {
    late LocalPostRepository postRepo;

    setUp(() {
      postRepo = LocalPostRepository(isDevMode: true);
    });

    Widget createTestApp({required MemberProfile profile}) {
      return ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(postRepo),
          memberProfileProvider.overrideWith(
            () => FakeMemberProfileNotifier(profile),
          ),
        ],
        child: const MaterialApp(
          home: RefugeHomeScreen(),
        ),
      );
    }

    patrolWidgetTest(
      'Guest user sees Demo Mode banner and sample reflections',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          createTestApp(profile: const MemberProfile.guest()),
        );
        await $.pumpAndSettle();

        // 1. Demo Mode banner is visible
        expect($(const Key('demo_mode_banner')), findsOneWidget);
        expect($('Demo Mode · Sample reflections shown. Sign in to view and share live community reflections.'), findsWidgets);

        // 2. Sample seeded reflections are visible
        expect($('David M. (UK)'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Signed-in member sees real data feed without dummy demo posts',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        const signedInProfile = MemberProfile(
          displayName: 'Rachel S. (Dallas)',
          email: 'rachel@example.com',
          bio: 'Fellowship member',
          comfortBadges: ['Quiet fellowship'],
          isSignedIn: true,
          icocChurchAffiliation: 'Dallas Church of Christ',
        );

        await $.pumpWidget(
          createTestApp(profile: signedInProfile),
        );
        await $.pumpAndSettle();

        // 1. Demo Mode banner is NOT visible
        expect($(const Key('demo_mode_banner')), findsNothing);

        // 2. Dummy seeded reflections are filtered out
        expect($('David M. (UK)'), findsNothing);

        // 3. Peaceful empty state is rendered
        expect($(const Key('empty_reflections_placeholder')), findsOneWidget);
        expect($('No community reflections yet in this space.'), findsOneWidget);

        // 4. Submitting a new reflection adds real data
        await $(const Key('reflection_composer_input')).enterText('Blessed to gather together tonight.');
        await $.pumpAndSettle();
        await $(const Key('publish_reflection_button')).tap();
        await $.pumpAndSettle();

        // Now the real reflection is displayed
        expect($('Blessed to gather together tonight.'), findsOneWidget);
        expect($('Rachel S. (Dallas)'), findsOneWidget);
      },
    );
  });
}
