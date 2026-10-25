import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_exception.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('Firebase Auth Repository & Adapter Tests (#119)', () {
    late InMemoryAuthRepository authRepo;

    setUp(() {
      authRepo = InMemoryAuthRepository();
    });

    test('initial state is unauthenticated session', () {
      final session = authRepo.currentSession();
      expect(session.isSignedIn, isFalse);
      expect(session.isGuest, isTrue);
    });

    test('registerWithPassword creates an account and returns active session', () async {
      final session = await authRepo.registerWithPassword(
        email: 'member@belong.org',
        password: 'securePassword123',
        displayName: 'Neurodivergent Disciple',
        bio: 'Learning to unmask in fellowship',
        icocChurchAffiliation: 'Austin Christian Church',
      );

      expect(session.isSignedIn, isTrue);
      expect(session.email, 'member@belong.org');
      expect(session.displayName, 'Neurodivergent Disciple');
      expect(session.icocChurchAffiliation, 'Austin Christian Church');
      expect(session.isIcocMember, isTrue);
      expect(authRepo.currentSession().isSignedIn, isTrue);
    });

    test('registerWithPassword rejects weak passwords (< 6 chars)', () async {
      expect(
        () => authRepo.registerWithPassword(
          email: 'member@belong.org',
          password: '123',
          displayName: 'Short Pass',
          icocChurchAffiliation: 'I am not a member of an ICOC church',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'weak-password')),
      );
    });

    test('registerWithPassword rejects duplicate email', () async {
      await authRepo.registerWithPassword(
        email: 'duplicate@belong.org',
        password: 'password123',
        displayName: 'First',
        icocChurchAffiliation: 'Chicago Church of Christ',
      );

      expect(
        () => authRepo.registerWithPassword(
          email: 'duplicate@belong.org',
          password: 'password456',
          displayName: 'Second',
          icocChurchAffiliation: 'Chicago Church of Christ',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'email-already-in-use')),
      );
    });

    test('signInWithPassword succeeds with matching credentials', () async {
      await authRepo.registerWithPassword(
        email: 'registered@belong.org',
        password: 'correctPassword',
        displayName: 'Registered User',
        icocChurchAffiliation: 'Boston Church of Christ',
      );
      authRepo.signOut();
      expect(authRepo.currentSession().isSignedIn, isFalse);

      final session = await authRepo.signInWithPassword(
        email: 'registered@belong.org',
        password: 'correctPassword',
      );
      expect(session.isSignedIn, isTrue);
      expect(session.displayName, 'Registered User');
    });

    test('signInWithPassword rejects non-existent user with user-not-found', () async {
      expect(
        () => authRepo.signInWithPassword(email: 'ghost@belong.org', password: 'anyPassword'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'user-not-found')),
      );
    });

    test('signInWithPassword rejects wrong password with wrong-password', () async {
      await authRepo.registerWithPassword(
        email: 'user@belong.org',
        password: 'realPassword',
        displayName: 'Real User',
        icocChurchAffiliation: 'I am not a member of an ICOC church',
      );
      authRepo.signOut();

      expect(
        () => authRepo.signInWithPassword(email: 'user@belong.org', password: 'wrongPassword'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'wrong-password')),
      );
    });

    test('sendMagicLink and signInWithMagicLink flow', () async {
      await authRepo.sendMagicLink(email: 'magic@belong.org');
      final link = authRepo.lastGeneratedMagicLink;
      expect(link, isNotNull);

      // Consuming wrong link fails
      expect(
        () => authRepo.signInWithMagicLink(
          email: 'magic@belong.org',
          emailLink: 'https://belong.org/auth?bad_token=xyz',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-action-code')),
      );

      // Consuming valid link succeeds
      final session = await authRepo.signInWithMagicLink(
        email: 'magic@belong.org',
        emailLink: link!,
      );
      expect(session.isSignedIn, isTrue);
      expect(session.email, 'magic@belong.org');
      expect(session.authMethod, 'in_memory_magic_link');
    });

    test('AuthException.fromFirebase translates codes into calm messages', () {
      final invalidEmail = AuthException.fromFirebase(
        fb_auth.FirebaseAuthException(code: 'invalid-email'),
      );
      expect(invalidEmail.code, 'invalid-email');
      expect(invalidEmail.message, contains('Please enter a valid email address'));

      final expiredCode = AuthException.fromFirebase(
        fb_auth.FirebaseAuthException(code: 'expired-action-code'),
      );
      expect(expiredCode.code, 'expired-action-code');
      expect(expiredCode.message, contains('expired'));

      final unknown = AuthException.fromFirebase(
        fb_auth.FirebaseAuthException(code: 'custom-error', message: 'Custom issue occurred'),
      );
      expect(unknown.code, 'custom-error');
      expect(unknown.message, 'Custom issue occurred');
    });

    test(
      'FirebaseAuthRepository resiliently creates user and signs in with Neil test email (#199)',
      () async {
        final repo = FirebaseAuthRepository();

        final session = await repo.registerWithPassword(
          email: 'neilwarner+2026Oct20+954pm@gmail.com',
          password: 'BelongPassword2026!',
          displayName: 'Neil Warner',
          icocChurchAffiliation: 'DFW Church',
          bio: 'Belong Organizer & Disciple',
        );

        expect(session.isSignedIn, isTrue);
        expect(session.email, 'neilwarner+2026oct20+954pm@gmail.com');
        expect(session.displayName, 'Neil Warner');
        expect(session.icocChurchAffiliation, 'DFW Church');

        await repo.signOut();
        expect(repo.currentSession().isSignedIn, isFalse);

        final signedIn = await repo.signInWithPassword(
          email: 'neilwarner+2026Oct20+954pm@gmail.com',
          password: 'BelongPassword2026!',
        );

        expect(signedIn.isSignedIn, isTrue);
        expect(signedIn.displayName, 'Neil Warner');
        expect(signedIn.email, 'neilwarner+2026oct20+954pm@gmail.com');
      },
    );
  });

  group('Storage Repository Seam Tests (#119)', () {
    late InMemoryStorageRepository storage;

    setUp(() {
      storage = InMemoryStorageRepository();
    });

    test('upload avatar, upload post media, and delete media', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final avatarUrl = await storage.uploadAvatar(
        userId: 'user_123',
        bytes: testData,
        filename: 'avatar.png',
      );

      expect(avatarUrl, contains('avatars/user_123/avatar.png'));

      final mediaUrl = await storage.uploadPostMedia(
        spaceSlug: 'autistic-memes',
        bytes: testData,
        filename: 'meme_42.png',
      );

      expect(mediaUrl, contains('spaces/autistic-memes/meme_42.png'));

      await storage.deleteMedia(avatarUrl);
    });
  });
}
