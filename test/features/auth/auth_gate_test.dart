import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_provider.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

AuthSession _signedInSession({
  required String email,
  bool emailVerified = false,
}) => AuthSession(
  userId: 'uid-${email.hashCode}',
  displayName: 'Fellowship Member',
  email: email,
  bio: 'bio',
  comfortBadges: const ['Literal communication appreciated'],
  isSignedIn: true,
  authMethod: 'in_memory_password',
  emailVerified: emailVerified,
);

Widget _gateApp({
  required AuthRepository authRepo,
  required AppFlavor flavor,
  List<Override> extra = const [],
}) => RefugeApp(
  repository: LocalPostRepository(),
  enforceSignIn: true,
  overrides: [
    authRepositoryProvider.overrideWithValue(authRepo),
    appFlavorProvider.overrideWithValue(flavor),
    ...extra,
  ],
);

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
    for (final flavor in [AppFlavor.dev, AppFlavor.prod]) {
      testWidgets('soft-deleted member is blocked from home (${flavor.slug})', (
        tester,
      ) async {
        final session = _signedInSession(
          email: 'gone@belongonthespectrum.com',
          emailVerified: true,
        );
        final deletion = AccountDeletionRepository(
          sinks: [InMemoryAccountDeletionSink()],
          flavor: flavor.slug,
        );
        await deletion.softDeleteSelf(
          userId: session.userId,
          displayName: session.displayName,
          email: session.email,
          confirmed: true,
        );

        await tester.pumpWidget(
          _gateApp(
            authRepo: InMemoryAuthRepository(initialSession: session),
            flavor: flavor,
            extra: [
              accountDeletionRepositoryProvider.overrideWithValue(deletion),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('auth_gate_soft_deleted_wall')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('belong_profile_avatar_button')),
          findsNothing,
        );
      });
    }

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
        expect(
          find.text('[DEV] Sign in to Belong on the Spectrum PREVIEW'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_top_bar_sign_in_button')),
          findsNothing,
        );
      });
    });

    testWidgets('prod sign-in wall has no DEV prefix', (tester) async {
      final authRepo = InMemoryAuthRepository();
      await tester.pumpWidget(
        _gateApp(authRepo: authRepo, flavor: AppFlavor.prod),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to Belong on the Spectrum'), findsOneWidget);
    });

    testWidgets('prod unverified shows verify wall', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(
        _gateApp(authRepo: authRepo, flavor: AppFlavor.prod),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('auth_gate_verify_email_wall')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('home_top_bar_sign_in_button')),
        findsNothing,
      );
    });

    testWidgets('dev unverified reaches home with avatar', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(
        _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('auth_gate_verify_email_wall')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('belong_profile_avatar_button')),
        findsOneWidget,
      );
    });

    testWidgets('prod verified reaches home', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: true,
        ),
      );
      await tester.pumpWidget(
        _gateApp(authRepo: authRepo, flavor: AppFlavor.prod),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('auth_gate_verify_email_wall')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('belong_profile_avatar_button')),
        findsOneWidget,
      );
    });

    testWidgets('prod unverified reload opens home', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );
      await tester.pumpWidget(
        _gateApp(authRepo: authRepo, flavor: AppFlavor.prod),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_gate_i_verified')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('auth_gate_verify_email_wall')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('belong_profile_avatar_button')),
        findsOneWidget,
      );
    });

    testWidgets('anonymous session stays on the sign-in wall', (tester) async {
      await runWithPlatform(tester, TargetPlatform.android, () async {
        final authRepo = InMemoryAuthRepository(
          initialSession: AuthSession(
            userId: 'anon-uid',
            displayName: 'Anonymous',
            email: '',
            bio: 'bio',
            comfortBadges: const ['Literal communication appreciated'],
            isSignedIn: true,
            authMethod: 'anonymous',
          ),
        );
        await tester.pumpWidget(
          _gateApp(authRepo: authRepo, flavor: AppFlavor.dev),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);
        expect(
          find.byKey(const Key('home_top_bar_sign_in_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('belong_profile_avatar_button')),
          findsNothing,
        );
      });
    });
  });
}
