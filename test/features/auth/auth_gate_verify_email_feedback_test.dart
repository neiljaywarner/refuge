import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_exception.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

import 'auth_gate_test_helpers.dart';

AuthSession _signedInSession({required String email, bool emailVerified = false}) => AuthSession(
  userId: 'uid-${email.hashCode}',
  displayName: 'Fellowship Member',
  email: email,
  bio: 'bio',
  comfortBadges: const ['Literal communication appreciated'],
  isSignedIn: true,
  authMethod: 'in_memory_password',
  emailVerified: emailVerified,
);

Widget _gateApp({required AuthRepository authRepo, AppFlavor flavor = AppFlavor.prod}) => RefugeApp(
  repository: LocalPostRepository(),
  enforceSignIn: true,
  overrides: [
    authRepositoryProvider.overrideWithValue(authRepo),
    appFlavorProvider.overrideWithValue(flavor),
  ],
);

class FakeAuthRepository extends InMemoryAuthRepository {
  FakeAuthRepository({
    required super.initialSession,
    this.reloadVerified = false,
    this.resendException,
  });

  bool reloadVerified;
  Object? resendException;
  Completer<void>? pendingReload;
  Completer<void>? pendingResend;
  int resendCallCount = 0;

  @override
  Future<AuthSession> reloadCurrentUser() async {
    if (pendingReload != null) {
      await pendingReload!.future;
    }
    if (reloadVerified) {
      return super.reloadCurrentUser();
    }
    return currentSession();
  }

  @override
  Future<void> sendEmailVerification() async {
    resendCallCount++;
    if (pendingResend != null) {
      await pendingResend!.future;
    }
    if (resendException != null) {
      throw resendException!;
    }
  }
}

void main() {
  setUp(() {
    ProfileStorageService.instance.clear();
  });

  tearDown(() {
    ProfileStorageService.instance.clear();
  });

  group('AuthGate VerifyEmailWall Feedback & Busy Guard (#661)', () {
    testWidgets('status message is initially absent on wall visit', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsOneWidget);
      expect(find.byKey(const Key('auth_gate_verify_status')), findsNothing);
      expect(
        find.text(
          'We sent a verification link to member@belongonthespectrum.com. Open it, then come back.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('resend success renders calm confirmation copy', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_gate_resend_verification')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_status')), findsOneWidget);
      expect(
        find.text('Sent a fresh verification link. Please check your inbox and spam folder.'),
        findsOneWidget,
      );
    });

    testWidgets('resend failure with AuthException renders friendly message', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      repo.resendException = const AuthException(
        code: 'too-many-requests',
        message: 'Too many attempts. Please wait a minute before requesting another link.',
      );

      await tester.tap(find.byKey(const Key('auth_gate_resend_verification')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_status')), findsOneWidget);
      expect(
        find.text('Too many attempts. Please wait a minute before requesting another link.'),
        findsOneWidget,
      );
    });

    testWidgets('resend failure with unmapped error renders calm fallback guidance', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      repo.resendException = Exception('SocketException: Connection refused');

      await tester.tap(find.byKey(const Key('auth_gate_resend_verification')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_status')), findsOneWidget);
      expect(
        find.text('Could not send right now. Please wait a minute and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('reload while still unverified displays calm guidance', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
        reloadVerified: false,
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_gate_i_verified')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsOneWidget);
      expect(find.byKey(const Key('auth_gate_verify_status')), findsOneWidget);
      expect(
        find.text(
          'Not verified yet. Open the link in your email first, then tap I verified my email.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reload once verified unlocks home screen', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
        reloadVerified: true,
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_gate_i_verified')));
      await tester.pumpAndSettle();
      await dismissFirstVisitWelcomeIfShown(tester);

      expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsNothing);
      expect(find.byKey(const Key('belong_profile_avatar_button')), findsOneWidget);
    });

    testWidgets('busy guard disables action buttons while resend is in-flight', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      final pendingResend = Completer<void>();
      repo.pendingResend = pendingResend;

      await tester.tap(find.byKey(const Key('auth_gate_resend_verification')));
      await tester.pump();

      final iVerifiedBtn = tester.widget<FilledButton>(
        find.byKey(const Key('auth_gate_i_verified')),
      );
      final resendBtn = tester.widget<OutlinedButton>(
        find.byKey(const Key('auth_gate_resend_verification')),
      );
      expect(iVerifiedBtn.onPressed, isNull);
      expect(resendBtn.onPressed, isNull);

      pendingResend.complete();
      await tester.pumpAndSettle();

      final iVerifiedBtnAfter = tester.widget<FilledButton>(
        find.byKey(const Key('auth_gate_i_verified')),
      );
      final resendBtnAfter = tester.widget<OutlinedButton>(
        find.byKey(const Key('auth_gate_resend_verification')),
      );
      expect(iVerifiedBtnAfter.onPressed, isNotNull);
      expect(resendBtnAfter.onPressed, isNotNull);
      expect(find.byKey(const Key('auth_gate_verify_status')), findsOneWidget);
    });

    testWidgets('busy guard disables action buttons while reload is in-flight', (tester) async {
      final repo = FakeAuthRepository(
        initialSession: _signedInSession(
          email: 'member@belongonthespectrum.com',
          emailVerified: false,
        ),
        reloadVerified: false,
      );

      await tester.pumpWidget(_gateApp(authRepo: repo));
      await tester.pumpAndSettle();

      final pendingReload = Completer<void>();
      repo.pendingReload = pendingReload;

      await tester.tap(find.byKey(const Key('auth_gate_i_verified')));
      await tester.pump();

      final iVerifiedBtn = tester.widget<FilledButton>(
        find.byKey(const Key('auth_gate_i_verified')),
      );
      final resendBtn = tester.widget<OutlinedButton>(
        find.byKey(const Key('auth_gate_resend_verification')),
      );
      expect(iVerifiedBtn.onPressed, isNull);
      expect(resendBtn.onPressed, isNull);

      pendingReload.complete();
      await tester.pumpAndSettle();

      final iVerifiedBtnAfter = tester.widget<FilledButton>(
        find.byKey(const Key('auth_gate_i_verified')),
      );
      final resendBtnAfter = tester.widget<OutlinedButton>(
        find.byKey(const Key('auth_gate_resend_verification')),
      );
      expect(iVerifiedBtnAfter.onPressed, isNotNull);
      expect(resendBtnAfter.onPressed, isNotNull);
    });
  });
}
