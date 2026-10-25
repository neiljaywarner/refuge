import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_access_policy.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

AuthSession _signedInSession({
  required String email,
  bool emailVerified = false,
}) {
  return AuthSession(
    userId: 'uid-${email.hashCode}',
    displayName: 'Fellowship Member',
    email: email,
    bio: 'bio',
    comfortBadges: const ['Literal communication appreciated'],
    isSignedIn: true,
    authMethod: 'in_memory_password',
    emailVerified: emailVerified,
  );
}

Widget _gateApp({
  required AuthRepository authRepo,
  required AppFlavor flavor,
}) {
  return RefugeApp(
    repository: LocalPostRepository(),
    enforceSignIn: true,
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      appFlavorProvider.overrideWithValue(flavor),
    ],
  );
}

Future<void> runWithPlatform(
  WidgetTester tester,
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  final previous = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}

void main() {
  group('AuthGate', () {
    testWidgets('guest on dev shows sign-in wall, not home bar sign-in', (
      tester,
    ) async {
      await runWithPlatform(tester, TargetPlatform.android, () async {
        final authRepo = InMemoryAuthRepository();
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);
        expect(find.text('Sign In to Belong'), findsOneWidget);
        expect(
          find.byKey(const Key('home_top_bar_sign_in_button')),
          findsNothing,
        );
      });
    });

    testWidgets('dev android shows example account buttons', (tester) async {
      await runWithPlatform(tester, TargetPlatform.android, () async {
        final authRepo = InMemoryAuthRepository();
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dev_example_user_1')), findsOneWidget);
        expect(find.byKey(const Key('dev_example_user_2')), findsOneWidget);
      });
    });

    testWidgets('dev iOS hides example account buttons', (tester) async {
      await runWithPlatform(tester, TargetPlatform.iOS, () async {
        final authRepo = InMemoryAuthRepository();
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dev_example_user_1')), findsNothing);
        expect(find.byKey(const Key('dev_example_user_2')), findsNothing);
      });
    });

    testWidgets('prod android hides example account buttons', (tester) async {
      await runWithPlatform(tester, TargetPlatform.android, () async {
        final authRepo = InMemoryAuthRepository();
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.prod),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dev_example_user_1')), findsNothing);
      });
    });

    testWidgets('prod unverified shows verify wall', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(_gateApp(authRepo: authRepo, flavor: AppFlavor.prod));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsOneWidget);
      expect(find.byKey(const Key('home_top_bar_sign_in_button')), findsNothing);
    });

    testWidgets('dev unverified reaches home with avatar', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(_gateApp(authRepo: authRepo, flavor: AppFlavor.dev));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsNothing);
      expect(find.byKey(const Key('belong_profile_avatar_button')), findsOneWidget);
    });

    testWidgets('prod verified reaches home', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: true,
        ),
      );
      await tester.pumpWidget(_gateApp(authRepo: authRepo, flavor: AppFlavor.prod));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsNothing);
      expect(find.byKey(const Key('belong_profile_avatar_button')), findsOneWidget);
    });

    testWidgets('prod unverified reload opens home', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(_gateApp(authRepo: authRepo, flavor: AppFlavor.prod));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_gate_i_verified')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsNothing);
      expect(find.byKey(const Key('belong_profile_avatar_button')), findsOneWidget);
    });

    testWidgets('empty DEV_EXAMPLE_PASSWORD disables example buttons', (
      tester,
    ) async {
      await runWithPlatform(tester, TargetPlatform.android, () async {
        expect(devExamplePassword, isEmpty);

        final authRepo = InMemoryAuthRepository();
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('dev_example_user_1')),
        );
        expect(button.onPressed, isNull);
        expect(find.text(devExamplePasswordMissingMessage), findsOneWidget);
      });
    });
  });
}
