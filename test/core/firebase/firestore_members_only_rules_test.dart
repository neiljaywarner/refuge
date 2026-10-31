import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String firestoreRules;
  late String storageRules;
  late String firebaseConfig;

  setUpAll(() {
    firestoreRules = File('firestore.rules').readAsStringSync();
    storageRules = File('storage.rules').readAsStringSync();
    firebaseConfig = File('firebase.json').readAsStringSync();
  });

  group('firestore.rules members-only & guest audit (#601, #620)', () {
    test('defines isSignedInMember and rejects anonymous', () {
      expect(firestoreRules, contains('function isSignedInMember()'));
      expect(
        firestoreRules,
        contains("request.auth.token.firebase.sign_in_provider != 'anonymous'"),
      );
    });

    test('does not allow unauthenticated reads or pre-alpha public writes', () {
      expect(firestoreRules, isNot(contains('allow read: if true')));
      expect(firestoreRules, isNot(contains('allow create: if true')));
      expect(firestoreRules, isNot(contains('allow create, update: if true')));
      expect(firestoreRules, isNot(contains('|| true')));
    });

    test('community collections require isSignedInMember and exist in schema', () {
      const collections = [
        'feature_votes',
        'member_feedback',
        'posts',
        'users',
        'comments',
        'soft_deleted_users',
        'reflections',
        'reflections_dev',
        'direct_messages',
        'directory_members',
        'member_notifications',
        'self_deleted_accounts',
      ];
      for (final name in collections) {
        expect(firestoreRules, contains('match /$name/{'), reason: name);
      }
    });

    test('feature vote updates require voterIds membership (#733)', () {
      expect(firestoreRules, contains('function featureVoteVoterIds'));
      expect(firestoreRules, contains('function featureVoteUpvote()'));
      expect(firestoreRules, contains('function featureVoteUnvote()'));
    });

    test('feedback submissions are immutable to prevent tampering', () {
      expect(firestoreRules, contains('match /member_feedback/{feedbackId}'));
      expect(firestoreRules, contains('allow update, delete: if false;'));
    });

    test('comment update and delete require author check', () {
      expect(firestoreRules, contains('match /comments/{commentId}'));
      expect(firestoreRules, contains('isAuthorOf(resource.data)'));
    });

    test('post and reflection mirrors guard update and delete by authorId', () {
      expect(firestoreRules, contains('match /posts/{postId}'));
      expect(firestoreRules, contains('match /reflections/{postId}'));
      expect(firestoreRules, contains('match /reflections_dev/{postId}'));
      expect(firestoreRules, contains("request.auth.uid == resource.data.get('authorId', null)"));
    });
  });

  group('storage.rules members-only & guest audit (#620)', () {
    test('defines isSignedInMember and rejects anonymous sessions in storage', () {
      expect(storageRules, contains('function isSignedInMember()'));
      expect(storageRules, contains("request.auth.token.firebase.sign_in_provider != 'anonymous'"));
    });

    test('enforces strict path separation, size limits, and image types', () {
      expect(storageRules, contains('match /avatars/{userId}/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 5 * 1024 * 1024'));
      expect(storageRules, contains("request.resource.contentType.matches('image/.*')"));

      expect(storageRules, contains('match /posts/{spaceSlug}/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 10 * 1024 * 1024'));

      expect(storageRules, contains('match /feedback/{allPaths=**}'));
      expect(storageRules, contains('allow read: if false;'));

      expect(storageRules, contains('match /diagnostics/{allPaths=**}'));
      expect(storageRules, contains('request.resource.size < 2 * 1024 * 1024'));

      // Default deny
      expect(storageRules, contains('match /{allPaths=**}'));
      expect(storageRules, contains('allow read, write: if false;'));
    });
  });

  group('firebase.json multi-service configuration (#620)', () {
    test('links both firestore and storage security rules', () {
      final config = jsonDecode(firebaseConfig) as Map<String, dynamic>;
      expect(config['firestore'], isNotNull);
      expect(config['firestore']['rules'], equals('firestore.rules'));
      expect(config['storage'], isNotNull);
      expect(config['storage']['rules'], equals('storage.rules'));
    });
  });
}
