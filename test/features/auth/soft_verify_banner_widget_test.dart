import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_exception.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/verify_email_copy.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

import 'auth_gate_test_helpers.dart';

/// Staging flavor lets an unverified member into Home and explains verification
/// on a banner. Production uses the check-email wall instead. Dev hides both.
class _RecordingAuthRepository extends InMemoryAuthRepository {
  _RecordingAuthRepository({required super.initialSession});

  bool failSend = false;
  int sends = 0;

  @override
  Future<void> sendEmailVerification() async {
    sends += 1;
    if (failSend) {
      throw const AuthException(code: 'network-request-failed', message: 'The network paused.');
    }
  }
}

void main() {
  setUp(ProfileStorageService.instance.clear);
  tearDown(ProfileStorageService.instance.clear);

  AuthSession unverified() => const AuthSession(
    userId: 'uid-stg',
    displayName: 'Sarah K.',
    email: 'member@belongonthespectrum.com',
    bio: 'bio',
    comfortBadges: ['Literal communication appreciated'],
    isSignedIn: true,
    authMethod: 'in_memory_password',
  );

  Future<void> pumpGate(WidgetTester tester, _RecordingAuthRepository auth) async {
    await tester.pumpWidget(
      RefugeApp(
        repository: LocalPostRepository(),
        enforceSignIn: true,
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          appFlavorProvider.overrideWithValue(AppFlavor.stg),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await dismissFirstVisitWelcomeIfShown(tester);
  }

  testWidgets('stg unverified member sees the soft banner and can resend', (tester) async {
    final auth = _RecordingAuthRepository(initialSession: unverified());
    await pumpGate(tester, auth);

    expect(find.byKey(const Key('auth_gate_verify_email_wall')), findsNothing);
    expect(find.byKey(const Key('home_verify_email_banner')), findsOneWidget);
    expect(find.textContaining('member@belongonthespectrum.com'), findsWidgets);
    expect(find.text(VerifyEmailCopy.softBannerSent), findsOneWidget);
    expect(auth.sends, greaterThan(0));

    await tester.tap(find.byKey(const Key('home_resend_verification')));
    await tester.pumpAndSettle();

    expect(find.text(VerifyEmailCopy.softBannerResent), findsOneWidget);
  });

  testWidgets('a failed resend stays on Home with a calm status', (tester) async {
    final auth = _RecordingAuthRepository(initialSession: unverified());
    await pumpGate(tester, auth);
    auth.failSend = true;

    expect(find.byKey(const Key('home_verify_email_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_resend_verification')));
    await tester.pumpAndSettle();
    expect(find.text('The network paused.'), findsOneWidget);
    expect(find.byKey(const Key('belong_profile_avatar_button')), findsOneWidget);
  });

  test('friendlyVerifyEmailError keeps mapped auth copy and a generic fallback', () {
    expect(
      friendlyVerifyEmailError(
        const AuthException(code: 'no-current-user', message: 'Sign in first.'),
      ),
      'Sign in first.',
    );
    expect(friendlyVerifyEmailError(StateError('boom')), VerifyEmailCopy.couldNotSend);
  });
}
