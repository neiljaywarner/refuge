import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_access_policy.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';

void main() {
  group('mustVerifyEmail', () {
    test('is true only for prod', () {
      expect(mustVerifyEmail(AppFlavor.prod), isTrue);
      expect(mustVerifyEmail(AppFlavor.dev), isFalse);
      expect(mustVerifyEmail(AppFlavor.stg), isFalse);
      expect(mustVerifyEmail(AppFlavor.qa), isFalse);
    });
  });

  group('showDevExampleAccounts', () {
    test('dev android and dev web', () {
      expect(
        showDevExampleAccounts(
          flavor: AppFlavor.dev,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        showDevExampleAccounts(
          flavor: AppFlavor.dev,
          isWeb: true,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
    });

    test('hidden on dev iOS, dev desktop, and prod', () {
      expect(
        showDevExampleAccounts(flavor: AppFlavor.dev, isWeb: false, platform: TargetPlatform.iOS),
        isFalse,
      );
      expect(
        showDevExampleAccounts(flavor: AppFlavor.dev, isWeb: false, platform: TargetPlatform.macOS),
        isFalse,
      );
      expect(
        showDevExampleAccounts(
          flavor: AppFlavor.prod,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(
        showDevExampleAccounts(
          flavor: AppFlavor.prod,
          isWeb: true,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
    });
  });

  group('sessionMayEnterCommunity', () {
    AuthSession signedIn({String userId = 'uid-1', String authMethod = 'firebase_password'}) {
      return AuthSession(
        userId: userId,
        displayName: 'David M.',
        email: 'member@belongonthespectrum.com',
        bio: 'bio',
        comfortBadges: const ['Literal communication appreciated'],
        isSignedIn: true,
        authMethod: authMethod,
      );
    }

    test('true for a real password session', () {
      expect(sessionMayEnterCommunity(signedIn()), isTrue);
    });

    test('false for guest, anonymous, and guest-shaped ids', () {
      expect(sessionMayEnterCommunity(const AuthSession.guest()), isFalse);
      expect(sessionMayEnterCommunity(signedIn(authMethod: 'anonymous')), isFalse);
      expect(sessionMayEnterCommunity(signedIn(authMethod: 'firebase_anonymous')), isFalse);
      expect(sessionMayEnterCommunity(signedIn(userId: 'guest')), isFalse);
      expect(sessionMayEnterCommunity(signedIn(userId: '')), isFalse);
    });
  });
}
