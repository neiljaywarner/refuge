import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';

AuthSession _signedInSession() => AuthSession(
  userId: 'uid-member',
  displayName: 'Rachel S. (Dallas)',
  email: 'member@belongonthespectrum.com',
  bio: 'Fellowship member',
  comfortBadges: const ['Quiet fellowship'],
  isSignedIn: true,
  authMethod: 'in_memory_password',
  emailVerified: true,
);

void main() {
  group('Members-only feed vs sign-in wall BDD Tests (#668, #673)', () {
    late LocalPostRepository postRepo;

    setUp(() {
      postRepo = LocalPostRepository(isDevMode: true);
    });

    Widget signedInApp() => RefugeApp(
      repository: postRepo,
      enforceSignIn: true,
      overrides: [
        postRepositoryProvider.overrideWithValue(postRepo),
        authRepositoryProvider.overrideWithValue(
          InMemoryAuthRepository(initialSession: _signedInSession()),
        ),
        appFlavorProvider.overrideWithValue(AppFlavor.dev),
      ],
    );

    patrolWidgetTest('unsigned visitor sees sign-in wall, not demo feed or guest banner', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(
        RefugeApp(
          repository: postRepo,
          enforceSignIn: true,
          overrides: [
            postRepositoryProvider.overrideWithValue(postRepo),
            authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
            appFlavorProvider.overrideWithValue(AppFlavor.dev),
          ],
        ),
      );
      await $.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);
      expect(find.byKey(const Key('demo_mode_banner')), findsNothing);
      expect(find.byKey(const Key('home_top_bar_sign_in_button')), findsNothing);
      expect($('David M. (UK)'), findsNothing);
    });

    patrolWidgetTest('Signed-in member sees real data feed without dummy demo posts', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(signedInApp());
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);
      await $.pumpAndSettle();

      expect(find.byKey(const Key('demo_mode_banner')), findsNothing);
      expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsNothing);
      expect($('David M. (UK)'), findsNothing);

      expect(find.byKey(const Key('empty_reflections_placeholder')), findsOneWidget);
      expect($('No community reflections yet in this space.'), findsOneWidget);

      await $(const Key('reflection_composer_input')).enterText('Blessed to gather together tonight.');
      await $.pumpAndSettle();
      await $(const Key('publish_reflection_button')).tap();
      await $.pumpAndSettle();

      expect($('Blessed to gather together tonight.'), findsOneWidget);
      expect($('Rachel S. (Dallas)'), findsOneWidget);
    });
  });
}
